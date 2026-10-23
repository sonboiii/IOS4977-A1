import Foundation

enum DateParsing {
    /// Parses the API's date-only values ("2026-10-17") in the device's time zone,
    /// so the day doesn't shift when displayed.
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let isoFormatter = ISO8601DateFormatter()

    static func date(fromDay string: String) -> Date? {
        dayFormatter.date(from: string)
    }

    static func displayDate(fromDay string: String) -> String {
        guard let date = date(fromDay: string) else { return string }
        return date.formatted(date: .long, time: .omitted)
    }

    /// .NET writes up to 7 fractional-second digits ("2026-10-22T22:41:07.1234567Z"),
    /// which ISO8601DateFormatter doesn't always accept, so the fraction is dropped first.
    static func date(fromISO string: String) -> Date? {
        guard string.count >= 19 else { return nil }
        let trimmed = String(string.prefix(19)) + "Z"
        return isoFormatter.date(from: trimmed)
    }
}
