//
//  BrowserAppearance.swift
//  Reynard
//
//  Created by Reynard on 23/6/26.
//

import UIKit

enum BrowserThemeMode: String, CaseIterable {
    case system
    case light
    case dark
    case oledBlack

    var displayName: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .oledBlack:
            return "OLED Black"
        }
    }

    var overrideStyle: UIUserInterfaceStyle {
        switch self {
        case .system:
            return .unspecified
        case .light:
            return .light
        case .dark, .oledBlack:
            return .dark
        }
    }
}

enum BrowserAccentColor: String, CaseIterable {
    case highContrast
    case blue
    case orange
    case green
    case purple

    var displayName: String {
        switch self {
        case .highContrast:
            return "High Contrast"
        case .blue:
            return "Blue"
        case .orange:
            return "Orange"
        case .green:
            return "Green"
        case .purple:
            return "Purple"
        }
    }

    var color: UIColor {
        switch self {
        case .highContrast:
            return .label
        case .blue:
            return .systemBlue
        case .orange:
            return .systemOrange
        case .green:
            return .systemGreen
        case .purple:
            return .systemPurple
        }
    }
}

enum BrowserAppearance {
    static func apply(to window: UIWindow?) {
        guard let window else { return }
        window.overrideUserInterfaceStyle = Prefs.AppearanceSettings.themeMode.overrideStyle
        window.tintColor = accentColor
        window.rootViewController?.view.tintColor = accentColor
    }

    static var accentColor: UIColor {
        Prefs.AppearanceSettings.accentColor.color
    }

    static var backgroundColor: UIColor {
        dynamicColor(oled: .black, standard: .systemBackground)
    }

    static var groupedBackgroundColor: UIColor {
        dynamicColor(oled: .black, standard: .systemGroupedBackground)
    }

    static var toolbarBackgroundColor: UIColor {
        dynamicColor(oled: .black, standard: .systemGray6)
    }

    static var surfaceColor: UIColor {
        dynamicColor(oled: UIColor(white: 0.04, alpha: 1), standard: .systemBackground)
    }

    static var secondarySurfaceColor: UIColor {
        dynamicColor(oled: UIColor(white: 0.08, alpha: 1), standard: .secondarySystemBackground)
    }

    private static func dynamicColor(oled: UIColor, standard: UIColor) -> UIColor {
        UIColor { traitCollection in
            guard Prefs.AppearanceSettings.themeMode == .oledBlack,
                  traitCollection.userInterfaceStyle == .dark else {
                return standard
            }
            return oled
        }
    }
}
