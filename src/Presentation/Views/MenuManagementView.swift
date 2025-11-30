#if canImport(SwiftUI)
import SwiftUI

struct MenuManagementView: View {
    @ObservedObject var menuStore: MenuStore
    @State private var name: String = ""
    @State private var selectedType: MenuType = .japanese
    @State private var ingredientName: String = ""
    @State private var ingredientUnit: String = ""
    @State private var ingredientQuantity: String = ""
    @State private var ingredients: [MenuIngredient] = []

    var body: some View {
        Form {
            Section(header: Text("新規メニュー")) {
                TextField("名前", text: $name)
                Picker("タイプ", selection: $selectedType) {
                    ForEach(menuStore.menuTypes, id: \._self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                VStack(alignment: .leading) {
                    Text("材料")
                    HStack {
                        TextField("材料", text: $ingredientName)
                        TextField("数量", text: $ingredientQuantity)
                            .keyboardType(.decimalPad)
                        TextField("単位", text: $ingredientUnit)
                        Button("追加") { addIngredient() }
                    }
                    ForEach(ingredients, id: \._self) { item in
                        Text("\(item.ingredient.name) \(item.quantity) \(item.ingredient.unit)")
                    }
                }
                Button("保存") { saveMenu() }
                    .disabled(!canSave)
            }

            Section(header: Text("登録済み")) {
                List(menuStore.menus) { menu in
                    VStack(alignment: .leading) {
                        Text(menu.name)
                        Text(menu.type.displayName).font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle("メニュー管理")
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !ingredients.isEmpty && ingredients.allSatisfy { $0.ingredient.isValid }
    }

    private func addIngredient() {
        let trimmedName = ingredientName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUnit = ingredientUnit.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedUnit.isEmpty, let quantity = Double(ingredientQuantity), quantity > 0 else { return }
        let ingredient = Ingredient(name: trimmedName, unit: trimmedUnit)
        ingredients.append(MenuIngredient(ingredient: ingredient, quantity: quantity))
        ingredientName = ""
        ingredientUnit = ""
        ingredientQuantity = ""
    }

    private func saveMenu() {
        menuStore.addMenu(name: name, type: selectedType, ingredients: ingredients)
        name = ""
        ingredients = []
    }
}
#endif
