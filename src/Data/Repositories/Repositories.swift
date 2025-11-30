import Foundation
import Combine

public protocol PlanRepository {
    func loadPlan(startDate: Date, endDate: Date) -> AnyPublisher<Plan, Never>
    func save(plan: Plan)
}

public protocol MenuRepository {
    var menuTypes: [MenuType] { get }
    var menuTypeSets: [MenuTypeSet] { get }
    func menus() -> AnyPublisher<[Menu], Never>
    func add(menu: Menu)
}
