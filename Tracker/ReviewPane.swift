import SwiftUI
import SwiftData

/// Wide screens (iPhone Duo open): one tracker's week, month and year at a glance.
/// Tap any past dot to log or fix that day.
struct ReviewPane: View {
    let tracker: Tracker?
    let today: Date
    var onOpen: (Tracker, Date) -> Void

    @Environment(\.palette) private var palette

    private let monthColumns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let yearColumns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 21)

    var body: some View {
        if let tracker {
            content(tracker)
        } else {
            EmptyHint()
        }
    }

    private func content(_ tracker: Tracker) -> some View {
        let calendar = Calendar.current
        let values = tracker.valuesByDay()
        let weekDays = calendar.days(in: .weekOfYear, containing: today)
        let monthDays = calendar.days(in: .month, containing: today)
        let yearDays = calendar.days(in: .year, containing: today)
        let blanks = monthDays.first.map { calendar.weekdayOffset(of: $0) } ?? 0
        let weekDone = tracker.doneCount(in: weekDays, values: values)
        let monthDone = tracker.doneCount(in: monthDays, values: values)
        let yearDone = tracker.doneCount(in: yearDays, values: values)
        let yearStates = tracker.states(for: yearDays, values: values, today: today)

        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(tracker.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(palette.ink)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(tracker.goalText)
                    .font(.system(size: 13))
                    .foregroundStyle(palette.muted)
                    .lineLimit(1)
            }
            .frame(height: 44)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    sectionHeader("This week", weekText(tracker, done: weekDone, days: weekDays.count))
                        .padding(.top, 12)
                    HStack(spacing: 0) {
                        ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                            dayButton(tracker, day: day, values: values, size: 30)
                            if index < weekDays.count - 1 { Spacer(minLength: 0) }
                        }
                    }
                    .padding(.top, 10)

                    sectionHeader(today.formatted(.dateTime.month(.wide)), "\(monthDone) days")
                        .padding(.top, 30)
                    LazyVGrid(columns: monthColumns, spacing: 7) {
                        ForEach(0..<blanks, id: \.self) { _ in
                            Color.clear.frame(height: 30)
                        }
                        ForEach(monthDays, id: \.self) { day in
                            dayButton(tracker, day: day, values: values, size: 30)
                        }
                    }
                    .padding(.top, 10)

                    sectionHeader(today.formatted(.dateTime.year()), "\(yearDone) days")
                        .padding(.top, 30)
                    LazyVGrid(columns: yearColumns, spacing: 4) {
                        ForEach(Array(yearStates.enumerated()), id: \.offset) { _, state in
                            DotView(state: state, size: 8)
                        }
                    }
                    .padding(.top, 10)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(yearDone) days done this year")
                }
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 24)
        .id(tracker.uuid)
        .transition(.opacity)
    }

    private func sectionHeader(_ title: String, _ trailing: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Caption(text: title)
            Spacer()
            Text(trailing)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(palette.muted)
                .contentTransition(.numericText())
                .animation(.dot, value: trailing)
        }
    }

    private func dayButton(_ tracker: Tracker, day: Date, values: [Date: Double], size: CGFloat) -> some View {
        Button {
            if day <= today { onOpen(tracker, day) }
        } label: {
            DotView(state: tracker.state(for: day, values: values, today: today), size: size)
        }
        .buttonStyle(PressScale())
        .disabled(day > today)
    }

    private func weekText(_ tracker: Tracker, done: Int, days: Int) -> String {
        if tracker.kind == .check && tracker.period == .week {
            return "\(done) of \(Int(tracker.goal))"
        }
        return "\(done) of \(days) days"
    }
}
