import SwiftUI
import SwiftData

/// This week: seven dots per tracker. Tap a dot to log or fix that day.
struct WeekView: View {
    let trackers: [Tracker]
    let today: Date
    var onOpen: (Tracker, Date) -> Void

    @Environment(\.palette) private var palette

    private let dotSize: CGFloat = 36

    var body: some View {
        let calendar = Calendar.current
        let days = calendar.days(in: .weekOfYear, containing: today)
        let letters = calendar.orderedWeekdayLetters
        let todayIndex = calendar.weekdayOffset(of: today)

        VStack(alignment: .leading, spacing: 0) {
            Hero(
                big: "\(calendar.component(.weekOfYear, from: today))",
                title: "Week",
                subtitle: rangeText(days),
                size: 110
            ) {
                Text(today.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.system(size: 22))
                    .foregroundStyle(palette.ink)
            }
            .padding(.top, 12)

            HStack(spacing: 0) {
                ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                    Text(letter)
                        .font(.system(size: 12, weight: index == todayIndex ? .bold : .regular))
                        .foregroundStyle(index == todayIndex ? palette.ink : palette.muted)
                        .frame(width: dotSize)
                    if index < letters.count - 1 { Spacer(minLength: 0) }
                }
            }
            .padding(.top, 24)

            ScrollView {
                VStack(spacing: 18) {
                    ForEach(trackers) { tracker in
                        WeekRow(tracker: tracker, days: days, today: today, dotSize: dotSize, onOpen: onOpen)
                    }
                }
                .padding(.top, 14)
            }
            .scrollIndicators(.hidden)

            Caption(text: "Filled is done · Ring is open")
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }

    private func rangeText(_ days: [Date]) -> String {
        guard let first = days.first, let last = days.last else { return "" }
        let style = Date.FormatStyle.dateTime.month(.abbreviated).day()
        return "\(first.formatted(style)) – \(last.formatted(style))"
    }
}

struct WeekRow: View {
    let tracker: Tracker
    let days: [Date]
    let today: Date
    let dotSize: CGFloat
    var onOpen: (Tracker, Date) -> Void

    @Environment(\.palette) private var palette

    var body: some View {
        let values = tracker.valuesByDay()
        let count = tracker.doneCount(in: days, values: values)

        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(tracker.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(palette.ink)
                Spacer()
                Text(countText(count))
                    .font(.system(size: 13))
                    .foregroundStyle(palette.muted)
                    .contentTransition(.numericText())
                    .animation(.dot, value: count)
            }

            HStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    Button {
                        if day <= today { onOpen(tracker, day) }
                    } label: {
                        DotView(state: tracker.state(for: day, values: values, today: today), size: dotSize)
                    }
                    .buttonStyle(PressScale())
                    .disabled(day > today)
                    if index < days.count - 1 { Spacer(minLength: 0) }
                }
            }
        }
    }

    private func countText(_ count: Int) -> String {
        if tracker.kind == .check && tracker.period == .week {
            return "\(count) of \(Int(tracker.goal))"
        }
        return "\(count) of \(days.count) days"
    }
}
