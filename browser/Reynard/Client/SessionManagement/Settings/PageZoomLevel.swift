//
//  PageZoomLevel.swift
//  Reynard
//
//  Created by Reynard on 23/6/26.
//

import Foundation

enum PageZoomLevel {
    static let defaultPercent = 100
    static let allowedPercents = [50, 75, 85, 100, 115, 125, 150, 175, 200, 250, 300]

    static func normalizedPercent(_ percent: Int) -> Int {
        allowedPercents.min { first, second in
            abs(first - percent) < abs(second - percent)
        } ?? defaultPercent
    }

    static func scale(for percent: Int) -> Double {
        Double(normalizedPercent(percent)) / 100
    }

    static func displayTitle(for percent: Int) -> String {
        "\(normalizedPercent(percent))%"
    }

    static func sliderIndex(for percent: Int) -> Int {
        let normalized = normalizedPercent(percent)
        return allowedPercents.firstIndex(of: normalized) ?? allowedPercents.firstIndex(of: defaultPercent) ?? 0
    }

    static func percent(forSliderValue value: Float) -> Int {
        guard !allowedPercents.isEmpty else {
            return defaultPercent
        }

        let roundedIndex = Int(value.rounded())
        let clampedIndex = max(0, min(roundedIndex, allowedPercents.count - 1))
        return allowedPercents[clampedIndex]
    }

    static func lowerPercent(than percent: Int) -> Int? {
        allowedPercents.last { $0 < normalizedPercent(percent) }
    }

    static func higherPercent(than percent: Int) -> Int? {
        allowedPercents.first { $0 > normalizedPercent(percent) }
    }
}
