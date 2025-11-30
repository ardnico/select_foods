#if canImport(SwiftUI)
import SwiftUI

public struct ContentView: View {
    @StateObject private var menuStore: MenuStore
    @StateObject private var planStore: PlanStore
    @State private var showingPicker: Bool = false
    @State private var selectedDay: PlanDay?
    @State private var selectedSlot: MealSlot = .lunch
    @State private var dateRange: ClosedRange<Date>

    public init(menuRepository: MenuRepository, planRepository: PlanRepository) {
        let today = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 6, to: today) ?? today
        _menuStore = StateObject(wrappedValue: MenuStore(repository: menuRepository))
        _planStore = StateObject(wrappedValue: PlanStore(planRepository: planRepository, menuRepository: menuRepository))
        _dateRange = State(initialValue: today...end)
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                PeriodSelectionView(range: $dateRange) { range in
                    planStore.update(dateRange: range)
                }
                PlanListView(plan: planStore.plan) { day, slot in
                    selectedDay = day
                    selectedSlot = slot
                    showingPicker = true
                }
                IngredientSummaryView(totals: planStore.ingredientTotals())
                Spacer()
            }
            .sheet(isPresented: $showingPicker) {
                if let selectedDay {
                    MenuPickerView(
                        menuStore: menuStore,
                        onSelect: { menu in
                            planStore.assign(menu: menu, to: selectedDay.date, slot: selectedSlot)
                        }
                    )
                }
            }
            .navigationTitle("Select Foods")
            .toolbar {
                NavigationLink("Menus") {
                    MenuManagementView(menuStore: menuStore)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let menuRepo = InMemoryMenuRepository()
        let planRepo = InMemoryPlanRepository(startDate: Date(), endDate: Date())
        ContentView(menuRepository: menuRepo, planRepository: planRepo)
    }
}
#endif
