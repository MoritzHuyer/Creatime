import SwiftUI

// MARK: - BuddyView
//
// Zeigt den Buddy-Status im HistoryView (oder in einer Sheet). Inhalt:
//  • Mein Invite-Code mit Copy-Button
//  • Aktuell verbundener Buddy + seine manuell eingetragene Streak
//  • Eingabefeld für manuelle Update (Streak-Nummer + Notiz)
//  • Share-Button (iMessage / AirDrop via UIActivityViewController)
//  • „Buddy entfernen"-Button wenn verbunden

struct BuddyView: View {
    @Environment(CreatineStore.self) private var store
    @Environment(BuddySystem.self) private var buddy

    @State private var showStreakEditor = false
    @State private var showShareSheet = false
    @State private var showBuddyClearConfirm = false

    /// Vergleichs-Wert: meine Streak — Buddys Streak. Positiv = ich führe.
    private var lead: Int {
        store.currentStreak - buddy.buddyStreak
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // MARK: Titel + Invite-Code
            HStack(alignment: .firstTextBaseline) {
                Label("Streak-Battle", systemImage: "person.2.fill")
                    .font(.headline)
                Spacer()
                if buddy.buddyName.isEmpty {
                    Text("Kein Buddy")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(.secondary)
                        .background(.regularMaterial, in: Capsule())
                } else {
                    Text("Mit \(buddy.buddyName) verbunden")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(.green)
                        .background(.green.opacity(0.15), in: Capsule())
                }
            }

            // MARK: Mein Code + Copy
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mein Invite-Code")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(buddy.myInviteCode)
                        .font(.system(.title3, design: .monospaced).weight(.bold))
                        .foregroundStyle(Color.accentColor)
                        .tracking(2)
                }
                Spacer()
                Button {
                    UIPasteboard.general.string = buddy.myInviteCode
                    Haptics.success()
                } label: {
                    Label("Code kopieren", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

            // MARK: Battle-Status oder Empty-State
            if buddy.buddyName.isEmpty {
                emptyBuddyState
            } else {
                connectedBuddyCard
            }

            Button {
                showShareSheet = true
            } label: {
                Label("Invite mit Freunden teilen", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .airySection()
        .sheet(isPresented: $showStreakEditor) {
            BuddyStreakEditorSheet()
                .presentationDetents([.height(280)])
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityShareSheet(items: [buddy.shareText])
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog(
            "Buddy entfernen?",
            isPresented: $showBuddyClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Entfernen", role: .destructive) {
                buddy.clearBuddy()
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Du trennst die Verbindung zu \(buddy.buddyName). Sein Code bleibt für eine Neu-Verbindung erhalten.")
        }
    }

    // MARK: - Sub-Views

    @ViewBuilder
    private var emptyBuddyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Lade einen Freund ein")
                .font(.subheadline.bold())
            Text("Schick deinen Invite-Code per AirDrop, iMessage oder WhatsApp. Dein Freund tippt ihn in seiner Creatime-App ein — und schon seht ihr euch gegenseitig auf der Rangliste.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.tertiary)
                Text("Erinnerung: Streak deines Buddys musst du aktuell noch manuell pflegen — Phase 2 bringt Auto-Sync.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var connectedBuddyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(buddy.buddyName)
                    .font(.title3.weight(.semibold))
                Spacer()
                Text("vs.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 0) {
                buddyScoreColumn(
                    label: "Du",
                    value: store.currentStreak,
                    tint: .accentColor
                )
                Spacer(minLength: 8)
                Image(systemName: lead >= 0 ? "arrow.right" : "arrow.left")
                    .foregroundStyle(.tertiary)
                Spacer(minLength: 8)
                buddyScoreColumn(
                    label: buddy.buddyName,
                    value: buddy.buddyStreak,
                    tint: .secondary
                )
            }

            // Wer führt?
            HStack {
                Spacer()
                if lead > 0 {
                    Label("Du führst mit +\(lead)", systemImage: "crown.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                } else if lead < 0 {
                    Label("\(buddy.buddyName) führt mit \(-lead)", systemImage: "crown.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Label("Gleichstand", systemImage: "equal")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 8) {
                Button {
                    showStreakEditor = true
                } label: {
                    Label("Update-Streak", systemImage: "pencil.circle")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                Button(role: .destructive) {
                    showBuddyClearConfirm = true
                } label: {
                    Label("Trennen", systemImage: "xmark.circle")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 6)
        }
    }

    private func buddyScoreColumn(label: String, value: Int, tint: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(.title, design: .rounded).bold())
                .foregroundStyle(tint)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Streak-Editor-Sheet
//
// Schnelle manuelle Eingabe der Buddy-Streak. Kein Schnickschnack:
// TextField mit Stepper, Speichern-Button.

struct BuddyStreakEditorSheet: View {
    @Environment(BuddySystem.self) private var buddy
    @Environment(ThemeManager.self) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var streak = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Buddys Streak aktualisieren")
                .font(.headline)
                .padding(.top, 24)

            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.caption.bold())
                TextField("z. B. Lisa", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Aktuelle Streak (Tage)")
                    .font(.caption.bold())
                Stepper(value: $streak, in: 0...365) {
                    Text("\(streak)")
                        .font(.system(.title2, design: .rounded).bold())
                        .foregroundStyle(theme.tint)
                }
            }

            Button("Speichern") {
                let trimmedName = name.trimmingCharacters(in: .whitespaces)
                let finalName = trimmedName.isEmpty ? "Buddy" : trimmedName
                buddy.updateBuddy(name: finalName, streak: streak)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding(24)
        .onAppear {
            name = buddy.buddyName
            streak = buddy.buddyStreak
        }
    }
}

// MARK: - ActivityShareSheet ist global definiert in ShareStreakCard.swift.
// Hier NICHT erneut anlegen — das verursacht „invalid redeclaration“-Errors.
