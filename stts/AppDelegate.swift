//
//  AppDelegate.swift
//  stts
//

import Cocoa
import MBPopup
import PreferencesWindow
import Reachability
import UserNotifications

@NSApplicationMain
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var shouldAutomaticallyCheckServices: Bool {
        // We don't want to start the updating timer when unit testing because:
        // 1. It will be checking services unnecessarily
        // 2. It will check services that have a Store (like Adobe) before our tests and cache statuses
        return ProcessInfo.processInfo.environment["UNIT_TESTING"] == nil
    }

    private var timer: Timer?
    private var remoteServicesTimer: Timer?
    private let remoteServicesUpdater: RemoteServicesUpdater?

    private let reachability = try! Reachability() // swiftlint:disable:this force_try
    private var initialReachabilityChange: Bool = true

    let popupController: MBPopupController
    private let serviceTableViewController: ServiceTableViewController

    private let serviceLoader: ServiceLoader
    private let preferences: Preferences
    private let preferencesWindow: PreferencesWindow

    override init() {
        var serviceDefinitionProviders: [ServiceDefinitionProvider] = []

        // swiftlint:disable:next force_try
        let appDefinedProvider = try! AppDefinedServiceDefinitionProvider()
        if let remoteProvider = try? RemoteServiceDefinitionProvider() {
            // Wholesale swap, not a per-identifier merge: once the remote copy has any data, it
            // fully replaces the bundled one rather than being unioned with it, so a service the
            // remote copy drops doesn't linger just because the (older) bundled copy still has it.
            // Falls back to the bundled copy entirely when remote hasn't fetched anything successfully
            // yet.
            serviceDefinitionProviders.append(
                FallbackServiceDefinitionProvider(primary: remoteProvider, fallback: appDefinedProvider)
            )
        } else {
            serviceDefinitionProviders.append(appDefinedProvider)
        }
        // swiftlint:disable:next force_try
        serviceDefinitionProviders.append(try! BundleServiceDefinitionProvider())
        if let userDefinedProvider = try? UserDefinedServiceDefinitionProvider() {
            serviceDefinitionProviders.append(userDefinedProvider)
        }
        serviceLoader = ServiceLoader(providers: serviceDefinitionProviders)
        SendbirdAll.sendbirdServices = serviceLoader.allServices
            .compactMap { $0 as? SendbirdServiceDefinition }
            .compactMap { $0.build() as? SendbirdService }

        remoteServicesUpdater = (try? RemoteServiceDefinitionProvider.cachedServicesJSONURL())
            .map { RemoteServicesUpdater(destinationURL: $0) }

        preferences = Preferences(serviceLoader: serviceLoader)
        preferencesWindow = PreferencesWindow(serviceLoader: serviceLoader, preferences: preferences)

        serviceTableViewController = ServiceTableViewController(
            serviceLoader: serviceLoader,
            preferences: preferences,
            preferencesWindow: preferencesWindow
        )

        popupController = MBPopupController(contentView: serviceTableViewController.contentView)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(AppDelegate.restartTimer),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        if shouldAutomaticallyCheckServices {
            reachability.whenReachable = { [weak self] _ in self?.reachabilityChanged() }
            reachability.whenUnreachable = { [weak self] _ in self?.reachabilityChanged() }
        }

        try? reachability.startNotifier()

        Appearance.addObserver(self)

        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

        popupController.statusItem.button?.title = "stts"
        popupController.statusItem.button?.font =
            NSFont(name: "SF Mono Regular", size: 10) ?? NSFont.systemFont(ofSize: 12)
        popupController.statusItem.length = 30

        popupController.contentView.wantsLayer = true
        popupController.contentView.layer?.masksToBounds = true

        serviceTableViewController.setup()

        preferencesWindow.saveCallback = { [weak self] in
            self?.serviceTableViewController.reloadServicesList()
            self?.updateServices()
        }

        popupController.willOpenPopup = { [weak self] _ in
            self?.serviceTableViewController.willOpenPopup()
        }

        if shouldAutomaticallyCheckServices {
            restartTimer()
            restartRemoteServicesTimer()
        }
    }

    private static let remoteServicesRefreshInterval: TimeInterval = 3 * 60 * 60

    private func restartRemoteServicesTimer() {
        remoteServicesTimer?.invalidate()
        remoteServicesTimer = Timer.scheduledTimer(
            withTimeInterval: Self.remoteServicesRefreshInterval,
            repeats: true
        ) { [weak self] _ in
            Task { await self?.refreshRemoteServices() }
        }
        remoteServicesTimer?.fire()
    }

    private func refreshRemoteServices() async {
        guard let remoteServicesUpdater, await remoteServicesUpdater.update() else { return }

        serviceLoader.reload()
        SendbirdAll.sendbirdServices = serviceLoader.allServices
            .compactMap { $0 as? SendbirdServiceDefinition }
            .compactMap { $0.build() as? SendbirdService }

        // reloadServicesList() rebuilds `services` with fresh BaseService instances (always starting
        // at .undetermined/"Loading"), which orphans whatever the in-flight updateServices() fetch
        // (e.g. from app launch) was updating and leaves the new instances stuck showing "Loading"
        // until the next scheduled update. Re-running updateServices() here fetches them right away.
        serviceTableViewController.reloadServicesList()
        updateServices()
    }

    @objc
    private func restartTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            timeInterval: 300,
            target: self,
            selector: #selector(AppDelegate.updateServices),
            userInfo: nil,
            repeats: true
        )
        timer?.fire()
    }

    @objc func updateServices() {
        serviceTableViewController.updateServices { [weak self] in
            guard let self else { return }
            let title = serviceTableViewController.generalStatus == .major ? "s__s" : "stts"
            popupController.statusItem.button?.title = title

            if preferences.notifyOnStatusChange {
                serviceTableViewController.services.forEach { $0.notifyIfStatusChanged() }
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        popupController.openPopup()
        return true
    }

    private func reachabilityChanged() {
        if initialReachabilityChange {
            // Reachability notifies us of a change on app launch (after calling startNotifier()),
            // we don't need it because it causes duplicate updateServices()
            initialReachabilityChange = false
        } else {
            updateServices()
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        popupController.openPopup()
        completionHandler()
    }
}

extension AppDelegate: AppearanceObserver {
    func changeAppearance(to newAppearance: NSAppearance) {
        popupController.backgroundView.backgroundColor = newAppearance.isDarkMode ? .windowBackgroundColor : .white
    }
}
