import Foundation
import HealthKit

// Schreibt das getrunkene Wasser in Apple Health (Datentyp "dietaryWater").
// Wichtig zu verstehen: Health ist bei uns nur ein SPIEGEL — die Wahrheit
// lebt im WaterStore. Deshalb löschen wir beim Sync erst unsere eigenen
// heutigen Einträge und schreiben dann EINEN Eintrag mit der Gesamtmenge.
// So stimmt Health auch nach einem Minus-Tap wieder exakt.
final class HealthKitManager {

    static let shared = HealthKitManager()
    private init() {}

    private let healthStore = HKHealthStore()
    private let waterType = HKQuantityType(.dietaryWater)

    /// Auf dem iPad/Mac gibt es kein Health — immer zuerst prüfen.
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Zeigt den System-Dialog, in dem der Nutzer den Zugriff erlaubt.
    func requestAuthorization() {
        guard isAvailable else { return }
        healthStore.requestAuthorization(toShare: [waterType], read: []) { _, error in
            if let error {
                print("Health-Berechtigung fehlgeschlagen: \(error)")
            }
        }
    }

    /// Gleicht Health mit der heutigen Gesamtmenge ab:
    /// 1. Alle heutigen Wasser-Einträge finden, die VON CREATIME stammen
    ///    (fremde Einträge, z.B. von anderen Apps, fassen wir nie an!)
    /// 2. Diese löschen
    /// 3. Einen neuen Eintrag mit der aktuellen Gesamtmenge schreiben
    func syncTodayWater(totalML: Int) {
        guard isAvailable else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }

        let todayPredicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay)
        let ownEntriesPredicate = HKQuery.predicateForObjects(from: HKSource.default())
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [todayPredicate, ownEntriesPredicate])

        let query = HKSampleQuery(
            sampleType: waterType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { [self] _, samples, _ in

            let writeNewTotal = {
                guard totalML > 0 else { return }
                let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: Double(totalML))
                let sample = HKQuantitySample(type: self.waterType, quantity: quantity, start: Date(), end: Date())
                self.healthStore.save(sample) { _, error in
                    if let error {
                        print("Health-Speichern fehlgeschlagen: \(error)")
                    }
                }
            }

            if let samples, !samples.isEmpty {
                self.healthStore.delete(samples) { _, _ in
                    writeNewTotal()
                }
            } else {
                writeNewTotal()
            }
        }

        healthStore.execute(query)
    }
}
