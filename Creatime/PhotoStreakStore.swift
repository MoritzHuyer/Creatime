import Foundation
import Observation
import UIKit

// MARK: - Photo-Streak-Store
//
// Verwaltet das Foto-Archiv: einmal pro Woche macht der User ein
// Foto von seinem Shake oder Trainings-Tag, abgelegt im
// Documents/photoStreak/<UUID>.jpg.
//
// Bewusste Design-Entscheidungen:
//   • **Im App-Sandbox**, nicht in der System-Foto-Library. Der User
//     kann sie also jederzeit löschen, ohne dass seine andere Foto-Library
//     vollgemüllt wird.
//   • **Kein iCloud-Backup**. NSURLIsExcludedFromBackupKey ist hier
//     sinnvoll, weil es ein SECONDARY-ARCHIV ist und die primären Fotos
//     ohnehin in der Foto-Library leben.
//   • **Metadaten in UserDefaults.standard** (nicht App-Group!), weil
//     das Widget die Liste der Fotos nicht braucht — nur die Haupt-App.

@Observable
final class PhotoStreakStore {

    /// Ein Foto-Eintrag. `id` ist der Dateiname (= UUID), was die
    /// Datei performant zum Identifiable-Item macht UND garantiert,
    /// dass kein Foto doppelt vorkommt.
    struct Entry: Identifiable, Hashable {
        let id: String
        let week: String          // ISO-Woche (z. B. "2026-W28")
        let capturedAt: Date
        var filename: String { id }
    }

    /// Liste der vorhandenen Einträge; von SwiftUI beobachtbar.
    private(set) var entries: [Entry] = []

    /// Wo die Fotos liegen — wiederverwendet von der Gallery beim Lesen.
    let directory: URL

    private static let storageKey = "photoStreakEntries"

    init() {
        let docs = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        directory = docs.appendingPathComponent("photoStreak", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
        )
        loadFromDefaults()
    }

    /// Vollständiger Datei-Pfad zu einem Eintrag.
    func url(for entry: Entry) -> URL {
        directory.appendingPathComponent(entry.filename)
    }

    /// Fügt das aktuelle Bild in der aktuellen ISO-Woche hinzu.
    /// Liefert true bei Erfolg, false wenn das JPEG-Encoding schief ging.
    @discardableResult
    func add(image: UIImage, week: String = WeekKey.current) -> Bool {
        let filename = "\(UUID().uuidString).jpg"
        let url = directory.appendingPathComponent(filename)

        guard let data = image.jpegData(compressionQuality: 0.85) else {
            return false
        }
        do {
            try data.write(to: url, options: .atomic)
            entries.insert(
                Entry(id: filename, week: week, capturedAt: Date()),
                at: 0
            )
            saveToDefaults()
            return true
        } catch {
            return false
        }
    }

    /// Löscht einen Eintrag (Datei + Metadaten).
    func delete(_ entry: Entry) {
        try? FileManager.default.removeItem(at: url(for: entry))
        entries.removeAll { $0.id == entry.id }
        saveToDefaults()
    }

    /// Einträge der aktuellen ISO-Woche.
    func entriesThisWeek() -> [Entry] {
        let currentWeek = WeekKey.current
        return entries.filter { $0.week == currentWeek }
    }

    /// True, wenn diese Woche bereits ein Foto eingetragen ist.
    /// Vermeidet Doppel-Submit, falls der User zweimal auf den Button tippt.
    var alreadyCapturedThisWeek: Bool {
        !entriesThisWeek().isEmpty
    }

    // MARK: - Persistence

    /// Räumt Einträge auf, deren Datei nicht mehr existiert (z.B. nach
    /// manuellem Sandbox-Clean). Wird nach dem Laden automatisch gerufen.
    private func pruneMissing() {
        let fm = FileManager.default
        entries.removeAll { !fm.fileExists(atPath: url(for: $0).path) }
    }

    private func loadFromDefaults() {
        guard let raw = UserDefaults.standard.array(forKey: Self.storageKey) as? [[String: Any]]
        else { return }
        entries = raw.compactMap { dict -> Entry? in
            guard let filename = dict["filename"] as? String,
                  let week = dict["week"] as? String,
                  let ts = dict["capturedAt"] as? Double
            else { return nil }
            return Entry(
                id: filename,
                week: week,
                capturedAt: Date(timeIntervalSince1970: ts)
            )
        }
            .sorted { $0.capturedAt > $1.capturedAt }

        // Einträge ohne Datei = Müll → direkt rauswerfen.
        pruneMissing()
    }

    private func saveToDefaults() {
        let arr = entries.map { entry -> [String: Any] in
            [
                "filename": entry.filename,
                "week": entry.week,
                "capturedAt": entry.capturedAt.timeIntervalSince1970,
            ]
        }
        UserDefaults.standard.set(arr, forKey: Self.storageKey)
    }
}
