import Foundation

enum DayParseError: LocalizedError {
    case missingFrontmatter
    case missingDate
    case missingSection(SectionKind)

    var errorDescription: String? {
        switch self {
        case .missingFrontmatter:        "Súbor dňa nemá YAML hlavičku."
        case .missingDate:               "Hlavička súboru nemá kľúč `date`."
        case .missingSection(let kind):  "Súbor dňa nemá sekciu `\(kind.rawValue)`."
        }
    }
}

/// Parses a day .md file into a typed `DayContent`. The format is fixed:
///
///     ---
///     date: YYYY-MM-DD
///     feast: null
///     season: easter
///     scripture_ref: Jn 21,15-19
///     thought_author: sv. Bernard z Clairvaux
///     ---
///
///     ## morning.prayer
///     <body>
///
///     ## morning.scripture
///     <body>
///     ... eight sections in any order
///
/// We do **not** use a general YAML parser — the frontmatter is a flat scalar
/// dictionary and a generic dependency would be overkill.
enum DayParser {
    static func parse(_ text: String) throws -> DayContent {
        let (frontmatter, body) = try splitFrontmatter(text)
        guard let date = frontmatter["date"] ?? nil else {
            throw DayParseError.missingDate
        }

        var sections: [SectionKind: String] = [:]
        for kind in SectionKind.allCases {
            guard let chunk = extractSection(named: kind.rawValue, from: body) else {
                throw DayParseError.missingSection(kind)
            }
            sections[kind] = chunk
        }

        return DayContent(
            date: date,
            feast: frontmatter["feast"] ?? nil,
            season: frontmatter["season"] ?? nil,
            scriptureRef: frontmatter["scripture_ref"] ?? nil,
            thoughtAuthor: frontmatter["thought_author"] ?? nil,
            sections: sections,
            frontmatter: frontmatter
        )
    }

    // MARK: - Frontmatter

    private static func splitFrontmatter(_ text: String) throws -> ([String: String?], String) {
        let trimmed = text.hasPrefix("\u{FEFF}") ? String(text.dropFirst()) : text
        guard trimmed.hasPrefix("---\n") else {
            throw DayParseError.missingFrontmatter
        }
        let afterOpener = trimmed.index(trimmed.startIndex, offsetBy: 4)
        guard let closeRange = trimmed.range(of: "\n---\n", range: afterOpener..<trimmed.endIndex) else {
            throw DayParseError.missingFrontmatter
        }
        let yaml = String(trimmed[afterOpener..<closeRange.lowerBound])
        let body = String(trimmed[closeRange.upperBound...])
        return (parseFrontmatter(yaml), body)
    }

    private static func parseFrontmatter(_ yaml: String) -> [String: String?] {
        var out: [String: String?] = [:]
        for raw in yaml.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = line[..<colon].trimmingCharacters(in: .whitespaces)
            var value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            if value.isEmpty || value.lowercased() == "null" || value == "~" {
                out[key] = .some(nil)
                continue
            }
            if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
               (value.hasPrefix("'") && value.hasSuffix("'")) {
                value = String(value.dropFirst().dropLast())
            }
            out[key] = value
        }
        return out
    }

    // MARK: - Sections

    /// Pull body of `## name` up to the next `## ` or end of text.
    private static func extractSection(named name: String, from body: String) -> String? {
        let header = "## \(name)"
        // Find header at the start of a line.
        guard let headerRange = range(ofHeader: header, in: body) else { return nil }
        let contentStart = body.index(headerRange.upperBound, offsetBy: 0)
        // Advance to the newline after the header.
        guard let lineEnd = body.range(of: "\n", range: contentStart..<body.endIndex) else {
            return ""
        }
        let afterHeader = lineEnd.upperBound
        // Find next "\n## " (start of next section).
        if let nextHeader = body.range(of: "\n## ", range: afterHeader..<body.endIndex) {
            return String(body[afterHeader..<nextHeader.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return String(body[afterHeader...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    /// Finds an `## header` line anchored at the start of a line.
    private static func range(ofHeader header: String, in body: String) -> Range<String.Index>? {
        if body.hasPrefix(header) {
            return body.startIndex..<body.index(body.startIndex, offsetBy: header.count)
        }
        let needle = "\n\(header)"
        if let r = body.range(of: needle) {
            return body.index(after: r.lowerBound)..<r.upperBound
        }
        return nil
    }
}
