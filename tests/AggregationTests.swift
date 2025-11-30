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
}
