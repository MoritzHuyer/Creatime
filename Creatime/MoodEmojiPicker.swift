import SwiftUI

// MARK: - Mood-Emoji-Reihe (v7 — Glass-Card)
//
// Glass-Card mit 5 Emojis, gewrappt in `.padding(.horizontal, -8)` damit
// die Reihe edge-to-edge schwebt (sonst hätte die Card einen Innenrand).
// Auswahl wird mit gefülltem Circle hinter dem Emoji markiert.

struct MoodEmojiPicker: View {
    @Environment(CreatineStore.self) private var store

    private static let moods: [(emoji: String, label: String, key: String)] = [
        ("😐", "Schlecht", "neutral"),
        ("😊", "OK",      "good"),
        ("🤩", "Gut",     "great"),
        ("🥵", "Stress",  "stressed"),
        ("😴", "Erledigt", "tired"),
    ]

    private var selectedMood: String? {
        store.moodByDay[DayKey.today]
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Label("Wie geht's dir heute?", systemImage: "face.smiling")
                    .font(.subheadline.bold())
                Spacer()
            }

            HStack(spacing: 6) {
                ForEach(Self.moods, id: \.key) { mood in
                    Button {
                        Haptics.tap()
                        store.setMoodToday(mood.key)
                    } label: {
                        VStack(spacing: 4) {
                            Text(mood.emoji)
                                .font(.system(size: 30))
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(selectedMood == mood.key ? Color.cyan.opacity(0.20) : Color.clear)
                                )
                            Text(mood.label)
                                .font(.caption2)
                                .foregroundStyle(selectedMood == mood.key ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .scaleEffect(selectedMood == mood.key ? 1.06 : 1.0)
                        .animation(.snappy, value: selectedMood)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(mood.label), Stimmung")
                    .accessibilityValue(selectedMood == mood.key ? "ausgewählt" : "")
                }
            }
        }
        .padding(14)
        // Edge-to-edge-bleed: der v7-Hack, damit die Emojis die volle
        // Card-Breite nutzen statt eingequetscht zu wirken.
        .padding(.horizontal, -8)
    }
}

#Preview {
    MoodEmojiPicker()
        .environment(CreatineStore())
        .padding()
}
