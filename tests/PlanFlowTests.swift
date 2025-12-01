import Foundation
import XCTest
@testable import select_foods

final class PlanFlowTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testSimulatedManualWalkthrough() {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.date(from: DateComponents(year: 2025, month: 3, day: 1))!
        let end = calendar.date(byAdding: .day, value: 6, to: start)!

        let stirFry = Menu(name: "野菜炒め", type: .japanese, ingredients: [
            MenuIngredient(ingredient: Ingredient(name: "キャベツ", unit: "g"), quantity: 120),
            MenuIngredient(ingredient: Ingredient(name: "醤油", unit: "ml"), quantity: 10)
        ])
        let quickSet = MenuTypeSet(name: "時短", includedTypes: [.western, .italian])

        let planRepository = InMemoryPlanRepository(startDate: start, endDate: end)
        let menuRepository = InMemoryMenuRepository(seed: [stirFry], menuTypes: MenuType.presets, menuTypeSets: [quickSet])
        let planStore = PlanStore(planRepository: planRepository, menuRepository: menuRepository)
        let menuStore = MenuStore(repository: menuRepository)

        guard let initialMenus = waitForMenus(menuStore, where: { !$0.isEmpty }) else {
            XCTFail("Expected initial menus to load")
            return
        }

        let quickIngredients = [
            MenuIngredient(ingredient: Ingredient(name: " パスタ ", unit: " g "), quantity: 150),
            MenuIngredient(ingredient: Ingredient(name: "ベーコン", unit: "枚"), quantity: 2)
        ]
        menuStore.addMenu(name: " 15分カルボナーラ ", type: .italian, ingredients: quickIngredients)

        guard let menus = waitForMenus(menuStore, where: { $0.count == initialMenus.count + 1 }) else {
            XCTFail("Expected quick menu to be added")
            return
        }

        guard let quickMenu = menus.first(where: { $0.name == "15分カルボナーラ" }) else {
            XCTFail("Expected quick menu name to be trimmed")
            return
        }

        let filteredMenus = menuStore.menus(typeSet: quickSet)
        XCTAssertTrue(filteredMenus.contains(where: { $0.id == quickMenu.id }))

        planStore.update(dateRange: start...end)
        planStore.assign(menu: quickMenu, to: start, slot: .lunch)

        let secondDay = calendar.date(byAdding: .day, value: 1, to: start)!
        guard let stirFryMenu = menus.first(where: { $0.name == stirFry.name }) else {
            XCTFail("Expected stir-fry seed menu to remain available")
            return
        }
        planStore.assign(menu: stirFryMenu, to: secondDay, slot: .dinner)

        planStore.update(dateRange: start...secondDay)
        XCTAssertEqual(planStore.plan.days.count, 2)
        XCTAssertEqual(planStore.plan.days.first?.lunch?.id, quickMenu.id)
        XCTAssertEqual(planStore.plan.days.last?.dinner?.name, stirFry.name)
        XCTAssertNil(planStore.plan.days.last?.lunch)

        let totals = planStore.ingredientTotals()
        XCTAssertEqual(totals.count, 4)
        XCTAssertEqual(totals.first(where: { $0.ingredient.name == "パスタ" && $0.ingredient.unit == "g" })?.totalQuantity, 150)
        XCTAssertEqual(totals.first(where: { $0.ingredient.name == "ベーコン" })?.totalQuantity, 2)
        XCTAssertEqual(totals.first(where: { $0.ingredient.name == "キャベツ" })?.totalQuantity, 120)
        XCTAssertEqual(totals.first(where: { $0.ingredient.name == "醤油" })?.totalQuantity, 10)
    }

    private func waitForMenus(
        _ store: MenuStore,
        where predicate: @escaping ([Menu]) -> Bool,
        timeout: TimeInterval = 1
    ) -> [Menu]? {
        let expectation = expectation(description: "menus updated")
        var result: [Menu]?
        store.$menus
            .sink { menus in
                guard predicate(menus) else { return }
                result = menus
                expectation.fulfill()
            }
            .store(in: &cancellables)

        waitForExpectations(timeout: timeout)
        return result
    }
}
