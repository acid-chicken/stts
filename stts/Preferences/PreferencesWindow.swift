//
//  PreferencesWindow.swift
//  stts
//

import Cocoa
import PreferencesWindow
import SFSafeSymbols

final class PreferencesWindow {
    let controller: PreferencesWindowController
    private let servicesView: PreferencesServicesView

    var saveCallback: (() -> Void)? {
        get { servicesView.saveCallback }
        set { servicesView.saveCallback = newValue }
    }

    init(serviceLoader: ServiceLoader, preferences: Preferences) {
        servicesView = PreferencesServicesView(serviceLoader: serviceLoader, preferences: preferences)
        controller = PreferencesWindowController(menuItems: [
            Self.generalMenuItem(preferences: preferences),
            PreferencesWindow.servicesMenuItem(servicesView: servicesView),
            Self.aboutMenuItem()
        ])
    }

    func show() {
        controller.show()
    }

    private static func generalMenuItem(preferences: Preferences) -> PreferencesSidebarMenuItem {
        PreferencesSidebarMenuItem(
            title: "General",
            symbol: .gearshapeFill,
            view: PreferencesGeneralView(preferences: preferences)
        )
    }

    private static func servicesMenuItem(servicesView: PreferencesServicesView) -> PreferencesSidebarMenuItem {
        PreferencesSidebarMenuItem(
            title: "Services",
            symbol: .boltCircleFill,
            view: servicesView
        )
    }

    private static func aboutMenuItem() -> PreferencesSidebarMenuItem {
        let content = AboutContent(
            links: [
                AboutContent.Link(
                    title: "GitHub",
                    url: URL(string: "https://github.com/inket/stts")!
                ),
                AboutContent.Link(
                    title: "Contributors",
                    url: URL(string: "https://github.com/inket/stts/graphs/contributors")!
                )
            ],
            credit: "Activity glyph (app icon) by Gregor Črešnar from the Noun Project"
        )
        return PreferencesSidebarMenuItem(
            title: "About",
            symbol: .infoCircleFill,
            view: PreferencesAboutView(content: content)
        )
    }
}
