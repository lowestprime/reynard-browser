//
//  AppearancePreferencesViewController.swift
//  Reynard
//
//  Created by Minh Ton on 18/6/26.
//

import UIKit

final class AppearancePreferencesViewController: SettingsTableViewController {
    private enum Section: CaseIterable {
        case theme
        case accent
        case tabs
        
        var text: SettingsSectionText {
            switch self {
            case .theme:
                return SettingsSectionText(
                    headerTitle: "Theme",
                    footerTitle: "OLED Black uses true black surfaces when the interface is in dark appearance."
                )
            case .accent:
                return SettingsSectionText(headerTitle: "Accent")
            case .tabs:
                return SettingsSectionText(headerTitle: "Tabs")
            }
        }
    }
    
    private enum Row {
        case theme(BrowserThemeMode)
        case accent(BrowserAccentColor)
        case browserChromePosition
        case landscapeTabBar
    }
    
    private let landscapeTabBarSwitch = UISwitch()
    
    private var displayedSections: [Section] {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return [.theme, .accent]
        }

        return Section.allCases
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
        return rows(for: displayedSections[section]).count
    }
    
    override func sectionText(for section: Int) -> SettingsSectionText {
        guard displayedSections.indices.contains(section) else {
            return SettingsSectionText()
        }
        return displayedSections[section].text
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard displayedSections.indices.contains(indexPath.section),
              rows(for: displayedSections[indexPath.section]).indices.contains(indexPath.row) else {
            return UITableViewCell()
        }

        switch rows(for: displayedSections[indexPath.section])[indexPath.row] {
        case let .theme(mode):
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = mode.displayName
            cell.accessoryType = mode == Prefs.AppearanceSettings.themeMode ? .checkmark : .none
            return cell
        case let .accent(accent):
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = accent.displayName
            cell.imageView?.image = swatchImage(color: accent.color)
            cell.accessoryType = accent == Prefs.AppearanceSettings.accentColor ? .checkmark : .none
            return cell
        case .browserChromePosition:
            let cell = BrowserChromePositionPickerCell(style: .default, reuseIdentifier: nil)
            cell.display(selectedPosition: Prefs.AppearanceSettings.addressBarPosition)
            cell.onPositionChanged = { position in
                Prefs.AppearanceSettings.addressBarPosition = position
            }
            return cell
        case .landscapeTabBar:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "Landscape Tab Bar"
            cell.selectionStyle = .none
            cell.accessoryView = landscapeTabBarSwitch
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard displayedSections.indices.contains(indexPath.section),
              rows(for: displayedSections[indexPath.section]).indices.contains(indexPath.row) else {
            return
        }

        switch rows(for: displayedSections[indexPath.section])[indexPath.row] {
        case let .theme(mode):
            Prefs.AppearanceSettings.themeMode = mode
            tableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
        case let .accent(accent):
            Prefs.AppearanceSettings.accentColor = accent
            tableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
        case .browserChromePosition, .landscapeTabBar:
            return
        }
    }
    
    private func configureSwitch() {
        landscapeTabBarSwitch.addTarget(self, action: #selector(landscapeTabBarSwitchDidChange), for: .valueChanged)
    }
    
    private func refreshDisplayedState() {
        landscapeTabBarSwitch.isOn = Prefs.AppearanceSettings.showsLandscapeTabBar
    }
    
    @objc private func landscapeTabBarSwitchDidChange() {
        Prefs.AppearanceSettings.showsLandscapeTabBar = landscapeTabBarSwitch.isOn
    }

    private func rows(for section: Section) -> [Row] {
        switch section {
        case .theme:
            return BrowserThemeMode.allCases.map(Row.theme)
        case .accent:
            return BrowserAccentColor.allCases.map(Row.accent)
        case .tabs:
            return [.browserChromePosition, .landscapeTabBar]
        }
    }

    private func swatchImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 22, height: 22)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 2, dy: 2)
            color.setFill()
            UIBezierPath(ovalIn: rect).fill()
        }
    }
}
