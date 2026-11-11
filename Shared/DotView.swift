import SwiftUI

/// One day. Filled = done, ring = not done, orange = today, faint ring = coming up.
/// A number tracker part way to its goal draws a partial ring over a faint one.
struct DotView: View {
    let state: DotState
    var size: CGFloat = 36
    /// 0...1 toward the goal. Only shown while the day is not done.
    var progress: Double = 0

    @Environment(\.palette) private var palette

    private var isFilled: Bool { state == .done || state == .todayDone }
    private var isToday: Bool { state == .todayOpen || state == .todayDone }
    private var showsProgress: Bool { !isFilled && progress > 0 && state != .future && state != .blank }

    private var ringColor: Color {
        if showsProgress { return palette.future }
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
            ProgressArc(progress: showsProgress ? progress : 0, lineWidth: ringWidth)
                .foregroundStyle(isToday ? palette.accent : palette.dot)
            Circle()
                .fill(isToday ? palette.accent : palette.dot)
                .scaleEffect(isFilled ? 1 : 0.001)
                .opacity(isFilled ? 1 : 0)
        }
        .frame(width: size, height: size)
        .opacity(state == .blank ? 0 : 1)
        .animation(.dot, value: state)
        .animation(.dot, value: progress)
    }
}

/// A ring drawn clockwise from 12 o'clock, inset so it sits exactly on top of a `strokeBorder` ring.
struct ProgressArc: View {
    let progress: Double
    let lineWidth: CGFloat

    var body: some View {
        Circle()
            .inset(by: lineWidth / 2)
            .trim(from: 0, to: progress)
            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .opacity(progress > 0 ? 1 : 0)
    }
}

/// The round tap target on a tracker row or widget: ring, plus, or filled check.
struct QuickGlyph: View {
    let kind: TrackerKind
    let done: Bool
    var size: CGFloat = 44
    var highlight: Bool = false
    /// 0...1 toward the goal, drawn as a partial ring while not done.
    var progress: Double = 0

    @Environment(\.palette) private var palette

    private var symbol: String {
        if done { return "checkmark" }
        return kind == .number ? "plus" : ""
    }

    private var showsProgress: Bool { !done && progress > 0 }
    private var ringColor: Color { highlight && !done ? palette.accent : palette.ink }
    private var ringWidth: CGFloat { highlight && !done ? 3 : 2 }

    var body: some View {
        ZStack {
            Circle().strokeBorder(showsProgress ? palette.faint : ringColor, lineWidth: ringWidth)
            // Slightly thicker than the base ring so progress reads at a glance.
            ProgressArc(progress: showsProgress ? progress : 0, lineWidth: ringWidth + 1)
                .foregroundStyle(ringColor)
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
        .animation(.dot, value: progress)
    }
}
