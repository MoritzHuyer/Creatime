import SwiftUI
import UIKit

// MARK: - Share-Card-Rendering
//
// Renders the current streak as a 1080 × 1080 PNG, suitable for sharing
// on Instagram, WhatsApp, X (Twitter), iMessage. Uses iOS 16+ ImageRenderer.

struct ShareStreakCard: View {
    let streak: Int
    let bestStreak: Int
    let takenToday: Bool
    let dateText: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.36, green: 0.49, blue: 1.00),
                    Color(red: 0.49, green: 0.43, blue: 0.88),
                    Color(red: 0.59, green: 0.45, blue: 0.91),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.white.opacity(0.30), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 900
            )
            .blendMode(.plusLighter)

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "flame.fill")
                    Text("Creatime")
                    Text("·")
                    Text(dateText)
                }
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.top, 80)

                Spacer()

                VStack(spacing: 12) {
                    Text("🔥")
                        .font(.system(size: 110))
                        .shadow(color: .black.opacity(0.18), radius: 14, y: 6)

                    Text("\(streak)")
                        .font(.system(size: 280, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.22), radius: 14, y: 6)

                    Text(streak == 1 ? "TAG IN FOLGE" : "TAGE IN FOLGE")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .tracking(4)
                        .foregroundStyle(.white.opacity(0.95))
                }

                Spacer()

                HStack(alignment: .center, spacing: 28) {
                    statColumn(value: "\(bestStreak)", label: "Beste Streak")
                    Rectangle()
                        .fill(.white.opacity(0.45))
                        .frame(width: 1.5, height: 56)
                    statColumn(
                        symbol: takenToday ? "checkmark.circle.fill" : "circle",
                        symbolTint: takenToday ? .green : .white.opacity(0.75),
                        label: takenToday ? "Heute erledigt" : "Heute offen"
                    )
                }

                Spacer()

                Text("creatime.app")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.bottom, 80)
            }
            .padding(.horizontal, 60)
        }
        .frame(width: 1080, height: 1080)
    }

    @ViewBuilder
    private func statColumn(
        value: String? = nil,
        symbol: String? = nil,
        symbolTint: Color = .white,
        label: String
    ) -> some View {
        VStack(spacing: 6) {
            if let value {
                Text(value)
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            } else if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 56))
                    .foregroundStyle(symbolTint)
            }
            Text(label.uppercased())
                .font(.system(size: 18, weight: .semibold))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}

// MARK: - Share-Sheet-Wrapper

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {
        // No-op.
    }
}

#Preview("Share-Streak-Card") {
    ShareStreakCard(streak: 42, bestStreak: 89, takenToday: true, dateText: "12. Juli 2026")
        .scaleEffect(0.3)
        .frame(width: 320, height: 320)
}
