//
//  AppAppearanceController.swift
//  Reynard
//
//  Created by Minh Ton on 22/6/26.
//

import UIKit

@MainActor
enum AppAppearanceController {
    static func apply(_ appearance: AppAppearance) {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .forEach { window in
                window.overrideUserInterfaceStyle = userInterfaceStyle(for: appearance)
                window.backgroundColor = BrowserAppearance.backgroundColor
                window.tintColor = BrowserAppearance.accentColor
                window.rootViewController?.view.tintColor = BrowserAppearance.accentColor
                window.rootViewController?.view.setNeedsLayout()
                window.setNeedsLayout()
            }
    }
    
    static func userInterfaceStyle(for appearance: AppAppearance) -> UIUserInterfaceStyle {
        switch appearance {
        case .system:
            return .unspecified
        case .light:
            return .light
        case .dark, .oledBlack:
            return .dark
        }
    }
}
