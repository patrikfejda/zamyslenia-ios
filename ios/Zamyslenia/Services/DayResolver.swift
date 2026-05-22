import Foundation

/// Resolves the "logical day" — the date+mode the user should see for a given
/// wall-clock time.
///
/// People often read evening prayer past midnight, so flipping to the next
/// day at 00:00 would surprise them. Instead:
///
///     04:00 – 14:59  →  morning of *today*
///     15:00 – 23:59  →  evening of *today*
///     00:00 – 03:59  →  evening of *yesterday*
///
/// The window boundaries are tunable here if needed; everything else in the
/// app reads from this single resolver.
enum DayResolver {
    static let morningStartHour = 4
    static let eveningStartHour = 15

    struct Resolved: Equatable {
        let date: String        // "YYYY-MM-DD"
        let mode: DayMode
    }

    static func resolve(now: Date = .now, calendar: Calendar = .current) -> Resolved {
        var cal = calendar
        cal.timeZone = TimeZone.current
        let hour = cal.component(.hour, from: now)

        switch hour {
        case morningStartHour..<eveningStartHour:
            return Resolved(date: isoDate(now, calendar: cal), mode: .morning)
        case eveningStartHour...23:
            return Resolved(date: isoDate(now, calendar: cal), mode: .evening)
        default:
            // 00:00–03:59 — still "yesterday's evening".
            let yesterday = cal.date(byAdding: .day, value: -1, to: now) ?? now
            return Resolved(date: isoDate(yesterday, calendar: cal), mode: .evening)
        }
    }

    static func isoDate(_ date: Date, calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }

    static func parse(isoDate: String, calendar: Calendar = .current) -> Date? {
        let parts = isoDate.split(separator: "-")
        guard parts.count == 3,
              let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]) else { return nil }
        var comps = DateComponents()
        comps.year = y; comps.month = m; comps.day = d
        comps.hour = 12  // anchor at noon to avoid DST edges
        return calendar.date(from: comps)
    }

    static func shift(isoDate: String, by days: Int, calendar: Calendar = .current) -> String? {
        guard let date = parse(isoDate: isoDate, calendar: calendar),
              let shifted = calendar.date(byAdding: .day, value: days, to: date)
        else { return nil }
        return self.isoDate(shifted, calendar: calendar)
    }
}
