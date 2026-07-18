import PhotosUI
import SwiftUI

// MARK: - PHPicker-Wrapper
//
// PHPicker ist toll: keine NSPhotoLibraryUsageDescription nötig —
// Apple hat das in iOS 14 so gebaut, dass der User pro Foto-Aktion
// seine Auswahl trifft, statt Vollzugriff auf die Foto-Library.
//
// ACHTUNG: PHPicker ist nur eine VIEW des Library-Caches. Die
// eigentlichen Bilder kommen aus dem iCloud-Backup auf Wunsch,
// mit .preferredAssetRepresentationMode = .current überspringen wir
// das (sonst kann das erste Bild nach App-Start 5-10s dauern).

struct PhotoStreakPicker: UIViewControllerRepresentable {
    let onPicked: (UIImage?) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        let vc = PHPickerViewController(configuration: config)
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoStreakPicker

        init(_ parent: PhotoStreakPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController,
                    didFinishPicking results: [PHPickerResult]) {
            // Picker ohne Auswahl → einfach still schließen.
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self)
            else {
                parent.dismiss()
                parent.onPicked(nil)
                return
            }

            // loadObject-Callback feuert auf einem Background-Thread.
            // Wir hüpfen explizit auf den MainActor, um die UI zu dismissen.
            provider.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
                guard let self else { return }
                let image = obj as? UIImage
                Task { @MainActor in
                    self.parent.onPicked(image)
                    self.parent.dismiss()
                }
            }
        }
    }
}

// MARK: - Section in HistoryView
//
// 3-Spalten-Galerie der Foto-Streak-Archive. Empty-State erklärt,
// wozu das Feature gut ist. Der "+ Foto"-Button öffnet PHPicker.

struct PhotoStreakSection: View {
    @Environment(PhotoStreakStore.self) private var store
    @State private var showPicker = false

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 3
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Foto-Streak", systemImage: "camera.fill")
                    .font(.headline)
                Spacer()
                Button {
                    showPicker = true
                } label: {
                    Label("Foto", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel("Foto hinzufügen")
            }

            if store.entries.isEmpty {
                emptyState
            } else {
                gallery
            }
        }
        .padding()
        .airySection()
        .sheet(isPresented: $showPicker) {
            PhotoStreakPicker { image in
                if let image {
                    _ = store.add(image: image)
                }
            }
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("Noch keine Fotos")
                .font(.subheadline.weight(.semibold))
            Text("Mach wöchentlich ein Foto von deinem Kreatin-Shake oder deinem Training — so dokumentierst du deinen Fortschritt und baust eine visuelle Streak auf.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private var gallery: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(store.entries) { entry in
                    PhotoThumb(entry: entry)
                }
            }
            // Hinweis: aktuelle Woche hat schon ein Foto → Hinweis anzeigen.
            if store.alreadyCapturedThisWeek {
                Label("Diese Woche: ✓ eingetragen", systemImage: "checkmark.seal.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
            } else {
                Text("Kein Foto diese Woche — der Reminder kommt Samstagmorgen.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Einzel-Thumbnail
//
// Lädt das Bild direkt aus dem Dateipfad. `UIImage(contentsOfFile:)` ist
// synchron und lädt HEIC + JPEG. Bei vielen Fotos (>50) sollte das
// später async werden — für jetzt OK, weil die Galerie klein bleibt.

private struct PhotoThumb: View {
    @Environment(PhotoStreakStore.self) private var store
    let entry: PhotoStreakStore.Entry

    var body: some View {
        let path = store.url(for: entry).path
        let ui = UIImage(contentsOfFile: path)

        ZStack(alignment: .topTrailing) {
            Group {
                if let ui {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(.systemGray5)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        )
                }
            }
            // Feste 100pt-Breite verursachte horizontalen Overflow in der
            // 3-Spalten-Grid auf schmalen iPhones — maxWidth:.infinity +
            // aspectRatio lässt die Kachel in ihren Slot schrumpfen.
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.white.opacity(0.35), lineWidth: 0.5)
            }

            // Datums-Badge oben rechts
            Text(
                entry.capturedAt,
                format: .dateTime.day().month(.abbreviated)
            )
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.black.opacity(0.55), in: Capsule())
            .padding(4)
        }
        .accessibilityLabel("Foto aus Woche \(entry.week)")
        .accessibilityHint("Long-Press zum Löschen.")
        .contextMenu {
            Button("Löschen", systemImage: "trash", role: .destructive) {
                store.delete(entry)
            }
        }
    }
}
