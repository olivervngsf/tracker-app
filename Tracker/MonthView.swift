import SwiftUI
import SwiftData

/// One tracker, one month of dots. Tap a dot to log or fix that day.
struct MonthView: View {
    let trackers: [Tracker]
    let tracker: Tracker?
    let today: Date
    var onSelect: (Tracker) -> Void
    var onOpen: (Tracker, Date) -> Void

    @Environment(\.palette) private var palette
    @State private var anchor = Calendar.current.startOfDay(for: Date())

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        if let tracker {
            content(tracker)
        } else {
            EmptyHint()
        }
    }

    private func content(_ tracker: Tracker) -> some View {
        let calendar = Calendar.current
        let days = calendar.days(in: .month, containing: anchor)
        let blanks = days.first.map { calendar.weekdayOffset(of: $0) } ?? 0
        let values = tracker.valuesByDay()
        let count = tracker.doneCount(in: days, values: values)

        return VStack(alignment: .leading, spacing: 0) {
            Hero(
                big: "\(count)",
                title: "Days done",
                subtitle: anchor.formatted(.dateTime.month(.wide).year())
            ) {
                TrackerMenu(trackers: trackers, tracker: tracker, onSelect: onSelect)
            }
            .padding(.top, 12)

            HStack(spacing: 4) {
                chevron("chevron.left", label: "Previous month") { shift(-1) }
                chevron("chevron.right", label: "Next month") { shift(1) }
            }
            .padding(.leading, -12)
            .padding(.top, 8)

            HStack(spacing: 0) {
                ForEach(Array(calendar.orderedWeekdayLetters.enumerated()), id: \.offset) { _, letter in
                    Text(letter)
                        .font(.system(size: 12))
                        .foregroundStyle(palette.muted)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 8)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<blanks, id: \.self) { _ in
                    Color.clear.frame(height: 42)
                }
                ForEach(days, id: \.self) { day in
                    Button {
                        if day <= today { onOpen(tracker, day) }
                    } label: {
                        DotView(state: tracker.state(for: day, values: values, today: today), size: 42)
                    }
                    .buttonStyle(PressScale())
                    .disabled(day > today)
                }
            }
            .padding(.top, 10)
            .id(anchor)
            .transition(.opacity)

            Spacer(minLength: 0)

            Caption(text: "Goal · \(tracker.goalText)")
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }

    private func chevron(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(palette.ink)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressScale())
        .accessibilityLabel(label)
    }

    private func shift(_ months: Int) {
        guard let next = Calendar.current.date(byAdding: .month, value: months, to: anchor) else { return }
        withAnimation(.easeInOut(duration: 0.25)) { anchor = next }
    }
}
