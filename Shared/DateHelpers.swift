import Foundation

extension Calendar {
    /// Every day (as start-of-day) in the week, month or year that contains `date`.
    func days(in component: Calendar.Component, containing date: Date) -> [Date] {
        guard let interval = dateInterval(of: component, for: date) else { return [] }
        var result: [Date] = []
        var day = startOfDay(for: interval.start)
        while day < interval.end {
            result.append(day)
            guard let next = self.date(byAdding: .day, value: 1, to: day) else { break }
            day = startOfDay(for: next)
        }
        return result
    }

    /// 0 for the first column of the week, 6 for the last, following the user's region.
    func weekdayOffset(of date: Date) -> Int {
        (component(.weekday, from: date) - firstWeekday + 7) % 7
    }

    /// One-letter weekday names, starting on the user's first day of the week.
    var orderedWeekdayLetters: [String] {
        let symbols = veryShortStandaloneWeekdaySymbols
        let start = max(0, min(symbols.count - 1, firstWeekday - 1))
        return Array(symbols[start...] + symbols[..<start])
    }
}

/// "8,000", "1.5", "24".
func formatAmount(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(0...2)))
}

/// Reads "1.5" or "1,5" typed by the user.
func parseAmount(_ text: String) -> Double? {
    let cleaned = text
        .trimmingCharacters(in: .whitespaces)
        .replacingOccurrences(of: ",", with: ".")
    return Double(cleaned)
}

/// Number without thousands separators, for text fields.
func plainAmount(_ value: Double) -> String {
    value.formatted(.number.grouping(.never).precision(.fractionLength(0...2)))
}
