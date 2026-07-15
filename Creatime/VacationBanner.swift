import SwiftUI

// MARK: - VacationBanner (v7 — Glass-Card)
//
// Wird in TodayView ODER HistoryView oben angezeigt, wenn der
// Urlaubsmodus aktiv ist. Klickbar — öffnet das VacationModeSheet.
//
// Layout: Palm-Icon, "Urlaubsmodus bis <Datum>", Chevron nach rechts.

struct VacationBanner: View {
    let until: Date
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: "palm.tree.fill")
                    .foregroundStyle(.teal)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Urlaubsmodus aktiv")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Bis \(until, format: .dateTime.day().month(.wide).year())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .airySection()
        .accessibilityLabel("Urlaubsmodus aktiv bis \(until.formatted(date: .abbreviated, time: .omitted)). Tippen zum Bearbeiten.")
    }
}
