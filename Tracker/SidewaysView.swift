import SwiftUI
import SwiftData

/// iPhone Duo open and turned sideways. The fold runs across the middle, so the screen is
/// two stacked halves: overview on top, tracker cards with big tap circles below.
struct SidewaysView: View {
    let trackers: [Tracker]
    let tracker: Tracker?
    let today: Date
    let size: CGSize
    var onSelect: (Tracker) -> Void
    var onOpen: (Tracker, Date) -> Void
    var onNew: () -> Void

    @Environment(\.palette) private var palette

    private let sidePadding: CGFloat = 36
    private let foldGap: CGFloat = 48
    private let heroWidth: CGFloat = 290
    private let columnGap: CGFloat = 48

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: columnGap) {
                Hero(
                    big: "\(Calendar.current.component(.day, from: today))",
                    title: today.formatted(.dateTime.month(.wide)),
                    subtitle: today.formatted(.dateTime.year()),
                    size: 130
                ) {
                    Text(today.formatted(.dateTime.weekday(.abbreviated)))
                        .font(.system(size: 22))
                        .foregroundStyle(palette.ink)
                }
                .frame(width: heroWidth)

                if let tracker {
                    overview(tracker)
                } else {
                    EmptyHint()
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)

            // Nothing sits on the fold.
            Color.clear.frame(height: foldGap)

            cards
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, sidePadding)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: Top half

    private func overview(_ tracker: Tracker) -> some View {
        let calendar = Calendar.current
        let values = tracker.valuesByDay()
        let weekDays = calendar.days(in: .weekOfYear, containing: today)
        let yearDays = calendar.days(in: .year, containing: today)
        let weekDone = tracker.doneCount(in: weekDays, values: values)
        let yearDone = tracker.doneCount(in: yearDays, values: values)
        let weeks = yearColumns(tracker, days: yearDays, values: values, calendar: calendar)

        let available = size.width - sidePadding * 2 - heroWidth - columnGap
        let dot = max(4, min(9, ((available - CGFloat(max(weeks.count - 1, 0)) * 2) / CGFloat(max(weeks.count, 1))).rounded(.down)))

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

            header("This week", weekText(tracker, done: weekDone, days: weekDays.count))
                .padding(.top, 16)
            HStack(spacing: 14) {
                ForEach(weekDays, id: \.self) { day in
                    Button {
                        if day <= today { onOpen(tracker, day) }
                    } label: {
                        DotView(
                            state: tracker.state(for: day, values: values, today: today),
                            size: 30,
                            progress: tracker.progress(values[day])
                        )
                    }
                    .buttonStyle(PressScale())
                    .disabled(day > today)
                }
            }
            .padding(.top, 8)

            header("\(today.formatted(.dateTime.year())) · one column per week", "\(yearDone) days")
                .padding(.top, 22)
            HStack(alignment: .top, spacing: 2) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    VStack(spacing: 2) {
                        ForEach(Array(week.enumerated()), id: \.offset) { _, state in
                            DotView(state: state, size: dot)
                        }
                    }
                }
            }
            .padding(.top, 8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(yearDone) days done this year")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .id(tracker.uuid)
        .transition(.opacity)
    }

    /// The year as weeks: each inner array is one column of up to seven days.
    private func yearColumns(_ tracker: Tracker, days: [Date], values: [Date: Double], calendar: Calendar) -> [[DotState]] {
        guard let first = days.first else { return [] }
        var cells: [DotState] = Array(repeating: .blank, count: calendar.weekdayOffset(of: first))
        cells.append(contentsOf: tracker.states(for: days, values: values, today: today))
        return stride(from: 0, to: cells.count, by: 7).map { start in
            Array(cells[start..<min(start + 7, cells.count)])
        }
    }

    private func header(_ title: String, _ trailing: String) -> some View {
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

    private func weekText(_ tracker: Tracker, done: Int, days: Int) -> String {
        if tracker.kind == .check && tracker.period == .week {
            return "\(done) of \(Int(tracker.goal))"
        }
        return "\(done) of \(days) days"
    }

    // MARK: Bottom half

    private var cardWidth: CGFloat {
        let visible = CGFloat(min(max(trackers.count + 1, 1), 5))
        let total = size.width - sidePadding * 2 - 16 * (visible - 1)
        return max(130, total / visible)
    }

    private var cards: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(trackers) { item in
                    SidewaysCard(
                        tracker: item,
                        today: today,
                        selected: item.uuid == tracker?.uuid,
                        onSelect: { onSelect(item) }
                    )
                    .frame(width: cardWidth)
                }

                Button(action: onNew) {
                    VStack(alignment: .leading, spacing: 0) {
                        Rectangle().fill(palette.line).frame(height: 1)
                        Caption(text: "New tracker")
                            .padding(.top, 18)
                        Spacer(minLength: 0)
                    }
                    .frame(width: cardWidth, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .scrollIndicators(.hidden)
    }
}

/// One tracker in the bottom half: tap the name to show it above, tap the circle to log.
struct SidewaysCard: View {
    let tracker: Tracker
    let today: Date
    let selected: Bool
    var onSelect: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.palette) private var palette

    var body: some View {
        let values = tracker.valuesByDay()
        let done = tracker.isDone(values[today])
        let summary = tracker.summary(values: values, today: today)

        VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(palette.line).frame(height: 1)

            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        if selected {
                            Circle().fill(palette.ink).frame(width: 6, height: 6)
                        }
                        Text(tracker.name)
                            .font(.system(size: 18, weight: selected ? .semibold : .medium))
                            .foregroundStyle(palette.ink)
                            .lineLimit(1)
                    }
                    Text(summary)
                        .font(.system(size: 13))
                        .foregroundStyle(palette.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .contentTransition(.numericText())
                        .animation(.dot, value: summary)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .padding(.top, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .animation(.snappy(duration: 0.25), value: selected)

            Spacer(minLength: 12)

            Button {
                Store.quickLog(tracker, in: context)
            } label: {
                QuickGlyph(kind: tracker.kind, done: done, size: 56, progress: tracker.progress(values[today]))
            }
            .buttonStyle(PressScale())
            .sensoryFeedback(.impact(weight: .medium), trigger: values[today])
            .accessibilityLabel(tracker.kind == .check ? "Mark \(tracker.name) done" : "Add to \(tracker.name)")
        }
    }
}
