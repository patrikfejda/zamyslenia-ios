import SwiftUI

/// Calendar picker over dates that exist in the manifest. The user can jump
/// to any past day; future days without content are visible but disabled.
struct HistoryCalendarView: View {
    let selectedDate: String
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(ContentStore.self) private var store

    @State private var selection: Date

    init(selectedDate: String, onSelect: @escaping (String) -> Void) {
        self.selectedDate = selectedDate
        self.onSelect = onSelect
        let parsed = DayResolver.parse(isoDate: selectedDate) ?? .now
        _selection = State(initialValue: parsed)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                DatePicker(
                    "Vyber dátum",
                    selection: $selection,
                    in: dateRange,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(theme.accent)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                HStack {
                    Text(availabilityLabel)
                        .font(Typography.caption())
                        .foregroundStyle(theme.textSecondary)
                    Spacer()
                    Button {
                        let iso = DayResolver.isoDate(selection)
                        onSelect(iso)
                    } label: {
                        Text("Otvoriť")
                            .font(Typography.button())
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(canOpen ? theme.accent : theme.accentMuted)
                            .foregroundStyle(theme.background)
                            .clipShape(Capsule())
                    }
                    .disabled(!canOpen)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .background(theme.background)
            .navigationTitle("Kalendár")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zrušiť") { dismiss() }
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
    }

    private var dateRange: ClosedRange<Date> {
        let dates = store.manifest?.entries.compactMap { DayResolver.parse(isoDate: $0.date) } ?? []
        let lower = dates.min() ?? Calendar.current.date(byAdding: .year, value: -1, to: .now)!
        let upper = (dates.max() ?? .now) > .now ? dates.max()! : Date.now
        return lower...upper
    }

    private var canOpen: Bool {
        store.hasDay(date: DayResolver.isoDate(selection))
    }

    private var availabilityLabel: String {
        canOpen
            ? "Texty pre tento deň sú stiahnuté."
            : "Pre tento dátum zatiaľ nie sú texty."
    }
}
