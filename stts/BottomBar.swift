//
//  BottomBar.swift
//  stts
//

import Cocoa

enum BottomBarStatus {
    case undetermined
    case updating
    case updated(Date)
}

class BottomBar: NSView {
    let settingsButton = NSButton()
    let reloadButton = NSButton()
    let statusField = NSTextField()
    let separator = ServiceTableRowView()

    var status: BottomBarStatus = .undetermined {
        didSet {
            updateStatusText()
        }
    }

    var reloadServicesCallback: () -> Void = {}
    var openSettingsCallback: () -> Void = {}

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        [separator, settingsButton, reloadButton, statusField].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        let gearIcon = GearIcon()
        gearIcon.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.addSubview(gearIcon)

        let refreshIcon = RefreshIcon()
        refreshIcon.translatesAutoresizingMaskIntoConstraints = false
        reloadButton.addSubview(refreshIcon)

        NSLayoutConstraint.activate([
            separator.heightAnchor.constraint(equalToConstant: 1),
            separator.topAnchor.constraint(equalTo: topAnchor),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),

            settingsButton.heightAnchor.constraint(equalToConstant: 30),
            settingsButton.widthAnchor.constraint(equalToConstant: 30),
            settingsButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            settingsButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            gearIcon.centerYAnchor.constraint(equalTo: settingsButton.centerYAnchor),
            gearIcon.centerXAnchor.constraint(equalTo: settingsButton.centerXAnchor),
            gearIcon.heightAnchor.constraint(equalToConstant: 22),
            gearIcon.widthAnchor.constraint(equalToConstant: 22),

            reloadButton.heightAnchor.constraint(equalToConstant: 30),
            reloadButton.widthAnchor.constraint(equalToConstant: 30),
            reloadButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            reloadButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            refreshIcon.centerYAnchor.constraint(equalTo: reloadButton.centerYAnchor),
            refreshIcon.centerXAnchor.constraint(equalTo: reloadButton.centerXAnchor),
            refreshIcon.heightAnchor.constraint(equalToConstant: 18),
            refreshIcon.widthAnchor.constraint(equalToConstant: 18),

            statusField.leadingAnchor.constraint(equalTo: settingsButton.trailingAnchor),
            statusField.trailingAnchor.constraint(equalTo: reloadButton.leadingAnchor),
            statusField.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        settingsButton.isBordered = false
        settingsButton.bezelStyle = .regularSquare
        settingsButton.title = ""
        settingsButton.target = self
        settingsButton.action = #selector(openSettings)
        gearIcon.scaleUnitSquare(to: NSSize(width: 0.46, height: 0.46))

        reloadButton.isBordered = false
        reloadButton.bezelStyle = .regularSquare
        reloadButton.title = ""
        reloadButton.target = self
        reloadButton.action = #selector(reloadServices)
        refreshIcon.scaleUnitSquare(to: NSSize(width: 0.38, height: 0.38))

        statusField.isEditable = false
        statusField.isBordered = false
        statusField.isSelectable = false

        let fontSize = NSFont.systemFontSize(for: .small)
        let font = NSFont.systemFont(ofSize: fontSize)
        let italicFont = NSFontManager.shared.font(
            withFamily: font.fontName,
            traits: NSFontTraitMask.italicFontMask,
            weight: 5,
            size: fontSize
        )
        statusField.font = italicFont

        statusField.textColor = NSColor.secondaryLabelColor
        statusField.maximumNumberOfLines = 1
        statusField.backgroundColor = NSColor.clear
        statusField.alignment = .center
        statusField.cell?.truncatesLastVisibleLine = true
    }

    func updateStatusText() {
        switch status {
        case .undetermined: statusField.stringValue = ""
        case .updating: statusField.stringValue = "Updating…"
        case .updated(let date):
            var relativeDate = date
            if Int(relativeDate.timeIntervalSince1970) == Int(Date().timeIntervalSince1970) {
                // Avoid issues with relative time marking it as "in 0 sec."
                relativeDate = Date(timeIntervalSinceNow: -1)
            }

            let dateTimeFormatter = RelativeDateTimeFormatter()
            dateTimeFormatter.dateTimeStyle = .numeric
            dateTimeFormatter.unitsStyle = .short
            let dateString = dateTimeFormatter.string(for: relativeDate)! // Cannot be nil when date is Date
            statusField.stringValue = "Updated \(dateString)"
        }
    }

    @objc private func reloadServices() {
        reloadServicesCallback()
    }

    @objc private func openSettings() {
        openSettingsCallback()
    }
}
