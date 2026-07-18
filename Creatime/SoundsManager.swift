import Foundation
import SwiftUI
import AVFoundation
import UIKit

// MARK: - Sound-System (V2 — weiche, selbst erzeugte Töne)
//
// KOMPLETT ÜBERARBEITET: Vorher spielten wir harte iOS-System-Sounds
// (`AudioServicesPlaySystemSound`, z. B. 1306 „Heavy Punch"). Problem:
// diese Sounds sind fix laut — man kann die Lautstärke NICHT steuern,
// und der Punch-Klick wirkte wie ein nerviges „Ticken".
//
// Jetzt: Wir SYNTHETISIEREN kurze, weiche Sinus-Töne selbst (als PCM-WAV
// im Speicher) und spielen sie über `AVAudioPlayer`. Dadurch haben wir
// volle Kontrolle über Lautstärke (`masterVolume`) und Klangfarbe —
// gedämpfte, angenehme „Blips" statt scharfer System-Klicks.
//
// Audio-Session `.ambient` + `.mixWithOthers`: respektiert den stummen
// Klingelschalter (kein Ton, wenn das iPhone auf lautlos steht) und
// unterbricht laufende Musik/Podcasts nicht.

@MainActor
@Observable
final class SoundsManager {

    /// Gesamt-Lautstärke aller App-Sounds (0…1). Bewusst niedrig, damit
    /// die Feedback-Töne dezent bleiben und nie „laut" wirken.
    private let masterVolume: Float = 0.5

    /// Damit die kurzen Player nicht mitten im Ton wegdealloziert werden,
    /// halten wir sie hier fest und räumen fertige vor jedem Abspielen ab.
    private var activePlayers: [AVAudioPlayer] = []

    private var sessionConfigured = false

    init() {}

    // MARK: - Öffentliche Sounds (API-kompatibel zu vorher)

    /// Kreatin abgehakt — sanfter, aufsteigender Zwei-Ton-„Confirm".
    /// Ersetzt den harten „Heavy Punch". Dazu ein weiches Haptik-Tippen.
    func playCreatineMark() {
        play(notes: [(587.33, 0.085), (880.0, 0.11)], amplitude: 0.5)
        softImpact(0.7)
    }

    /// Wasser hinzugefügt — sehr dezenter, kurzer Einzel-Blip + leichtes Tippen.
    func playWaterSplash() {
        play(notes: [(659.25, 0.055)], amplitude: 0.32)
        softImpact(0.4)
    }

    /// Wasserziel erreicht — freundliches Drei-Ton-Arpeggio (C-E-G) + Success-Haptik.
    func playGoalReached() {
        play(notes: [(523.25, 0.10), (659.25, 0.10), (783.99, 0.17)], amplitude: 0.5)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Streak eingefroren — weicher, absteigender Zwei-Ton.
    func playFreeze() {
        play(notes: [(659.25, 0.09), (493.88, 0.13)], amplitude: 0.42)
        softImpact(0.5)
    }

    // MARK: - Haptik

    private func softImpact(_ intensity: CGFloat) {
        let gen = UIImpactFeedbackGenerator(style: .soft)
        gen.prepare()
        gen.impactOccurred(intensity: intensity)
    }

    // MARK: - Ton-Wiedergabe

    private func play(notes: [(freq: Double, dur: Double)], amplitude: Double) {
        configureSessionIfNeeded()
        guard let data = Self.renderMelody(notes, amplitude: amplitude) else { return }
        // Fertige Player abräumen, damit die Liste nicht wächst.
        activePlayers.removeAll { !$0.isPlaying }
        do {
            let player = try AVAudioPlayer(data: data)
            player.volume = masterVolume
            player.prepareToPlay()
            player.play()
            activePlayers.append(player)
        } catch {
            print("SoundsManager: Wiedergabe fehlgeschlagen: \(error)")
        }
    }

    private func configureSessionIfNeeded() {
        guard !sessionConfigured else { return }
        sessionConfigured = true
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("SoundsManager: AVAudioSession-Konfiguration fehlgeschlagen: \(error)")
        }
        #endif
    }

    // MARK: - Ton-Synthese (PCM-16 WAV im Speicher)

    /// Rendert eine Folge von Noten (nacheinander) als weiche Sinus-Töne
    /// mit sanfter Attack/Decay-Hüllkurve (verhindert Knackser) und packt
    /// sie in ein WAV-`Data`, das `AVAudioPlayer` direkt abspielen kann.
    private static func renderMelody(
        _ notes: [(freq: Double, dur: Double)],
        amplitude: Double,
        sampleRate: Double = 44_100
    ) -> Data? {
        guard !notes.isEmpty else { return nil }

        var samples: [Int16] = []
        for note in notes {
            let frameCount = Int(note.dur * sampleRate)
            guard frameCount > 0 else { continue }
            let attack = Int(0.008 * sampleRate)   // 8 ms sanfter Einschwinger

            for n in 0..<frameCount {
                let t = Double(n) / sampleRate
                // Hüllkurve: linearer Attack, danach weiches Ausklingen (^1.6).
                let env: Double
                if n < attack {
                    env = Double(n) / Double(attack)
                } else {
                    let p = Double(n) / Double(frameCount)
                    env = pow(1.0 - p, 1.6)
                }
                let value = sin(2.0 * .pi * note.freq * t) * env * amplitude
                let clamped = max(-1.0, min(1.0, value))
                samples.append(Int16(clamped * Double(Int16.max)))
            }
        }
        guard !samples.isEmpty else { return nil }
        return wavData(from: samples, sampleRate: Int(sampleRate))
    }

    /// Baut einen minimalen WAV-Container (Mono, PCM 16-bit) um die Samples.
    private static func wavData(from samples: [Int16], sampleRate: Int) -> Data {
        let channels = 1
        let bitsPerSample = 16
        let byteRate = sampleRate * channels * bitsPerSample / 8
        let blockAlign = channels * bitsPerSample / 8
        let dataSize = samples.count * bitsPerSample / 8

        var data = Data()
        func append(_ string: String) { data.append(contentsOf: string.utf8) }
        func append32(_ value: Int) { var v = UInt32(value).littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        func append16(_ value: Int) { var v = UInt16(value).littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }

        append("RIFF"); append32(36 + dataSize); append("WAVE")
        append("fmt "); append32(16); append16(1)            // PCM
        append16(channels); append32(sampleRate); append32(byteRate)
        append16(blockAlign); append16(bitsPerSample)
        append("data"); append32(dataSize)
        for sample in samples {
            var v = sample.littleEndian
            withUnsafeBytes(of: &v) { data.append(contentsOf: $0) }
        }
        return data
    }
}
