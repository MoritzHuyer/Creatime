import SwiftUI

// MARK: - Photo-Streak-Karussell (Hero-Bereich)
//
// Eine horizontale Page-Style-TabView für die bisherigen Foto-Streak-
// Einträge. Wird in HistoryView OBEN eingehängt (zwischen Stats-Grid
// und Insights-Section), wenn das Album ≥ 1 Eintrag hat.
//
// Das Karussell ist EINE zweite Variante zur vorhandenen `PhotoStreakSection`-
// Grid-Variante (die bleibt unten erhalten, weil sie als „vollständige
// Übersicht" weiterhin nützlich ist).

struct PhotoStreakCarousel: View {
    @Environment(PhotoStreakStore.self) private var store
    @State private var selectedIndex = 0

    private var entries: [PhotoStreakStore.Entry] {
        // Neueste zuerst; Carousel rendert sinnvoll ab ≥ 1 Eintrag.
        store.entries
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Label("Foto-Streak", systemImage: "camera.fill")
                    .font(.headline)
                Spacer()
                Text("\(entries.count) Foto\(entries.count == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            TabView(selection: $selectedIndex) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    CarouselPage(entry: entry)
                        .tag(index)
                        .padding(.bottom, 28)  // .page indexDisplayMode braucht Platz
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 220)
        }
        .padding()
        .liquidGlassCard()
    }
}

private struct CarouselPage: View {
    @Environment(PhotoStreakStore.self) private var store
    let entry: PhotoStreakStore.Entry

    var body: some View {
        let path = store.url(for: entry).path
        let ui = UIImage(contentsOfFile: path)

        ZStack(alignment: .bottomLeading) {
            Group {
                if let ui {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [.indigo.opacity(0.4), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: "photo")
                            .font(.system(size: 56))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            // Wasserzeichen-Datierung + Woche unten links
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.caption.bold())
                Text(
                    entry.capturedAt,
                    format: .dateTime.day().month(.wide).year()
                )
                .font(.caption.bold())
                Text("· Woche \(entry.week)")
                    .font(.caption2)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.black.opacity(0.45), in: Capsule())
            .padding(12)
        }
        .accessibilityLabel("Foto aus Woche \(entry.week) aufgenommen am \(entry.capturedAt.formatted(date: .abbreviated, time: .omitted))")
    }
}

#Preview {
    PhotoStreakCarousel()
        .environment(PhotoStreakStore())
        .padding()
}
