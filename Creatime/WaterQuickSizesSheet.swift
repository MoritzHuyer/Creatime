import SwiftUI

// Sheet zum Anpassen der Schnell-Größen in der Wasser-Karte.
// Statt fest +250 ml kann der Nutzer mehrere Buttons z.B. 200/250/500
// definieren.
struct WaterQuickSizesSheet: View {

    @Environment(WaterStore.self) private var water
    @Environment(\.dismiss) private var dismiss

    /// Bearbeitete Liste. Beim "Speichern" wandert sie zurück in den Store.
    @State private var sizes: [Int] = []

    /// Das aktuell fokussierte Eingabefeld (für die "Fertig"-Taste).
    @FocusState private var focusedIndex: Int?

    var body: some View {
        VStack(spacing: 16) {
            Text("Schnell-Größen")
                .font(.headline)
                .padding(.top, 24)

            Text("Diese Mengen erscheinen als Buttons in der Wasser-Karte.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Liste mit den Mengen + -/+ Buttons zum Hinzufügen/Entfernen.
            VStack(spacing: 8) {
                ForEach(sizes.indices, id: \.self) { index in
                    HStack {
                        TextField(
                            "ml",
                            value: $sizes[index],
                            format: .number
                        )
                        .keyboardType(.numberPad)
                        .focused($focusedIndex, equals: index)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)

                        Text("ml")
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                            sizes.remove(at: index)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button {
                    sizes.append(250)
                    focusedIndex = sizes.count - 1
                } label: {
                    Label("Größe hinzufügen", systemImage: "plus.circle")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            Spacer(minLength: 0)

            Button("Speichern") {
                let cleaned = sizes
                    .filter { $0 > 0 }
                    .sorted()
                water.quickAmounts = cleaned.isEmpty ? WaterStore.defaultQuickAmounts : cleaned
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
        }
        .padding(.horizontal)
        .toolbar {
            // "Fertig"-Knopf über der Tastatur.
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fertig") { focusedIndex = nil }
            }
        }
        .onAppear {
            sizes = water.quickAmounts
        }
    }
}
