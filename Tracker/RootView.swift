import SwiftUI
import SwiftData

enum Span: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }
}

enum ActiveSheet: Identifiable {
    case new
    case edit(Tracker)
    case log(Tracker, Date)

    var id: String {
        switch self {
        case .new:
            return "new"
        case .edit(let tracker):
            return "edit-\(tracker.uuid.uuidString)"
        case .log(let tracker, let day):
            return "log-\(tracker.uuid.uuidString)-\(day.timeIntervalSince1970)"
        }
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \Tracker.sortOrder) private var trackers: [Tracker]

    @State private var span: Span = .day
    @State private var selectedID: UUID?
    @State private var sheet: ActiveSheet?
    @State private var today = Calendar.current.startOfDay(for: Date())
    @State private var refreshToken = 0

    private var palette: Palette { .of(scheme) }

    private var selected: Tracker? {
        trackers.first { $0.uuid == selectedID } ?? trackers.first
    }

    var body: some View {
        ZStack {
            palette.paper.ignoresSafeArea()

            GeometryReader { geo in
                // Wide and tall enough = iPhone Duo open (or a tablet). Anything else is a normal phone.
                if geo.size.width >= 580 && geo.size.height >= 480 {
                    if geo.size.width > geo.size.height {
                        sideways(geo.size)
                    } else {
                        wide
                    }
                } else {
                    compact
                }
            }
        }
        .environment(\.palette, palette)
        .sheet(item: $sheet) { item in
            sheetContent(item)
                .environment(\.palette, palette)
        }
        .onAppear {
            Store.seedIfNeeded(in: context)
            today = Calendar.current.startOfDay(for: Date())
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                // Pick up a new day and anything logged from a widget.
                today = Calendar.current.startOfDay(for: Date())
                refreshToken += 1
            }
        }
    }

    /// Phone, or iPhone Duo closed: one screen at a time.
    private var compact: some View {
        VStack(alignment: .leading, spacing: 0) {
            SpanTabs(span: $span)
                .padding(.horizontal, 24)

            TabView(selection: $span) {
                DayView(
                    trackers: trackers,
                    today: today,
                    onOpen: { sheet = .log($0, today) },
                    onNew: { sheet = .new }
                )
                .tag(Span.day)

                WeekView(
                    trackers: trackers,
                    today: today,
                    onOpen: { tracker, day in sheet = .log(tracker, day) }
                )
                .tag(Span.week)

                MonthView(
                    trackers: trackers,
                    tracker: selected,
                    today: today,
                    onSelect: { selectedID = $0.uuid },
                    onOpen: { tracker, day in sheet = .log(tracker, day) }
                )
                .tag(Span.month)

                YearView(
                    trackers: trackers,
                    tracker: selected,
                    today: today,
                    onSelect: { selectedID = $0.uuid }
                )
                .tag(Span.year)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .id(refreshToken)
        }
    }

    /// iPhone Duo open (or any wide screen): log on the left, review on the right.
    private var wide: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Today")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(palette.ink)
                    .frame(height: 44)
                    .padding(.horizontal, 24)

                DayView(
                    trackers: trackers,
                    today: today,
                    selectedID: selected?.uuid,
                    showsSelection: true,
                    onOpen: { tracker in
                        withAnimation(.snappy(duration: 0.25)) { selectedID = tracker.uuid }
                    },
                    onNew: { sheet = .new }
                )
            }
            .frame(maxWidth: .infinity)

            ReviewPane(
                tracker: selected,
                today: today,
                onOpen: { tracker, day in sheet = .log(tracker, day) }
            )
            .frame(maxWidth: .infinity)
        }
        .id(refreshToken)
    }

    /// iPhone Duo open and turned sideways: overview above the fold, tracker cards below.
    private func sideways(_ size: CGSize) -> some View {
        SidewaysView(
            trackers: trackers,
            tracker: selected,
            today: today,
            size: size,
            onSelect: { tracker in
                withAnimation(.snappy(duration: 0.25)) { selectedID = tracker.uuid }
            },
            onOpen: { tracker, day in sheet = .log(tracker, day) },
            onNew: { sheet = .new }
        )
        .id(refreshToken)
    }

    @ViewBuilder
    private func sheetContent(_ item: ActiveSheet) -> some View {
        switch item {
        case .new:
            EditTrackerView(tracker: nil, nextOrder: (trackers.map(\.sortOrder).max() ?? -1) + 1)
        case .edit(let tracker):
            EditTrackerView(tracker: tracker, nextOrder: tracker.sortOrder)
        case .log(let tracker, let day):
            LogSheet(tracker: tracker, day: day, onEdit: { sheet = .edit(tracker) })
        }
    }
}

/// Day · Week · Month · Year. Tap or swipe sideways.
struct SpanTabs: View {
    @Binding var span: Span

    @Environment(\.palette) private var palette
    @Namespace private var marker

    var body: some View {
        HStack(spacing: 22) {
            ForEach(Span.allCases) { item in
                Button {
                    withAnimation(.snappy(duration: 0.3)) { span = item }
                } label: {
                    VStack(spacing: 5) {
                        Text(item.rawValue)
                            .font(.system(size: 15, weight: item == span ? .semibold : .regular))
                            .foregroundStyle(item == span ? palette.ink : palette.muted)
                        ZStack {
                            Circle().fill(Color.clear).frame(width: 5, height: 5)
                            if item == span {
                                Circle()
                                    .fill(palette.ink)
                                    .frame(width: 5, height: 5)
                                    .matchedGeometryEffect(id: "marker", in: marker)
                            }
                        }
                    }
                    .frame(height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .animation(.snappy(duration: 0.3), value: span)
        .sensoryFeedback(.selection, trigger: span)
    }
}

/// The giant number with two lines under it, used at the top of every screen.
struct Hero<Trailing: View>: View {
    let big: String
    let title: String
    let subtitle: String
    var size: CGFloat = 150
    @ViewBuilder var trailing: () -> Trailing

    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(big)
                .font(.system(size: size, weight: .bold))
                .tracking(-size * 0.05)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .foregroundStyle(palette.ink)
                .contentTransition(.numericText())
                .animation(.dot, value: big)
                .padding(.leading, -4)
                .padding(.vertical, -size * 0.08)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(.system(size: 22))
                        .foregroundStyle(palette.ink)
                    Text(subtitle)
                        .font(.system(size: 22))
                        .foregroundStyle(palette.muted)
                }
                Spacer(minLength: 12)
                trailing()
            }
            .padding(.top, 10)
        }
    }
}

/// Small uppercase label.
struct Caption: View {
    let text: String

    @Environment(\.palette) private var palette

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12))
            .tracking(1.6)
            .foregroundStyle(palette.muted)
    }
}

/// Lets you switch which tracker Month and Year show.
struct TrackerMenu: View {
    let trackers: [Tracker]
    let tracker: Tracker
    var onSelect: (Tracker) -> Void

    @Environment(\.palette) private var palette

    var body: some View {
        Menu {
            ForEach(trackers) { item in
                Button(item.name) { onSelect(item) }
            }
        } label: {
            HStack(spacing: 6) {
                Text(tracker.name)
                    .font(.system(size: 22))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(palette.ink)
            .frame(minHeight: 44, alignment: .bottom)
        }
    }
}

struct EmptyHint: View {
    @Environment(\.palette) private var palette

    var body: some View {
        VStack {
            Spacer()
            Caption(text: "Add a tracker on the Day screen")
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
