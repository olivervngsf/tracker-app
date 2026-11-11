import SwiftUI
import SwiftData

/// One tracker, the whole year: one dot per day.
struct YearView: View {
    let trackers: [Tracker]
    let tracker: Tracker?
    let today: Date
    var onSelect: (Tracker) -> Void

    @Environment(\.palette) private var palette

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 18)

    var body: some View {
        if let tracker {
            content(tracker)
        } else {
            EmptyHint()
        }
    }

    private func content(_ tracker: Tracker) -> some View {
        let calendar = Calendar.current
        let days = calendar.days(in: .year, containing: today)
        let values = tracker.valuesByDay()
        let states = tracker.states(for: days, values: values, today: today)
        let count = tracker.doneCount(in: days, values: values)
        let dayNumber = (days.firstIndex(of: today) ?? 0) + 1

        return VStack(alignment: .leading, spacing: 0) {
            Hero(
                big: "\(count)",
                title: "Days done",
                subtitle: today.formatted(.dateTime.year()),
                size: 120
            ) {
                TrackerMenu(trackers: trackers, tracker: tracker, onSelect: onSelect)
            }
            .padding(.top, 12)

            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(Array(states.enumerated()), id: \.offset) { _, state in
                    DotView(state: state, size: 14)
                }
            }
            .padding(.top, 28)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(count) days done this year")

            Spacer(minLength: 0)

            HStack {
                Text("day \(dayNumber) of \(days.count)")
                Spacer()
                Text("\(days.count - dayNumber) days left")
            }
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(palette.muted)
            .frame(height: 44)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }
}
