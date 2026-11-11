import SwiftUI

/// One day. Filled = done, ring = not done, orange = today, faint ring = coming up.
struct DotView: View {
    let state: DotState
    var size: CGFloat = 36

    @Environment(\.palette) private var palette

    private var isFilled: Bool { state == .done || state == .todayDone }
    private var isToday: Bool { state == .todayOpen || state == .todayDone }

    private var ringColor: Color {
        if isToday { return palette.accent }
        if state == .done { return palette.dot }
        return state == .future ? palette.future : palette.ring
    }

    private var ringWidth: CGFloat {
        let base = max(1.5, size * 0.045)
        return state == .todayOpen ? base * 1.5 : base
    }

    var body: some View {
        ZStack {
            Circle().strokeBorder(ringColor, lineWidth: ringWidth)
            Circle()
                .fill(isToday ? palette.accent : palette.dot)
                .scaleEffect(isFilled ? 1 : 0.001)
                .opacity(isFilled ? 1 : 0)
        }
        .frame(width: size, height: size)
        .opacity(state == .blank ? 0 : 1)
        .animation(.dot, value: state)
    }
}

/// The round tap target on a tracker row or widget: ring, plus, or filled check.
struct QuickGlyph: View {
    let kind: TrackerKind
    let done: Bool
    var size: CGFloat = 44
    var highlight: Bool = false

    @Environment(\.palette) private var palette

    private var symbol: String {
        if done { return "checkmark" }
        return kind == .number ? "plus" : ""
    }

    var body: some View {
        ZStack {
            Circle().strokeBorder(highlight && !done ? palette.accent : palette.ink, lineWidth: highlight && !done ? 3 : 2)
            Circle()
                .fill(palette.ink)
                .scaleEffect(done ? 1 : 0.001)
                .opacity(done ? 1 : 0)
            if !symbol.isEmpty {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundStyle(done ? palette.paper : palette.ink)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .animation(.dot, value: done)
    }
}
