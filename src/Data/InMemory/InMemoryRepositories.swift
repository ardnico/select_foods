import Foundation
#if canImport(Combine)
import Combine
#endif

public final class InMemoryPlanRepository: PlanRepository {
    private var plan: Plan

    public init(startDate: Date, endDate: Date) {
        self.plan = Plan(startDate: startDate, endDate: endDate, days: InMemoryPlanRepository.makeDays(start: startDate, end: endDate))
    }

    private static func makeDays(start: Date, end: Date) -> [PlanDay] {
        var days: [PlanDay] = []
        var cursor = start
        let calendar = Calendar.current
        while cursor <= end {
            days.append(PlanDay(date: cursor))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return days
    }

    public func loadPlan(startDate: Date, endDate: Date) -> AnyPublisher<Plan, Never> {
        if startDate != plan.startDate || endDate != plan.endDate {
            plan.startDate = startDate
            plan.endDate = endDate
            plan.days = Self.makeDays(start: startDate, end: endDate)
        }
        return Just(plan).eraseToAnyPublisher()
    }

    public func save(plan: Plan) {
        self.plan = plan
    }
}

public final class InMemoryMenuRepository: MenuRepository, ObservableObject {
    @Published private var storage: [Menu]
    public let menuTypes: [MenuType]
    public let menuTypeSets: [MenuTypeSet]

    public init(seed: [Menu] = Menu.sampleMenus, menuTypes: [MenuType] = MenuType.presets, menuTypeSets: [MenuTypeSet] = []) {
        self.storage = seed
        let typeSets = menuTypeSets.isEmpty ? [
            MenuTypeSet(name: "和食中心", includedTypes: [.japanese]),
            MenuTypeSet(name: "時短", includedTypes: [.western, .italian]),
            MenuTypeSet(name: "ヘルシー", includedTypes: [.japanese, .western])
        ] : menuTypeSets
        self.menuTypeSets = typeSets
        self.menuTypes = menuTypes
    }

    public func menus() -> AnyPublisher<[Menu], Never> {
        $storage.eraseToAnyPublisher()
    }

    public func add(menu: Menu) {
        guard menu.isValid else { return }
        storage.append(menu)
    }
}
