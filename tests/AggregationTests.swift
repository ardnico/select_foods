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

    func testUpdatePreservesInRangeAssignmentsAndDropsOutliers() {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let end = calendar.date(byAdding: .day, value: 6, to: start)!
        let shortenedEnd = calendar.date(byAdding: .day, value: 2, to: start)!

        let planRepo = InMemoryPlanRepository(startDate: start, endDate: end)
        let menuRepo = InMemoryMenuRepository()
        let store = PlanStore(planRepository: planRepo, menuRepository: menuRepo)

        store.update(dateRange: start...end)
        XCTAssertEqual(store.plan.days.count, 7)

        let inRangeMenu = Menu.sampleMenus[0]
        let outOfRangeMenu = Menu.sampleMenus[1]
        let outOfRangeDate = calendar.date(byAdding: .day, value: 5, to: start)!

        store.assign(menu: inRangeMenu, to: start, slot: .lunch)
        store.assign(menu: outOfRangeMenu, to: outOfRangeDate, slot: .dinner)

        XCTAssertEqual(store.plan.days.first?.lunch?.id, inRangeMenu.id)
        XCTAssertEqual(store.plan.days.first(where: { $0.date == outOfRangeDate })?.dinner?.id, outOfRangeMenu.id)

        store.update(dateRange: start...shortenedEnd)
        XCTAssertEqual(store.plan.days.count, 3)

        let preservedDay = store.plan.days.first { Calendar.current.isDate($0.date, inSameDayAs: start) }
        XCTAssertEqual(preservedDay?.lunch?.id, inRangeMenu.id)

        let droppedDay = store.plan.days.first { Calendar.current.isDate($0.date, inSameDayAs: outOfRangeDate) }
        XCTAssertNil(droppedDay?.dinner)
    }

    func testUpdateExpandsRangeAndKeepsExistingAssignments() {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.date(from: DateComponents(year: 2025, month: 2, day: 1))!
        let end = calendar.date(byAdding: .day, value: 2, to: start)!
        let extendedEnd = calendar.date(byAdding: .day, value: 6, to: start)!

        let planRepo = InMemoryPlanRepository(startDate: start, endDate: end)
        let menuRepo = InMemoryMenuRepository()
        let store = PlanStore(planRepository: planRepo, menuRepository: menuRepo)

        store.update(dateRange: start...end)
        XCTAssertEqual(store.plan.days.count, 3)

        let assignedMenu = Menu.sampleMenus[2]
        let midDate = calendar.date(byAdding: .day, value: 1, to: start)!
        store.assign(menu: assignedMenu, to: midDate, slot: .dinner)

        store.update(dateRange: start...extendedEnd)

        XCTAssertEqual(store.plan.days.count, 7)

        let preservedDay = store.plan.days.first { Calendar.current.isDate($0.date, inSameDayAs: midDate) }
        XCTAssertEqual(preservedDay?.dinner?.id, assignedMenu.id)

        let newLastDay = store.plan.days.first { Calendar.current.isDate($0.date, inSameDayAs: extendedEnd) }
        XCTAssertNil(newLastDay?.lunch)
        XCTAssertNil(newLastDay?.dinner)
    }

    func testIngredientTotalsSkipInvalidEntries() {
        let invalidIngredient = Ingredient(name: "   ", unit: " ml ")
        let zeroQuantity = MenuIngredient(ingredient: Ingredient(name: "醤油", unit: "ml"), quantity: 0)
        let negativeQuantity = MenuIngredient(ingredient: Ingredient(name: "キャベツ", unit: "g"), quantity: -1)
        let validIngredient = MenuIngredient(ingredient: Ingredient(name: "キャベツ", unit: "g"), quantity: 100)

        let menu = Menu(name: "テスト", type: .japanese, ingredients: [
            MenuIngredient(ingredient: invalidIngredient, quantity: 10),
            zeroQuantity,
            negativeQuantity,
            validIngredient
        ])

        let planRepo = InMemoryPlanRepository(startDate: Date(), endDate: Date())
        let menuRepo = InMemoryMenuRepository(seed: [menu])
        let store = PlanStore(planRepository: planRepo, menuRepository: menuRepo)

        let today = Calendar.current.startOfDay(for: Date())
        store.assign(menu: menu, to: today, slot: .lunch)

        let totals = store.ingredientTotals()
        XCTAssertEqual(totals.count, 1)
        XCTAssertEqual(totals.first?.ingredient.name, "キャベツ")
        XCTAssertEqual(totals.first?.totalQuantity, 100)
    }

    func testIngredientTotalsKeepUnitsSeparateAndOrdered() {
        let saltGrams = MenuIngredient(ingredient: Ingredient(name: "塩", unit: "g"), quantity: 5)
        let saltTeaspoon = MenuIngredient(ingredient: Ingredient(name: "塩", unit: "小さじ"), quantity: 1)
        let soy = MenuIngredient(ingredient: Ingredient(name: "醤油", unit: "ml"), quantity: 10)
        let menu = Menu(name: "味付けテスト", type: .japanese, ingredients: [saltGrams, saltTeaspoon, soy])

        let planRepo = InMemoryPlanRepository(startDate: Date(), endDate: Date())
        let menuRepo = InMemoryMenuRepository(seed: [menu])
        let store = PlanStore(planRepository: planRepo, menuRepository: menuRepo)

        let today = Calendar.current.startOfDay(for: Date())
        store.assign(menu: menu, to: today, slot: .lunch)

        let totals = store.ingredientTotals()
        XCTAssertEqual(totals.count, 3)

        XCTAssertEqual(totals[0].ingredient.name, "塩")
        XCTAssertEqual(totals[0].ingredient.unit, "g")
        XCTAssertEqual(totals[0].totalQuantity, 5)

        XCTAssertEqual(totals[1].ingredient.name, "塩")
        XCTAssertEqual(totals[1].ingredient.unit, "小さじ")
        XCTAssertEqual(totals[1].totalQuantity, 1)

        XCTAssertEqual(totals[2].ingredient.name, "醤油")
        XCTAssertEqual(totals[2].ingredient.unit, "ml")
        XCTAssertEqual(totals[2].totalQuantity, 10)
    }

    func testClearMenuRemovesAssignmentAndTotals() {
        let rice = MenuIngredient(ingredient: Ingredient(name: "ご飯", unit: "杯"), quantity: 2)
        let menu = Menu(name: "ご飯セット", type: .japanese, ingredients: [rice])

        let planRepo = InMemoryPlanRepository(startDate: Date(), endDate: Date())
        let menuRepo = InMemoryMenuRepository(seed: [menu])
        let store = PlanStore(planRepository: planRepo, menuRepository: menuRepo)

        let today = Calendar.current.startOfDay(for: Date())
        store.assign(menu: menu, to: today, slot: .lunch)

        XCTAssertEqual(store.plan.days.first?.lunch?.id, menu.id)
        XCTAssertEqual(store.ingredientTotals().count, 1)

        store.clearMenu(for: today, slot: .lunch)

        XCTAssertNil(store.plan.days.first?.lunch)
        XCTAssertTrue(store.ingredientTotals().isEmpty)
    }
}
