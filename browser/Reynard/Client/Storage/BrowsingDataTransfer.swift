//
//  BrowsingDataTransfer.swift
//  Reynard
//
//  Created by Reynard on 23/6/26.
//

import Foundation

struct BookmarkImportItem: Hashable {
    let title: String
    let url: URL
}

struct HistoryImportItem: Hashable {
    let title: String
    let url: URL
    let visitedAt: Date
}

struct DataImportSummary {
    let imported: Int
    let skipped: Int
}

enum BookmarkHTMLTransfer {
    static let fileName = "Reynard-Bookmarks.html"

    static func exportHTML(bookmarks: [BookmarkSnapshot]) -> Data {
        let lines = bookmarks.map { bookmark in
            let title = escapeHTML(bookmark.title)
            let url = escapeHTML(bookmark.url.absoluteString)
            let added = Int(bookmark.dateAdded.timeIntervalSince1970)
            return "<DT><A HREF=\"\(url)\" ADD_DATE=\"\(added)\">\(title)</A>"
        }
        let html = """
        <!DOCTYPE NETSCAPE-Bookmark-file-1>
        <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
        <TITLE>Bookmarks</TITLE>
        <H1>Bookmarks</H1>
        <DL><p>
        \(lines.joined(separator: "\n"))
        </DL><p>
        """
        return Data(html.utf8)
    }

    static func parseBookmarks(from data: Data) -> [BookmarkImportItem] {
        guard let text = decodeText(data) else {
            return []
        }

        let pattern = #"<A\s+[^>]*HREF\s*=\s*(["'])(.*?)\1[^>]*>(.*?)</A>"#
        guard let expression = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return []
        }

        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        return expression.matches(in: text, range: range).compactMap { match in
            guard match.numberOfRanges >= 4 else {
                return nil
            }

            let rawURL = unescapeHTML(nsText.substring(with: match.range(at: 2)))
            let rawTitle = stripHTML(unescapeHTML(nsText.substring(with: match.range(at: 3))))
            guard let url = URL(string: rawURL.trimmingCharacters(in: .whitespacesAndNewlines)),
                  URLUtils.isAbsoluteURL(url) else {
                return nil
            }

            let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            return BookmarkImportItem(
                title: title.isEmpty ? url.host ?? url.absoluteString : title,
                url: url
            )
        }
    }
}

enum HistoryCSVTransfer {
    static let fileName = "Reynard-History.csv"

    private static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func exportCSV(items: [HistorySiteSnapshot]) -> Data {
        let rows = [["Title", "URL", "Last Visited"]] + items.map { item in
            [
                item.title,
                item.url.absoluteString,
                formatter.string(from: item.lastVisitedAt),
            ]
        }
        let csv = rows.map { row in
            row.map(escapeCSV).joined(separator: ",")
        }.joined(separator: "\n")
        return Data(csv.utf8)
    }

    static func parseHistory(from data: Data) -> [HistoryImportItem] {
        guard let text = decodeText(data) else {
            return []
        }

        let records = parseCSVRecords(text)
        guard !records.isEmpty else {
            return []
        }

        let dataRows: ArraySlice<[String]>
        if let firstRow = records.first,
           firstRow.contains(where: { $0.caseInsensitiveCompare("URL") == .orderedSame }) {
            dataRows = records.dropFirst()
        } else {
            dataRows = records[...]
        }

        return dataRows.compactMap { row in
            guard row.count >= 2,
                  let url = URL(string: row[1].trimmingCharacters(in: .whitespacesAndNewlines)),
                  URLUtils.isWebURL(url) else {
                return nil
            }

            let title = row[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let visitedAt: Date
            if row.count >= 3,
               let parsedDate = formatter.date(from: row[2].trimmingCharacters(in: .whitespacesAndNewlines)) {
                visitedAt = parsedDate
            } else {
                visitedAt = Date()
            }

            return HistoryImportItem(
                title: title.isEmpty ? url.host ?? url.absoluteString : title,
                url: url,
                visitedAt: visitedAt
            )
        }
    }

    private static func escapeCSV(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private static func parseCSVRecords(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var isQuoted = false
        var iterator = text.makeIterator()

        while let character = iterator.next() {
            if character == "\"" {
                if isQuoted, let next = iterator.next() {
                    if next == "\"" {
                        field.append("\"")
                    } else {
                        isQuoted = false
                        handleCSVDelimiter(next, row: &row, rows: &rows, field: &field, isQuoted: isQuoted)
                    }
                } else {
                    isQuoted.toggle()
                }
                continue
            }

            handleCSVDelimiter(character, row: &row, rows: &rows, field: &field, isQuoted: isQuoted)
        }

        row.append(field)
        if row.contains(where: { !$0.isEmpty }) {
            rows.append(row)
        }
        return rows
    }

    private static func handleCSVDelimiter(
        _ character: Character,
        row: inout [String],
        rows: inout [[String]],
        field: inout String,
        isQuoted: Bool
    ) {
        if !isQuoted, character == "," {
            row.append(field)
            field = ""
            return
        }

        if !isQuoted, character == "\n" {
            row.append(field)
            rows.append(row)
            row = []
            field = ""
            return
        }

        if character != "\r" {
            field.append(character)
        }
    }
}

private func decodeText(_ data: Data) -> String? {
    String(data: data, encoding: .utf8)
    ?? String(data: data, encoding: .isoLatin1)
}

private func escapeHTML(_ value: String) -> String {
    value
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
}

private func unescapeHTML(_ value: String) -> String {
    value
        .replacingOccurrences(of: "&quot;", with: "\"")
        .replacingOccurrences(of: "&#34;", with: "\"")
        .replacingOccurrences(of: "&apos;", with: "'")
        .replacingOccurrences(of: "&#39;", with: "'")
        .replacingOccurrences(of: "&lt;", with: "<")
        .replacingOccurrences(of: "&gt;", with: ">")
        .replacingOccurrences(of: "&amp;", with: "&")
}

private func stripHTML(_ value: String) -> String {
    guard let expression = try? NSRegularExpression(pattern: "<[^>]+>", options: []) else {
        return value
    }

    let range = NSRange(location: 0, length: (value as NSString).length)
    return expression.stringByReplacingMatches(in: value, range: range, withTemplate: "")
}
