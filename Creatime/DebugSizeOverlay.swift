import SwiftUI

// MARK: - DebugSizeOverlay (v14.5 — DIAGNOSE-INSTRUMENT)
//
// Hilfs-View die in `#if DEBUG`-Builds jeden Sub-Block umrandet und die
// tatsächlich gerenderte Breite anzeigt (rot wenn > Parent-Breite,
// grün sonst). Plus print auf Konsole für Xcode-Debugger.
//
// Verwendung:
//   statGrid
//     .debugSize("HistoryView.statGrid")
//
// Bei Release-Builds ist die View komplett leer (no-op) — also kann
// der Code ohne Aufräumen im Master-Branch bleiben, kostet nur den
// `#if`-Compiler-Block.
//
// So liest du die Diagnose auf dem Bildschirm:
//   • Roter Border + rote Eck-Label = Subview ist breiter als der
//     ScrollView → schuld an horizontalem Bounce/Swipe.
//   • Grüner Border + grüne Eck-Label = alles OK, weiter suchen.
//
// Auf der Konsole (Xcode → View → Debug Area → Activate Console):
//   DEBUG-SIZE [HistoryView.statGrid] = 343pt
//   DEBUG-SIZE [HistoryView.MonthCalendar] = 412pt   ← ROT
//
// Nach der Diagnose: `#if DEBUG`-Block in HistoryView entfernen und
// wieder einen normalen Build laufen lassen.

#if DEBUG
struct DebugSizeOverlay<Content: View>: View {
    let label: String
    let content: Content
    @State private var measuredWidth: CGFloat = 0
    @State private var parentWidth: CGFloat = 0

    /// `threshold` = Breite-ab-welcher der Border rot wird. Default
    /// 393pt = Standard-iPhone-Breite. Auf iPad/Mac größer einstellen.
    var threshold: CGFloat = 393

    init(label: String, threshold: CGFloat = 393, @ViewBuilder content: () -> Content) {
        self.label = label
        self.threshold = threshold
        self.content = content()
    }

    var body: some View {
        // GeometryReader im Background misst die gerenderte Breite.
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            measuredWidth = geo.size.width
                            parentWidth = UIScreen.main.bounds.width
                            print("DEBUG-SIZE [\(label)] = \(Int(geo.size.width))pt (parent=\(Int(parentWidth))pt)")
                        }
                        .onChange(of: geo.size.width) { _, new in
                            measuredWidth = new
                            print("DEBUG-SIZE [\(label)] = \(Int(new))pt")
                        }
                }
            )
            .overlay {
                Rectangle()
                    .stroke(borderColor, lineWidth: 2)
            }
            .overlay(alignment: .topLeading) {
                Text("\(label) · \(Int(measuredWidth))pt")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(borderColor, in: Rectangle())
            }
    }

    /// Rot wenn gemessene Breite den Threshold überschreitet (= Parent
    /// ist in Parent-Scroll-View überschossen), sonst grün.
    private var borderColor: Color {
        measuredWidth > threshold ? .red : .green
    }
}

extension View {
    /// Wrappt eine View in `DebugSizeOverlay`. Nur in DEBUG-Builds aktiv.
    func debugSize(_ label: String, threshold: CGFloat = 393) -> some View {
        DebugSizeOverlay(label: label, threshold: threshold) { self }
    }
}
#else
// In Release-Builds: komplett no-op, kostet keine Performance.
extension View {
    func debugSize(_ label: String, threshold: CGFloat = 393) -> some View {
        self
    }
}
#endif
