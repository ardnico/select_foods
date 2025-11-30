import Foundation
import XCTest
@testable import select_foods

final class MenuStoreTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testFiltersMenusByTypeAndTypeSet() {
        let japanese = Menu(name: "照り焼き", type: .japanese, ingredients: [
            MenuIngredient(ingredient: Ingredient(name: "鶏肉", unit: "g"), quantity: 200)
        ])
        let western = Menu(name: "ハンバーグ", type: .western, ingredients: [
            MenuIngredient(ingredient: Ingredient(name: "牛ひき肉", unit: "g"), quantity: 250)
        ])
        let italian = Menu(name: "カルボナーラ", type: .italian, ingredients: [
            MenuIngredient(ingredient: Ingredient(name: "パスタ", unit: "g"), quantity: 180)
        ])
        let chinese = Menu(name: "麻婆豆腐", type: .chinese, ingredients: [
            MenuIngredient(ingredient: Ingredient(name: "豆腐", unit: "丁"), quantity: 2)
        ])
        let westernSet = MenuTypeSet(name: "洋食系", includedTypes: [.western, .italian])

        let repository = InMemoryMenuRepository(seed: [japanese, western, italian, chinese], menuTypeSets: [westernSet])
        let store = MenuStore(repository: repository)

        guard let menus = waitForMenus(store, where: { !$0.isEmpty }) else {
            XCTFail("Expected menus to load")
            return
        }
        XCTAssertEqual(menus.count, 4)

        let japaneseOnly = store.menus(filter: .japanese)
        XCTAssertEqual(japaneseOnly.count, 1)
        XCTAssertEqual(japaneseOnly.first?.name, japanese.name)

        let westernFamily = store.menus(typeSet: westernSet)
        XCTAssertEqual(westernFamily.count, 2)
        XCTAssertEqual(Set(westernFamily.map { $0.name }), Set([western.name, italian.name]))

        let italianFromSet = store.menus(filter: .italian, typeSet: westernSet)
        XCTAssertEqual(italianFromSet.count, 1)
        XCTAssertEqual(italianFromSet.first?.name, italian.name)
    }

    func testAddMenuTrimsNameAndSkipsInvalidIngredients() {
        let repository = InMemoryMenuRepository(seed: [], menuTypes: MenuType.presets, menuTypeSets: [])
        let store = MenuStore(repository: repository)

        XCTAssertNil(waitForMenus(store, where: { !$0.isEmpty }, timeout: 0.2, expectEvent: false))

        store.addMenu(name: "   ", type: MenuType.japanese, ingredients: [])
        XCTAssertNil(waitForMenus(store, where: { !$0.isEmpty }, timeout: 0.2, expectEvent: false))

        let ingredients = [
            MenuIngredient(ingredient: Ingredient(name: "  ", unit: "g"), quantity: 100),
            MenuIngredient(ingredient: Ingredient(name: "キャベツ", unit: " g "), quantity: 0),
            MenuIngredient(ingredient: Ingredient(name: "キャベツ", unit: "g"), quantity: 1)
        ]
        store.addMenu(name: "  野菜炒め  ", type: MenuType.japanese, ingredients: ingredients)

        guard let menus = waitForMenus(store, where: { !$0.isEmpty }) else {
            XCTFail("Expected valid menu to be added")
            return
        }
        XCTAssertEqual(menus.count, 1)
        XCTAssertEqual(menus.first?.name, "野菜炒め")
        XCTAssertEqual(menus.first?.ingredients.count, 1)
        XCTAssertEqual(menus.first?.ingredients.first?.quantity, 1)
    }

    private func waitForMenus(
        _ store: MenuStore,
        where predicate: @escaping ([Menu]) -> Bool,
        timeout: TimeInterval = 1,
        expectEvent: Bool = true
    ) -> [Menu]? {
        let expectation = expectation(description: "menus updated")
        expectation.isInverted = !expectEvent
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
