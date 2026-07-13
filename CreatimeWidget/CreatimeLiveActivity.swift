import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Creatime Live Activity Widget
//
// Wird zusammen mit `CreatimeWidget` (dem normalen Home-Screen-Widget)
// im gleichen `WidgetBundle` registriert — siehe `CreatimeWidgetBundle`
// in `CreatimeWidget.swift`.
//
// Lifecycle:
//   • Start: von `LiveActivityManager.startOrUpdate(...)` aus der
//     Haupt-App. Activity.request ist `async throws` und liefert eine
//     `Activity<CreatimeActivityAttributes>`-Referenz.
//   • Update: Activity.update mit neuem `ContentState` → Dynamic Island
//     zeichnet sich neu.
//   • End: Activity.end — der User kann sie auch manuell in der
//     Dynamic Island wegwischen.
//
// Wichtig: dies ist eine **ANDERE** Struct als `CreatimeWidget`. Beide
// müssen im selben `WidgetBundle.body` registriert werden, damit iOS
// beide nebeneinander unterstützt.

@available(iOS 16.2, *)
struct CreatimeLiveActivity: Widget {

    /// Eindeutige Activity-Widget-Kennung. Egal — iOS sucht zur
    /// Laufzeit nach `ActivityConfiguration(for:)`.
    let kind = "CreatimeLiveActivity"

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CreatimeActivityAttributes.self) { context in
            // MARK: - 1) Lock-Screen / Banner (auch im Standby-Modus)
            LockScreenLiveView(context: context)
                .activityBackgroundTint(Color.indigo.opacity(0.85))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            // MARK: - 2) Dynamic Island: kompakt + minimal + expanded
            DynamicIsland {
                // EXPANDED — wenn User lang auf die Island tippt:
                DynamicIslandExpandedRegion(.leading) {
                    Label("\(context.state.streak)", systemImage: "flame.fill")
                        .font(.title.bold())
                        .foregroundStyle(.orange)
                        .labelStyle(.titleAndIcon)
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.creatineTaken {
                        Label("Erledigt", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                            .padding(.trailing, 6)
                    } else {
                        Label("Offen", systemImage: "circle.dashed")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 6)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    let goalSafe = max(1, context.state.waterGoalML)
                    let progress = min(1.0, Double(context.state.waterML) / Double(goalSafe))
                    HStack(spacing: 8) {
                        Image(systemName: "drop.fill")
                            .foregroundStyle(.blue)
                        ProgressView(value: progress)
                            .tint(.blue)
                            .frame(maxWidth: .infinity)
                        Text("\(context.state.waterML / 1000) L / \(context.state.waterGoalML / 1000) L")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
            } compactLeading: {
                // Kompakt (default): 🔥 links
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                // Kompakt (default): Streak-Zahl rechts
                Text("\(context.state.streak)")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(.primary)
            } minimal: {
                // Minimal (mehrere Activities gleichzeitig): nur 🔥
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
            }
            // Hinweis: bewusst kein .widgetURL für v1 — das URL-Schema
            // `creatime://` ist noch nicht in Info.plist registriert,
            // und ein tappender User in der Dynamic Island würde aktuell
            // einfach nichts tun. Wenn wir später Deep-Links wollen,
            // müssen wir CFBundleURLTypes ergänzen.
            .keylineTint(.orange)
        }
    }
}

// MARK: - Lock-Screen / Stretched-Banner-View
//
// Wenn die Dynamic Island nicht aktiv ist (ältere iPhones), erscheint
// die Activity unten auf dem Lock-Screen oder als Banner über der App.
// Hier bekommt sie den vollen "Streak-Card"-Stil.

private struct LockScreenLiveView: View {
    let context: ActivityViewContext<CreatimeActivityAttributes>

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.title3)
                    Text("\(context.state.streak)")
                        .font(.system(.title, design: .rounded).bold())
                        .foregroundStyle(.white)
                }
                if context.state.creatineTaken {
                    Label("Heute erledigt", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                } else {
                    Label("Heute offen", systemImage: "circle.dashed")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                let goalSafe = max(1, context.state.waterGoalML)
                let progress = min(1.0, Double(context.state.waterML) / Double(goalSafe))
                Text("\(context.state.waterML / 1000) L / \(context.state.waterGoalML / 1000) L")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(.white)
                ProgressView(value: progress)
                    .tint(.blue)
                    .frame(width: 110)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}
