import SwiftUI

// Sheet zum Einstellen des "Urlaubsmodus": solange aktiv, ist die
// "1 Pause pro Woche"-Grenze aufgehoben, damit im Urlaub nicht jede
// einzelne Skip-Aktion manuell freigeschaltet werden muss.
struct VacationModeSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(CreatineStore.self) private var store

    /// Lokaler State, der erst beim "Speichern" in den Store wandert.
    @State private var endDate: Date = Calendar.current.date(
        byAdding: .day, value: 7, to: Date()
    ) ?? Date()

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "beach.umbrella.fill")
                .font(.system(size: 44))
                .foregroundStyle(.tint)

            Text("Urlaubsmodus")
                .font(.title2.bold())

            Text("Während des Urlaubs kannst du beliebig oft pausieren, ohne die 1-mal-pro-Woche-Grenze.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            DatePicker(
                "Bis",
                selection: $endDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()

            HStack(spacing: 12) {
                Button("Abbrechen") { dismiss() }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                Button("Aktivieren") {
                    store.startVacation(until: endDate)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .onAppear {
            if let existing = store.vacationUntil, existing > Date() {
                endDate = existing
            }
        }
    }
}
