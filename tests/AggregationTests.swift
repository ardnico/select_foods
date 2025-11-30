import Foundation
import XCTest
@testable import select_foods

final class AggregationTests: XCTestCase {
    func testAggregatesIngredientTotals() {
        let chicken = Ingredient(name: "鶏肉", unit: "g")
        let soy = Ingredient(name: "醤油", unit: "ml")
        let menu1 = Menu(name: "照り焼き", type: .japanese, ingredients: [
            MenuIngredient(ingredient: chicken, quantity: 200),
            MenuIngredient(ingredient: soy, quantity: 30)
        ])
        let menu2 = Menu(name: "唐揚げ", type: .japanese, ingredients: [
            MenuIngredient(ingredient: chicken, quantity: 250),
            MenuIngredient(ingredient: soy, quantity: 10)
        ])
        let planRepo = InMemoryPlanRepository(startDate: Date(), endDate: Date())
        let menuRepo = InMemoryMenuRepository(seed: [menu1, menu2])
        let store = PlanStore(planRepository: planRepo, menuRepository: menuRepo)

        let today = Calendar.current.startOfDay(for: Date())
        store.assign(menu: menu1, to: today, slot: .lunch)
        store.assign(menu: menu2, to: today, slot: .dinner)

        let totals = store.ingredientTotals()
        let chickenTotal = totals.first { $0.ingredient == chicken }
        let soyTotal = totals.first { $0.ingredient == soy }

        XCTAssertEqual(chickenTotal?.totalQuantity, 450)
        XCTAssertEqual(soyTotal?.totalQuantity, 40)
    }

    func testUpdateRebuildsPlanDaysAndDropsOutOfRangeAssignments() {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let end = calendar.date(byAdding: .day, value: 6, to: start)!
        let shortenedEnd = calendar.date(byAdding: .day, value: 2, to: start)!

        let planRepo = InMemoryPlanRepository(startDate: start, endDate: end)
        let menuRepo = InMemoryMenuRepository()
        let store = PlanStore(planRepository: planRepo, menuRepository: menuRepo)

        store.update(dateRange: start...end)
        XCTAssertEqual(store.plan.days.count, 7)

        let menu = Menu.sampleMenus[0]
        store.assign(menu: menu, to: start, slot: .lunch)
        XCTAssertEqual(store.plan.days.first?.lunch?.id, menu.id)

        store.update(dateRange: start...shortenedEnd)
        XCTAssertEqual(store.plan.days.count, 3)
        XCTAssertTrue(store.plan.days.allSatisfy { $0.lunch == nil && $0.dinner == nil })
    }
}
