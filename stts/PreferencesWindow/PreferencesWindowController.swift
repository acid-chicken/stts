//
//  PreferencesWindowController.swift
//  PreferencesWindow
//

import Cocoa
import SFSafeSymbols

public class PreferencesWindowController: NSWindowController {
    public let menuItems: [PreferencesSidebarMenuItem]

    private let sidebarTableView = NSTableView()
    private let contentContainer = NSView()
    private var currentView: (any PreferencesView)?

    private var backHistory: [Int] = []
    private var forwardHistory: [Int] = []
    private var selectedIndex: Int = 0
    private var isNavigating = false

    private lazy var backButton: NSButton = {
        NSButton(image: NSImage(systemSymbol: .chevronLeft), target: self, action: #selector(navigateBack))
    }()

    private lazy var forwardButton: NSButton = {
        NSButton(image: NSImage(systemSymbol: .chevronRight), target: self, action: #selector(navigateForward))
    }()

    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.alignment = .natural
        return label
    }()

    public init(menuItems: [PreferencesSidebarMenuItem]) {
        self.menuItems = menuItems

        let window = NSWindow()
        window.styleMask = [.titled, .fullSizeContentView, .closable, .miniaturizable, .resizable]
        window.titleVisibility = .hidden
        window.titlebarSeparatorStyle = .automatic

        super.init(window: window)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        let toolbar = NSToolbar(identifier: "PreferencesToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        window?.toolbar = toolbar
        window?.toolbarStyle = .unified

        let sidebarVC = NSViewController()
        sidebarVC.view = makeSidebarScrollView()
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarVC)
        sidebarItem.canCollapse = false
        sidebarItem.minimumThickness = 160
        sidebarItem.maximumThickness = 200

        let contentVC = NSViewController()
        contentVC.view = contentContainer
        let contentItem = NSSplitViewItem(viewController: contentVC)
        contentItem.canCollapse = false

        let splitVC = NSSplitViewController()
        splitVC.splitViewItems = [sidebarItem, contentItem]
        contentViewController = splitVC

        if !menuItems.isEmpty {
            sidebarTableView.selectRowIndexes(.init(integer: 0), byExtendingSelection: false)
            selectItem(at: 0, addingToHistory: false)
        }
    }

    private func makeSidebarScrollView() -> NSView {
        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false

        let column = NSTableColumn(identifier: .init("item"))
        column.resizingMask = .autoresizingMask
        sidebarTableView.addTableColumn(column)
        sidebarTableView.headerView = nil
        sidebarTableView.style = .sourceList
        sidebarTableView.backgroundColor = .clear
        sidebarTableView.focusRingType = .none
        sidebarTableView.rowHeight = 32
        sidebarTableView.dataSource = self
        sidebarTableView.delegate = self

        scrollView.documentView = sidebarTableView
        return scrollView
    }

    private func selectItem(at index: Int, addingToHistory: Bool) {
        if addingToHistory, index != selectedIndex {
            backHistory.append(selectedIndex)
            forwardHistory.removeAll()
        }

        selectedIndex = index
        showView(menuItems[index].view)
        updateNavigationState()
    }

    private func showView(_ view: any PreferencesView) {
        currentView?.removeFromSuperview()
        currentView = view

        view.willShow()
        view.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(view)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])
    }

    private func updateNavigationState() {
        backButton.isEnabled = !backHistory.isEmpty
        forwardButton.isEnabled = !forwardHistory.isEmpty
        titleLabel.stringValue = menuItems[selectedIndex].title
    }

    @objc private func navigateBack() {
        guard let previous = backHistory.popLast() else { return }
        forwardHistory.append(selectedIndex)
        selectedIndex = previous
        syncSidebarSelection(to: previous)
        showView(menuItems[previous].view)
        updateNavigationState()
    }

    @objc private func navigateForward() {
        guard let next = forwardHistory.popLast() else { return }
        backHistory.append(selectedIndex)
        selectedIndex = next
        syncSidebarSelection(to: next)
        showView(menuItems[next].view)
        updateNavigationState()
    }

    private func syncSidebarSelection(to index: Int) {
        isNavigating = true
        sidebarTableView.selectRowIndexes(.init(integer: index), byExtendingSelection: false)
        isNavigating = false
    }

    public func show() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        let alreadyVisible = window?.isVisible == true
        showWindow(nil)
        if !alreadyVisible {
            window?.center()
        }

        // Deferred to the next run loop turn: ordering the window front in the same turn as activate()
        // can resolve before activation actually completes, leaving the window behind other apps.
        DispatchQueue.main.async { [weak self] in
            self?.window?.makeKeyAndOrderFront(nil)
            self?.window?.orderFrontRegardless()
        }
    }
}

// MARK: - NSToolbarDelegate

extension PreferencesWindowController: NSToolbarDelegate {
    public func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        switch itemIdentifier.rawValue {
        case "PreferencesNavigate":
            for button in [backButton, forwardButton] {
                button.isBordered = true
                button.bezelStyle = .texturedRounded
                button.isEnabled = false
                button.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    button.widthAnchor.constraint(equalToConstant: 32),
                    button.heightAnchor.constraint(equalToConstant: 32)
                ])
            }

            let separator = NSBox()
            separator.boxType = .separator
            separator.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                separator.widthAnchor.constraint(equalToConstant: 1),
                separator.heightAnchor.constraint(equalToConstant: 18)
            ])

            let navView = NSStackView(views: [backButton, separator, forwardButton])
            navView.spacing = -1
            navView.orientation = .horizontal

            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.view = navView
            item.label = "Navigate"
            return item

        case "PreferencesTitle":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.view = titleLabel
            return item

        default:
            return nil
        }
    }

    public func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.init("PreferencesNavigate"), .init("PreferencesTitle"), .flexibleSpace]
    }

    public func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            .init("PreferencesNavigate"),
            .init("PreferencesTitle"),
            .flexibleSpace,
            .space
        ]
    }
}

// MARK: - NSTableViewDataSource

extension PreferencesWindowController: NSTableViewDataSource {
    public func numberOfRows(in tableView: NSTableView) -> Int {
        menuItems.count
    }
}

// MARK: - NSTableViewDelegate

extension PreferencesWindowController: NSTableViewDelegate {
    public func tableView(
        _ tableView: NSTableView,
        viewFor tableColumn: NSTableColumn?,
        row: Int
    ) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("PreferencesSidebarCell")
        let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView ?? {
            let cell = NSTableCellView()
            cell.identifier = identifier

            let imageView = NSImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.symbolConfiguration = .init(pointSize: 14, weight: .medium)
            cell.imageView = imageView
            cell.addSubview(imageView)

            let textField = NSTextField(labelWithString: "")
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.font = .preferredFont(forTextStyle: .body)
            textField.lineBreakMode = .byTruncatingTail
            cell.textField = textField
            cell.addSubview(textField)

            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
                imageView.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 20),
                imageView.heightAnchor.constraint(equalToConstant: 20),

                textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 6),
                textField.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4)
            ])

            return cell
        }()

        let item = menuItems[row]
        cell.imageView?.image = NSImage(systemSymbol: item.symbol)
        cell.textField?.stringValue = item.title
        return cell
    }

    public func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat { 32 }

    public func tableViewSelectionDidChange(_ notification: Notification) {
        guard !isNavigating, sidebarTableView.selectedRow >= 0 else { return }
        selectItem(at: sidebarTableView.selectedRow, addingToHistory: true)
    }
}
