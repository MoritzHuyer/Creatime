import SwiftUI

// MARK: - Supplement-Verwaltung (Sheet aus den Einstellungen)
//
// Eigener, aufgeräumter Bereich zum Zusammenstellen der „Heute\u{201C}-
// Supplement-Liste: oben die aktiven (entfernbar), darunter alle
// verfügbaren Vorlagen zum Hinzufügen. Ersetzt die frühere flache
// Toggle-Liste.
struct SupplementManagerSheet: View {
    @Environment(SupplementStore.self) private var supplements
    @Environment(\.dismiss) private var dismiss

    private var active: [SupplementStore.Supplement] {
        supplements.supplements.filter(\.enabled)
    }

    private var available: [SupplementStore.Supplement] {
        supplements.supplements.filter { !$0.enabled }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if active.isEmpty {
                        Text("Noch keine Supplements ausgewählt. Füge unten welche hinzu.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(active) { item in
                            Button {
                                withAnimation { supplements.setEnabled(item.id, false) }
                                Haptics.tap()
                            } label: {
                                HStack(spacing: 12) {
                                    Text(item.emoji).font(.title3).frame(width: 30)
                                    Text(item.name).foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                } header: {
                    Text("In deiner Heute-Liste")
                } footer: {
                    Text("Tippe auf ein Supplement, um es aus der Liste zu entfernen.")
                }

                if !available.isEmpty {
                    Section("Hinzufügen") {
                        ForEach(available) { item in
                            Button {
                                withAnimation { supplements.setEnabled(item.id, true) }
                                Haptics.tap()
                            } label: {
                                HStack(spacing: 12) {
                                    Text(item.emoji).font(.title3).frame(width: 30)
                                    Text(item.name).foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Supplements verwalten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SupplementManagerSheet()
        .environment(SupplementStore())
}
