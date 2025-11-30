import Foundation
#if canImport(Combine)
import Combine
#endif

public final class PlanStore: ObservableObject {
    @Published public private(set) var plan: Plan
    private let planRepository: PlanRepository
    private let menuRepository: MenuRepository
    private var cancellables: Set<AnyCancellable> = []

    public init(planRepository: PlanRepository, menuRepository: MenuRepository) {
        self.planRepository = planRepository
        self.menuRepository = menuRepository
        let today = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 6, to: today) ?? today
        self.plan = Plan(startDate: today, endDate: end, days: [])
        loadPlan(startDate: today, endDate: end)
    }

    public func loadPlan(startDate: Date, endDate: Date) {
        planRepository.loadPlan(startDate: startDate, endDate: endDate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.plan = value
            }
            .store(in: &cancellables)
    }

    public func update(dateRange: ClosedRange<Date>) {
        loadPlan(startDate: dateRange.lowerBound, endDate: dateRange.upperBound)
    }

    public func assign(menu: Menu, to date: Date, slot: MealSlot) {
        guard let index = plan.days.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) else { return }
        var day = plan.days[index]
        switch slot {
        case .lunch: day.lunch = menu
        case .dinner: day.dinner = menu
        }
        plan.days[index] = day
        planRepository.save(plan: plan)
    }

    public func menusPublisher() -> AnyPublisher<[Menu], Never> {
        menuRepository.menus()
    }

    public func ingredientTotals() -> [IngredientTotal] {
        var totals: [Ingredient: Double] = [:]
        for day in plan.days {
            let menus = [day.lunch, day.dinner].compactMap { $0 }
            for menu in menus {
                for item in menu.ingredients where item.isValid {
                    let current = totals[item.ingredient, default: 0]
                    let updated = current + max(0, item.quantity)
                    totals[item.ingredient] = updated
                }
            }
        }
        return totals.map { IngredientTotal(ingredient: $0.key, totalQuantity: $0.value) }
            .sorted {
                if $0.ingredient.name == $1.ingredient.name {
                    return $0.ingredient.unit < $1.ingredient.unit
                }
                return $0.ingredient.name < $1.ingredient.name
            }
    }
}
