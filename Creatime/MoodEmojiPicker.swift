import SwiftUI

// MARK: - Mood-Emoji-Reihe (Editorial-light)
//
// Bewusst OHNE .regularMaterial-Card-Rahmen — schwebt zwischen Hero-
// Streak und Wochenübersicht. Auswahl wird durch einen kleinen Punkt
// unter dem Emoji markiert (subtiler als vorher der große gefüllte
// Hintergrund-Circle).
//
// 5 Emojis reichen — decken neutral / gut / euphorisch / gestresst / müde
// ab. Auswahl wird mit `Haptics.tap()` quittiert (in TodayView wired).

struct MoodEmojiPicker: View {
    @Environment(CreatineStore.self) private var store

    /// Die 5 Optionen + Labels. Reihenfolge wichtig: links = neutral,
    /// rechts = euphorisch.
    private static let moods: [(emoji: String, label: String, key: String)] = [
        ("😐", "Neutral",  "neutral"),
        ("😊", "Gut",      "good"),
        ("🤩", "Top",      "great"),
        ("🥵", "Stress",   "stressed"),
        ("😴", "Müde",     "tired"),
    ]

    private var selectedMood: String? {
        store.moodByDay[DayKey.today]
    }

    var body: some View {
        VStack(spacing: 10) {
            // Mikro-Caption — kleiner, leichter als vorher. Akzent nur bei
            // aktiver Auswahl — sonst schweigsam im Hintergrund.
            Text(selectedMood == nil ? "STIMMUNG" : "STIMMUNG HEUTE")
                .font(.caption2.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(.tertiary)

            HStack(spacing: 12) {
                ForEach(Self.moods, id: \.key) { mood in
                    Button {
                        Haptics.tap()
                        store.setMoodToday(mood.key)
                    } label: {
                        VStack(spacing: 4) {
                            Text(mood.emoji)
                                .font(.system(size: 32))
                                .opacity(selectedMood == mood.key ? 1 : 0.45)
                            // kleiner Punkt als Selekt-Indikator statt
                                // großem gefülltem Circle — viel ruhiger.
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 4, height: 4)
                                .opacity(selectedMood == mood.key ? 1 : 0)
                        }
                        .frame(width: 44, height: 56)
                        .scaleEffect(selectedMood == mood.key ? 1.05 : 1.0)
                        .animation(.snappy, value: selectedMood)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(mood.label), Stimmung")
                    .accessibilityValue(selectedMood == mood.key ? "ausgewählt" : "")
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    MoodEmojiPicker()
        .environment(CreatineStore())
        .padding()
}
