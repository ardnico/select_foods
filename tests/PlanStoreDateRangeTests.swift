import Foundation
import XCTest
@testable import select_foods

final class PlanStoreDateRangeTests: XCTestCase {
    func testDateRangeUpdateRetainsOverlappingAssignments() {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let nextDay = calendar.date(byAdding: .day, value: 1, to: start)!
        let thirdDay = calendar.date(byAdding: .day, value: 2, to: start)!

        let menu = Menu(name: "テストメニュー", type: .japanese, ingredients: [
            MenuIngredient(ingredient: Ingredient(name: "材料", unit: "g"), quantity: 100)
        ])

        let planRepo = InMemoryPlanRepository(startDate: start, endDate: nextDay)
        let menuRepo = InMemoryMenuRepository(seed: [menu])
        let store = PlanStore(planRepository: planRepo, menuRepository: menuRepo)

        store.assign(menu: menu, to: start, slot: .lunch)
        store.assign(menu: menu, to: nextDay, slot: .dinner)

        store.update(dateRange: nextDay...thirdDay)

        let days = store.plan.days
        XCTAssertEqual(days.count, 2)

        let first = days[0]
        XCTAssertTrue(calendar.isDate(first.date, inSameDayAs: nextDay))
        XCTAssertNil(first.lunch)
        XCTAssertEqual(first.dinner, menu)

        let second = days[1]
        XCTAssertTrue(calendar.isDate(second.date, inSameDayAs: thirdDay))
        XCTAssertNil(second.lunch)
        XCTAssertNil(second.dinner)
    }
}
