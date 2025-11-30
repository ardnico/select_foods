#if canImport(SwiftUI)
import SwiftUI

struct PlanListView: View {
    var plan: Plan
    var onSelect: (PlanDay, MealSlot) -> Void

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }

    var body: some View {
        List(plan.days) { day in
            VStack(alignment: .leading) {
                Text(dateFormatter.string(from: day.date)).font(.headline)
                HStack {
                    MenuSlotView(title: "昼", menu: day.lunch) {
                        onSelect(day, .lunch)
                    }
                    MenuSlotView(title: "夜", menu: day.dinner) {
                        onSelect(day, .dinner)
                    }
                }
            }
        }
    }
}

private struct MenuSlotView: View {
    var title: String
    var menu: Menu?
    var onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.subheadline)
            Button(action: onTap) {
                HStack {
                    Text(menu?.name ?? "未設定")
                    Spacer()
                }
            }
            .buttonStyle(.bordered)
        }
    }
}
#endif
