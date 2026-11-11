import SwiftUI
import SwiftData

/// Log or fix one day for one tracker: done / amount, plus a note.
struct LogSheet: View {
    let tracker: Tracker
    let day: Date
    var onEdit: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.palette) private var palette

    @State private var done = false
    @State private var amount = ""
    @State private var note = ""
    @FocusState private var amountFocused: Bool

    var body: some View {
        ZStack {
            palette.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(palette.muted)
                    Spacer()
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .foregroundStyle(palette.ink)
                }
                .font(.system(size: 15))
                .frame(height: 44)

                Text(tracker.name)
                    .font(.system(size: 56, weight: .bold))
                    .tracking(-2.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(palette.ink)
                    .padding(.top, 8)

                Text(day.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.system(size: 20))
                    .foregroundStyle(palette.muted)

                Group {
                    if tracker.kind == .check {
                        Button {
                            done.toggle()
                        } label: {
                            HStack(spacing: 14) {
                                QuickGlyph(kind: .check, done: done, size: 56)
                                Text(done ? "Done" : "Not done")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(palette.ink)
                                    .contentTransition(.opacity)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PressScale())
                        .sensoryFeedback(.impact(weight: .medium), trigger: done)
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            TextField("0", text: $amount)
                                .keyboardType(.decimalPad)
                                .focused($amountFocused)
                                .font(.system(size: 64, weight: .bold))
                                .foregroundStyle(palette.ink)
                                .fixedSize(horizontal: true, vertical: false)
                            Text("of \(formatAmount(tracker.goal)) \(tracker.unit)")
                                .font(.system(size: 20))
                                .foregroundStyle(palette.muted)
                            Spacer()
                        }
                    }
                }
                .padding(.top, 28)

                Caption(text: "Note")
                    .padding(.top, 28)
                TextField("Add a note", text: $note, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.system(size: 17))
                    .foregroundStyle(palette.ink)
                    .padding(.vertical, 12)
                Rectangle().fill(palette.line).frame(height: 1)

                Spacer(minLength: 16)

                HStack {
                    Button(action: clear) {
                        Caption(text: "Clear this day")
                            .frame(height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Button(action: onEdit) {
                        Caption(text: "Edit tracker")
                            .frame(height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear(perform: load)
    }

    private func load() {
        let entry = Store.entry(for: tracker, on: day)
        note = entry?.note ?? ""
        if tracker.kind == .check {
            done = (entry?.value ?? 0) >= 1
        } else {
            if let value = entry?.value { amount = plainAmount(value) }
            amountFocused = true
        }
    }

    private func save() {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        switch tracker.kind {
        case .check:
            if !done && trimmed.isEmpty {
                Store.setValue(nil, for: tracker, on: day, in: context)
            } else {
                Store.setValue(done ? 1 : 0, note: trimmed, for: tracker, on: day, in: context)
            }
        case .number:
            let value = parseAmount(amount)
            if value == nil && trimmed.isEmpty {
                Store.setValue(nil, for: tracker, on: day, in: context)
            } else {
                Store.setValue(value ?? 0, note: trimmed, for: tracker, on: day, in: context)
            }
        }
        dismiss()
    }

    private func clear() {
        Store.setValue(nil, for: tracker, on: day, in: context)
        dismiss()
    }
}
