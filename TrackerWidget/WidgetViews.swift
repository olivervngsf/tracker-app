import SwiftUI
import WidgetKit
import AppIntents

struct TrackerWidgetView: View {
    let entry: TrackerEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let snapshot = entry.snapshot {
            switch family {
            case .systemLarge:
                LargeYearView(snapshot: snapshot)
            case .accessoryCircular:
                CircularView(snapshot: snapshot)
            case .accessoryRectangular:
                RectangularView(snapshot: snapshot)
            default:
                SmallView(snapshot: snapshot)
            }
        } else {
            OpenAppHint()
        }
    }
}

/// Small: big number, tap circle, this week's dots.
struct SmallView: View {
    let snapshot: TrackerSnapshot

    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text(snapshot.headline)
                    .font(.system(size: 46, weight: .bold))
                    .tracking(-2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .foregroundStyle(palette.ink)
                    .contentTransition(.numericText())
                Spacer(minLength: 6)
                Button(intent: LogIntent(trackerID: snapshot.id)) {
                    QuickGlyph(kind: snapshot.kind, done: snapshot.doneToday, size: 40, highlight: true, progress: snapshot.progressToday)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
            DotRow(states: snapshot.week, progress: snapshot.weekProgress, size: 14)
            Spacer(minLength: 0)
            Text(snapshot.caption)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(palette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

/// Large: the whole year, one dot per day.
struct LargeYearView: View {
    let snapshot: TrackerSnapshot

    @Environment(\.palette) private var palette

    private let perRow = 21

    private var rows: [[DotState]] {
        stride(from: 0, to: snapshot.year.count, by: perRow).map { start in
            Array(snapshot.year[start..<min(start + perRow, snapshot.year.count)])
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 5) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 0) {
                        ForEach(0..<perRow, id: \.self) { index in
                            DotView(state: index < row.count ? row[index] : .blank, size: 10)
                            if index < perRow - 1 { Spacer(minLength: 0) }
                        }
                    }
                }
            }
            Spacer(minLength: 8)
            HStack {
                Text("\(snapshot.name.lowercased()) \(Date().formatted(.dateTime.year()))")
                Spacer()
                Text("\(snapshot.yearDone) days done")
            }
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(palette.muted)
            .lineLimit(1)
        }
        .padding(6)
    }
}

/// Medium: up to three trackers, each with its own tap circle.
struct TodayWidgetView: View {
    let entry: TodayEntry

    @Environment(\.palette) private var palette

    var body: some View {
        if entry.snapshots.isEmpty {
            OpenAppHint()
        } else {
            VStack(spacing: 2) {
                ForEach(entry.snapshots.prefix(3)) { snapshot in
                    HStack(spacing: 12) {
                        Text(snapshot.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(palette.ink)
                            .lineLimit(1)
                        Spacer(minLength: 6)
                        Text(snapshot.rowText)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(palette.muted)
                            .lineLimit(1)
                            .contentTransition(.numericText())
                        Button(intent: LogIntent(trackerID: snapshot.id)) {
                            QuickGlyph(kind: snapshot.kind, done: snapshot.doneToday, size: 40, highlight: true, progress: snapshot.progressToday)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
    }
}

/// Lock screen, wide: name, count and this week's dots.
struct RectangularView: View {
    let snapshot: TrackerSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(snapshot.name).font(.system(size: 15, weight: .semibold)).lineLimit(1)
                Spacer()
                Text(snapshot.headline).font(.system(size: 15, weight: .semibold))
            }
            DotRow(states: snapshot.week, progress: snapshot.weekProgress, size: 15)
        }
    }
}

/// Lock screen, round: the count inside a ring.
struct CircularView: View {
    let snapshot: TrackerSnapshot

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text(snapshot.headline)
                    .font(.system(size: 17, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(snapshot.name)
                    .font(.system(size: 9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(6)
        }
    }
}

struct DotRow: View {
    let states: [DotState]
    /// Optional 0...1 per day, matched to `states` by position.
    var progress: [Double] = []
    let size: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(states.enumerated()), id: \.offset) { index, state in
                DotView(state: state, size: size, progress: index < progress.count ? progress[index] : 0)
                if index < states.count - 1 { Spacer(minLength: 0) }
            }
        }
    }
}

struct OpenAppHint: View {
    @Environment(\.palette) private var palette

    var body: some View {
        Text("Open Tracker to add a tracker")
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(palette.muted)
            .multilineTextAlignment(.center)
    }
}
