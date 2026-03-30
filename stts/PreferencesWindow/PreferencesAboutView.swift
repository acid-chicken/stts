//
//  PreferencesAboutView.swift
//  PreferencesWindow
//

import Cocoa

public struct AboutContent {
    public struct Link {
        public let title: String
        public let url: URL

        public init(title: String, url: URL) {
            self.title = title
            self.url = url
        }
    }

    public let links: [Link]
    public let credit: String?

    public init(links: [Link], credit: String? = nil) {
        self.links = links
        self.credit = credit
    }
}

public class PreferencesAboutView: NSView, PreferencesView {
    private let content: AboutContent

    private let appIconView = NSImageView()
    private let appNameLabel = NSTextField(labelWithString: "")
    private let versionLabel = NSTextField(labelWithString: "")
    private var linkButtons: [NSButton] = []
    private let creditLabel = NSTextField(wrappingLabelWithString: "")

    public init(content: AboutContent) {
        self.content = content
        super.init(frame: .zero)
        commonInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {
        appIconView.image = NSApp.applicationIconImage
        appIconView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        appIconView.heightAnchor.constraint(equalToConstant: 80).isActive = true

        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
        appNameLabel.stringValue = appName
        appNameLabel.font = .systemFont(ofSize: 20, weight: .semibold)

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        versionLabel.stringValue = "Version \(version) (\(build))"
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.font = .systemFont(ofSize: 12)

        let divider = NSBox()
        divider.boxType = .separator

        linkButtons = content.links.map { link in
            let button = NSButton(title: link.title, target: self, action: #selector(openLink(_:)))
            button.bezelStyle = .rounded
            button.font = .systemFont(ofSize: 13)
            return button
        }

        let buttonRow = NSStackView(views: linkButtons)
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 12

        creditLabel.stringValue = content.credit ?? ""
        creditLabel.isHidden = content.credit == nil
        creditLabel.textColor = .tertiaryLabelColor
        creditLabel.font = .systemFont(ofSize: 11)
        creditLabel.alignment = .center

        let contentStack = NSStackView(
            views: [appIconView, appNameLabel, versionLabel, divider, buttonRow]
        )
        contentStack.orientation = .vertical
        contentStack.alignment = .centerX
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.setCustomSpacing(12, after: appIconView)
        contentStack.setCustomSpacing(4, after: appNameLabel)
        contentStack.setCustomSpacing(24, after: versionLabel)
        contentStack.setCustomSpacing(20, after: divider)

        creditLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)
        addSubview(creditLabel)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 400),
            heightAnchor.constraint(equalToConstant: 400),

            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),

            divider.widthAnchor.constraint(equalTo: contentStack.widthAnchor, constant: -80),

            creditLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            creditLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            creditLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24)
        ])
    }

    @objc private func openLink(_ sender: NSButton) {
        guard let index = linkButtons.firstIndex(of: sender) else { return }
        NSWorkspace.shared.open(content.links[index].url)
    }

    public func willShow() {}
}
