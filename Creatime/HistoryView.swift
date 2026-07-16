import SwiftUI

// MARK: - Fortschritts-Tab (v16 — Claude Design Port)
//
// Layout matches Creatime.dc.html screen 1c:
//   1. Header — PageTitle "Fortschritt" + 93-% BigNumber right-aligned
//   2. CalendarCard (7-col month grid + legend)
//   3. BuddyBattleCard (avatar list + progress bars)
//   4. PhotoStripCard (horizontal tile strip)
//
// State bindings (CreatineStore) preserved exactly from v15.0.
// Safe area + horizontal-scroll protections preserved.

struct HistoryView: View {

    @Environment(CreatineStore.self) private var store
    @Environment(WaterStore.self) private var water

    @State private var showSettings = false

    private var fulfilmentPct: Int {
        Int((store.last30DaysRate * 100).rounded())
    }

    private var recentPhotos: [(label: String, key: String)] {
        [
            ("Mo", "mo"), ("So", "so"), ("Sa", "sa"), ("Fr", "fr")
        ]
    }

    var body: some View {
        ZStack {
            DynamicBackground()

            ScrollView {
                VStack(spacing: 12) {
                    header
                    CalendarCard()
                    BuddyBattleCard()
                    PhotoStripCard(recentPhotos: recentPhotos)
                }
                .ctPagePadded()
                .padding(.vertical, 16)
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            PageTitle(text: "Fortschritt")
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Text("\(fulfilmentPct)")
                        .font(.ctBigNumber).tracking(-2)
                        .foregroundStyle(Color.ctAccent)
                    Text("%")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.ctAccent)
                }
                Text("Juli-Erfüllung")
                    .font(.caption)
                    .foregroundStyle(Color.ctInkSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }
}

#Preview {
    HistoryView()
        .environment(CreatineStore())
        .environment(WaterStore())
}
