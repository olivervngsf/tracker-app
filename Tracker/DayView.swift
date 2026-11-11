import SwiftUI
import SwiftData

/// Today: the date, then one row per tracker with a one-tap button.
struct DayView: View {
    let trackers: [Tracker]
    let today: Date
    var onOpen: (Tracker) -> Void
    var onNew: () -> Void

    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Hero(
                big: "\(Calendar.current.component(.day, from: today))",
                title: today.formatted(.dateTime.month(.wide)),
                subtitle: today.formatted(.dateTime.year())
            ) {
                Text(today.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.system(size: 22))
                    .foregroundStyle(palette.ink)
            }
            .padding(.top, 12)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(trackers) { tracker in
                        TrackerRow(tracker: tracker, today: today, onOpen: { onOpen(tracker) })
                    }
                    Rectangle().fill(palette.line).frame(height: 1)
                }
            }
            .scrollIndicators(.hidden)
            .padding(.top, 24)

            Button(action: onNew) {
                Caption(text: "New tracker")
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }
}

struct TrackerRow: View {
    let tracker: Tracker
    let today: Date
    var onOpen: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.palette) private var palette

    var body: some View {
        let values = tracker.valuesByDay()
        let done = tracker.isDone(values[today])
        let summary = tracker.summary(values: values, today: today)

        VStack(spacing: 0) {
            Rectangle().fill(palette.line).frame(height: 1)

            HStack(spacing: 12) {
                Button(action: onOpen) {
                    HStack(spacing: 12) {
                        Text(tracker.name)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(palette.ink)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(summary)
                            .font(.system(size: 14))
                            .foregroundStyle(palette.muted)
                            .lineLimit(1)
                            .contentTransition(.numericText())
                            .animation(.dot, value: summary)
                    }
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    Store.quickLog(tracker, in: context)
                } label: {
                    QuickGlyph(kind: tracker.kind, done: done)
                }
                .buttonStyle(PressScale())
                .sensoryFeedback(.impact(weight: .medium), trigger: values[today])
                .accessibilityLabel(tracker.kind == .check ? "Mark \(tracker.name) done" : "Add to \(tracker.name)")
            }
            .frame(height: 60)
        }
    }
}

/// Buttons shrink slightly while pressed.
struct PressScale: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.86 : 1)
            .animation(.dot, value: configuration.isPressed)
    }
}
