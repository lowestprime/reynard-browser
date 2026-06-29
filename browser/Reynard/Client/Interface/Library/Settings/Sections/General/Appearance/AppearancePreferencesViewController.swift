//
//  AppearancePreferencesViewController.swift
//  Reynard
//
//  Created by Minh Ton on 18/6/26.
//

import UIKit

final class AppearancePreferencesViewController: SettingsTableViewController {
    private enum UX {
        static let swatchSize = CGSize(width: 22, height: 22)
        static let swatchInset: CGFloat = 2
        static let swatchCornerRadius: CGFloat = 4
        static let swatchStrokeWidth: CGFloat = 1
    }

    private enum Section: CaseIterable {
        case appAppearance
        case accent
        case addressBar
        case tabs
        case pageZoom
        
        var text: SettingsSectionText {
            switch self {
            case .appAppearance:
                return SettingsSectionText()
            case .accent:
                return SettingsSectionText(headerTitle: "Accent")
            case .addressBar:
                return SettingsSectionText(headerTitle: "Address Bar")
            case .tabs:
                return SettingsSectionText(headerTitle: "Tabs")
            case .pageZoom:
                return SettingsSectionText(headerTitle: "Page Zoom")
            }
        }
        
        var rows: [Row] {
            switch self {
            case .appAppearance:
                return [.appAppearance]
            case .accent:
                return BrowserAccentColor.presetCases.map(Row.accent) + [.customAccent]
            case .addressBar:
                if UIDevice.current.userInterfaceIdiom == .pad {
                    return [.showFullWebsiteAddress]
                }
                return [.BrowserChromePosition, .showFullWebsiteAddress]
            case .tabs:
                if UIDevice.current.userInterfaceIdiom == .pad {
                    return []
                }
                return [.landscapeTabBar]
            case .pageZoom:
                return [.pageZoom]
            }
        }
    }
    
    private enum Row {
        case appAppearance
        case accent(BrowserAccentColor)
        case customAccent
        case BrowserChromePosition
        case showFullWebsiteAddress
        case landscapeTabBar
        case pageZoom
    }
    
    private let showFullWebsiteAddressSwitch = UISwitch()
    private let landscapeTabBarSwitch = UISwitch()
    
    private var displayedSections: [Section] {
        return Section.allCases.filter { section in
            !section.rows.isEmpty
        }
    }
    
    init() {
        super.init(style: .insetGrouped)
        title = "Appearance"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSwitch()
        refreshDisplayedState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshDisplayedState()
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        displayedSections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard displayedSections.indices.contains(section) else {
            return 0
        }
        return displayedSections[section].rows.count
    }
    
