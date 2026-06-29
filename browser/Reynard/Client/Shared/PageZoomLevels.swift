//
//  PageZoomLevels.swift
//  Reynard
//
//  Created by Minh Ton on 28/6/26.
//

import CoreGraphics
import Foundation

enum PageZoomLevels {
    static let defaultLevel = 100
    static let all = [50, 75, 90, 100, 110, 125, 150, 175, 200, 250, 300]
    
    static func displayText(for level: Int) -> String {
        return "\(level)%"
    }

    static func clamped(_ level: Int) -> Int {
        min(max(level, all.first ?? defaultLevel), all.last ?? defaultLevel)
    }

    static func nearestLevel(to level: CGFloat) -> Int {
        let boundedLevel = CGFloat(clamped(Int(level.rounded())))
        return all.min { lhs, rhs in
            abs(CGFloat(lhs) - boundedLevel) < abs(CGFloat(rhs) - boundedLevel)
        } ?? defaultLevel
    }

    static func level(from baseLevel: Int, scale: CGFloat) -> Int {
        nearestLevel(to: CGFloat(baseLevel) * max(scale, 0.01))
    }
}
