//
//  LocalURLCompletion.swift
//  Reynard
//
//  Created by Reynard on 23/6/26.
//

import Foundation

enum LocalURLCompletion {
    private static let commonDomains = [
        "apple.com",
        "google.com",
        "youtube.com",
        "github.com",
        "reddit.com",
        "wikipedia.org",
        "chatgpt.com",
        "mozilla.org",
        "news.ycombinator.com",
        "stackoverflow.com",
    ]

    static func completions(for query: String, limit: Int = 5) -> [String] {
        let normalizedQuery = URLUtils.normalizedURLMatchString(from: query.trimmingCharacters(in: .whitespacesAndNewlines))
        guard normalizedQuery.count >= 2 else {
            return []
        }

        var completions: [String] = []
        for domain in commonDomains where domain.hasPrefix(normalizedQuery) {
            completions.append(domain)
            if completions.count >= limit {
                return completions
            }
        }

        guard !normalizedQuery.contains(" "),
              !normalizedQuery.contains("."),
              normalizedQuery.count >= 3 else {
            return completions
        }

        let fallback = "\(normalizedQuery).com"
        if !commonDomains.contains(fallback) {
            completions.append(fallback)
        }
        return Array(completions.prefix(limit))
    }
}