    override func sectionText(for section: Int) -> SettingsSectionText {
        guard displayedSections.indices.contains(section) else {
            return SettingsSectionText()
        }
        return displayedSections[section].text
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard displayedSections.indices.contains(indexPath.section),
              displayedSections[indexPath.section].rows.indices.contains(indexPath.row) else {
            return UITableViewCell()
        }
        
        switch displayedSections[indexPath.section].rows[indexPath.row] {
        case .appAppearance:
            let cell = AppAppearancePickerCell(style: .default, reuseIdentifier: nil)
            cell.display(selectedAppearance: Prefs.AppearanceSettings.appAppearance)
            cell.onAppearanceChanged = { appearance in
                Prefs.AppearanceSettings.appAppearance = appearance
            }
            return cell
        case let .accent(accent):
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = accent.displayName
            cell.imageView?.image = swatchImage(color: accent.color, shape: .circle)
            cell.accessoryType = accent == Prefs.AppearanceSettings.accentColor ? .checkmark : .none
            return cell
        case .customAccent:
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            let hex = Prefs.AppearanceSettings.customAccentHex
            let isSelected = Prefs.AppearanceSettings.accentColor == .custom
            cell.textLabel?.text = "Custom"
            cell.detailTextLabel?.text = hex
            cell.imageView?.image = swatchImage(
                color: Prefs.AppearanceSettings.customAccentColor,
                shape: .square
            )
            cell.accessoryType = isSelected ? .checkmark : .none
            cell.accessibilityLabel = "Custom accent color"
            cell.accessibilityValue = "\(hex), \(isSelected ? "selected" : "not selected")"
            cell.accessibilityHint = "Opens custom accent color options."
            return cell
        case .BrowserChromePosition:
            let cell = AddressBarPositionPickerCell(style: .default, reuseIdentifier: nil)
            cell.display(selectedPosition: Prefs.AppearanceSettings.addressBarPosition)
            cell.onPositionChanged = { position in
                Prefs.AppearanceSettings.addressBarPosition = position
            }
            return cell
        case .showFullWebsiteAddress:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "Show Full Website Address"
            cell.selectionStyle = .none
            cell.accessoryView = showFullWebsiteAddressSwitch
            return cell
        case .landscapeTabBar:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "Landscape Tab Bar"
            cell.selectionStyle = .none
            cell.accessoryView = landscapeTabBarSwitch
            return cell
        case .pageZoom:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "Zoom Settings"
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        guard displayedSections.indices.contains(indexPath.section),
              displayedSections[indexPath.section].rows.indices.contains(indexPath.row) else {
            return
        }
        
        switch displayedSections[indexPath.section].rows[indexPath.row] {
        case let .accent(accent):
            Prefs.AppearanceSettings.accentColor = accent
            tableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
        case .customAccent:
            presentCustomAccentActions(from: tableView.cellForRow(at: indexPath))
        case .pageZoom:
            navigationController?.pushViewController(PageZoomPreferencesViewController(), animated: true)
        case .appAppearance, .BrowserChromePosition, .showFullWebsiteAddress, .landscapeTabBar:
            return
        }
    }
    
    private func configureSwitch() {
        showFullWebsiteAddressSwitch.addTarget(self, action: #selector(showFullWebsiteAddressSwitchDidChange), for: .valueChanged)
        landscapeTabBarSwitch.addTarget(self, action: #selector(landscapeTabBarSwitchDidChange), for: .valueChanged)
    }
    
    private func refreshDisplayedState() {
        showFullWebsiteAddressSwitch.isOn = Prefs.AppearanceSettings.showsFullWebsiteAddress
        landscapeTabBarSwitch.isOn = Prefs.AppearanceSettings.showsLandscapeTabBar
    }
    
    @objc private func showFullWebsiteAddressSwitchDidChange() {
        Prefs.AppearanceSettings.showsFullWebsiteAddress = showFullWebsiteAddressSwitch.isOn
    }
    
    @objc private func landscapeTabBarSwitchDidChange() {
        Prefs.AppearanceSettings.showsLandscapeTabBar = landscapeTabBarSwitch.isOn
    }

    private enum SwatchShape {
        case circle
        case square
    }

    private func swatchImage(color: UIColor, shape: SwatchShape) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: UX.swatchSize)
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: UX.swatchSize)
                .insetBy(dx: UX.swatchInset, dy: UX.swatchInset)
            let path: UIBezierPath
            switch shape {
            case .circle:
                path = UIBezierPath(ovalIn: rect)
            case .square:
                path = UIBezierPath(roundedRect: rect, cornerRadius: UX.swatchCornerRadius)
            }
            color.setFill()
            path.fill()
            UIColor.separator.setStroke()
            path.lineWidth = UX.swatchStrokeWidth
            path.stroke()
        }
    }

    private func presentCustomAccentActions(from sourceView: UIView?) {
        let hex = Prefs.AppearanceSettings.customAccentHex
        let alert = UIAlertController(
            title: "Custom Accent",
            message: "Current color: \(hex)",
            preferredStyle: .actionSheet
        )

        if #available(iOS 14.0, *) {
            alert.addAction(UIAlertAction(title: "Choose Custom Color", style: .default) { [weak self] _ in
                self?.presentCustomColorPicker(sourceView: sourceView)
            })
        }

        alert.addAction(UIAlertAction(title: "Enter Hex Code", style: .default) { [weak self] _ in
            self?.presentCustomHexEntry()
        })
        alert.addAction(UIAlertAction(title: "Use Current Custom Color", style: .default) { [weak self] _ in
            self?.commitCustomAccent(hex: hex, showsError: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController, let sourceView {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }

        present(alert, animated: true)
    }

    @available(iOS 14.0, *)
    private func presentCustomColorPicker(sourceView: UIView?) {
        let picker = UIColorPickerViewController()
        picker.title = "Choose Custom Color"
        picker.selectedColor = Prefs.AppearanceSettings.customAccentColor
        picker.supportsAlpha = false
        picker.delegate = self
        picker.modalPresentationStyle = .popover

        if let popover = picker.popoverPresentationController, let sourceView {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }

        present(picker, animated: true)
    }

    private func presentCustomHexEntry() {
        let alert = UIAlertController(
            title: "Custom Accent Hex",
            message: "Enter a 6-digit color value.",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.text = Prefs.AppearanceSettings.customAccentHex
            textField.placeholder = BrowserAccentColor.defaultCustomHex
            textField.keyboardType = .asciiCapable
            textField.autocapitalizationType = .allCharacters
            textField.autocorrectionType = .no
            textField.clearButtonMode = .whileEditing
            textField.accessibilityLabel = "Custom accent hex code"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Apply", style: .default) { [weak self, weak alert] _ in
            self?.commitCustomAccent(hex: alert?.textFields?.first?.text ?? "", showsError: true)
        })
        present(alert, animated: true)
    }

    @discardableResult
    private func commitCustomAccent(hex: String, showsError: Bool) -> Bool {
        guard let normalizedHex = BrowserAccentColor.normalizedCustomHex(hex) else {
            showCustomAccentError("Enter a 6-digit hex color such as #007AFF.", showsError: showsError)
            return false
        }

        if let validationMessage = BrowserAccentColor.validationMessage(forCustomHex: normalizedHex) {
            showCustomAccentError(validationMessage, showsError: showsError)
            return false
        }

        Prefs.AppearanceSettings.customAccentHex = normalizedHex
        Prefs.AppearanceSettings.accentColor = .custom
        reloadAccentSection()
        return true
    }

    @discardableResult
    private func commitCustomAccent(color: UIColor, showsError: Bool) -> Bool {
        if let validationMessage = BrowserAccentColor.validationMessage(forCustomColor: color) {
            showCustomAccentError(validationMessage, showsError: showsError)
            return false
        }

        Prefs.AppearanceSettings.customAccentHex = color.toHexString().uppercased()
        Prefs.AppearanceSettings.accentColor = .custom
        reloadAccentSection()
        return true
    }

    private func showCustomAccentError(_ message: String, showsError: Bool) {
        guard showsError else { return }
        let alert = UIAlertController(title: "Invalid Accent Color", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func reloadAccentSection() {
        guard let section = displayedSections.firstIndex(of: .accent) else {
            tableView.reloadData()
            return
        }
        tableView.reloadSections(IndexSet(integer: section), with: .automatic)
    }
}

@available(iOS 14.0, *)
extension AppearancePreferencesViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        commitCustomAccent(color: viewController.selectedColor, showsError: false)
    }

    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        commitCustomAccent(color: viewController.selectedColor, showsError: true)
    }
}
