import SwiftUI
import SwiftData

/// Create a tracker, or change / delete an existing one.
struct EditTrackerView: View {
    let tracker: Tracker?
    let nextOrder: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.palette) private var palette

    @State private var name = ""
    @State private var category = "Fitness"
    @State private var kind: TrackerKind = .check
    @State private var period: GoalPeriod = .week
    @State private var times = 3
    @State private var goalAmount = ""
    @State private var unit = ""
    @State private var stepAmount = ""
    @State private var isLimit = false
    @State private var showOnWidget = true
    @State private var confirmDelete = false
    @State private var loaded = false

    private let categories = ["Fitness", "Health", "Food", "Money"]

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            palette.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(palette.muted)
                    Spacer()
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .foregroundStyle(canSave ? palette.ink : palette.faint)
                        .disabled(!canSave)
                }
                .font(.system(size: 15))
                .frame(height: 44)
                .padding(.horizontal, 24)
                .padding(.top, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Caption(text: "Name")
                        TextField("Name", text: $name)
                            .font(.system(size: 64, weight: .bold))
                            .tracking(-3)
                            .foregroundStyle(palette.ink)
                            .minimumScaleFactor(0.5)
                            .padding(.bottom, 4)
                        Rectangle().fill(palette.ink).frame(height: 1)

                        Caption(text: "Category").padding(.top, 28)
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { item in
                                Pill(text: item, selected: category == item) { category = item }
                            }
                        }
                        .padding(.top, 10)

                        Caption(text: "What you log").padding(.top, 28)
                        HStack(spacing: 8) {
                            Pill(text: "Done / not done", selected: kind == .check, wide: true) { kind = .check }
                            Pill(text: "A number", selected: kind == .number, wide: true) { kind = .number }
                        }
                        .padding(.top, 10)

                        Caption(text: "Goal").padding(.top, 28)
                        Group {
                            if kind == .check {
                                checkGoal
                            } else {
                                numberGoal
                            }
                        }
                        .transition(.opacity)

                        Rectangle().fill(palette.line).frame(height: 1).padding(.top, 24)
                        Toggle("Show on widget", isOn: $showOnWidget)
                            .font(.system(size: 16))
                            .foregroundStyle(palette.ink)
                            .tint(palette.ink)
                            .frame(height: 56)
                        Rectangle().fill(palette.line).frame(height: 1)

                        if tracker != nil {
                            Button {
                                confirmDelete = true
                            } label: {
                                Caption(text: "Delete this tracker")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 20)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    .animation(.snappy(duration: 0.25), value: kind)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .onAppear(perform: load)
        .confirmationDialog("Delete this tracker and all its history?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { delete() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var checkGoal: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                roundButton("minus", label: "One less") { if times > 1 { times -= 1 } }
                Text("\(times)")
                    .font(.system(size: 64, weight: .bold))
                    .tracking(-3)
                    .foregroundStyle(palette.ink)
                    .contentTransition(.numericText())
                    .animation(.dot, value: times)
                    .frame(minWidth: 44)
                roundButton("plus", label: "One more") { if times < 31 { times += 1 } }
                Text(times == 1 ? "time" : "times")
                    .font(.system(size: 20))
                    .foregroundStyle(palette.muted)
            }
            .sensoryFeedback(.selection, trigger: times)

            HStack(spacing: 8) {
                ForEach(GoalPeriod.allCases) { item in
                    Pill(text: item.label, selected: period == item) { period = item }
                }
            }
        }
        .padding(.top, 6)
    }

    private var numberGoal: some View {
        VStack(alignment: .leading, spacing: 0) {
            field("Amount a day", text: $goalAmount, placeholder: "2000", numeric: true)
            field("Unit", text: $unit, placeholder: "kcal, L, steps, $", numeric: false)
            field("One tap adds", text: $stepAmount, placeholder: "100", numeric: true)
            Toggle("Stay under this amount", isOn: $isLimit)
                .font(.system(size: 16))
                .foregroundStyle(palette.ink)
                .tint(palette.ink)
                .frame(height: 52)
        }
        .padding(.top, 6)
    }

    private func field(_ title: String, text: Binding<String>, placeholder: String, numeric: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundStyle(palette.ink)
                Spacer()
                TextField(placeholder, text: text)
                    .keyboardType(numeric ? .decimalPad : .default)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(palette.ink)
                    .frame(maxWidth: 160)
            }
            .frame(height: 52)
            Rectangle().fill(palette.line).frame(height: 1)
        }
    }

    private func roundButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(palette.ink)
                .frame(width: 44, height: 44)
                .overlay(Circle().strokeBorder(palette.ink, lineWidth: 1.5))
                .contentShape(Circle())
        }
        .buttonStyle(PressScale())
        .accessibilityLabel(label)
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        guard let tracker else { return }
        name = tracker.name
        category = tracker.category
        kind = tracker.kind
        period = tracker.period
        showOnWidget = tracker.showOnWidget
        isLimit = tracker.isLimit
        unit = tracker.unit
        if tracker.kind == .check {
            times = max(1, Int(tracker.goal))
        } else {
            goalAmount = plainAmount(tracker.goal)
            stepAmount = plainAmount(tracker.step)
        }
    }

    private func save() {
        let target = tracker ?? Tracker(name: "", sortOrder: nextOrder)
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.category = category
        target.kind = kind
        target.showOnWidget = showOnWidget

        switch kind {
        case .check:
            target.period = period
            target.goal = Double(times)
            target.isLimit = false
        case .number:
            target.period = .day
            target.goal = parseAmount(goalAmount) ?? 1
            target.unit = unit.trimmingCharacters(in: .whitespaces)
            target.step = max(parseAmount(stepAmount) ?? 1, 0.01)
            target.isLimit = isLimit
        }

        if tracker == nil { context.insert(target) }
        Store.save(context)
        dismiss()
    }

    private func delete() {
        if let tracker { context.delete(tracker) }
        Store.save(context)
        dismiss()
    }
}

/// Rounded choice button: black when selected.
struct Pill: View {
    let text: String
    let selected: Bool
    var wide: Bool = false
    var action: () -> Void

    @Environment(\.palette) private var palette

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(selected ? palette.paper : palette.ink)
                .padding(.horizontal, 16)
                .frame(maxWidth: wide ? .infinity : nil)
                .frame(height: 44)
                .background(Capsule().fill(selected ? palette.ink : Color.clear))
                .overlay(Capsule().strokeBorder(selected ? palette.ink : palette.faint, lineWidth: 1.5))
                .contentShape(Capsule())
        }
        .buttonStyle(PressScale())
        .animation(.snappy(duration: 0.2), value: selected)
        .sensoryFeedback(.selection, trigger: selected)
    }
}
