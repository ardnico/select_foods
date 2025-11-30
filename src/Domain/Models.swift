import Foundation

public struct Ingredient: Codable, Hashable {
    public var name: String
    public var unit: String

    public init(name: String, unit: String) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.unit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var isValid: Bool {
        !name.isEmpty && !unit.isEmpty
    }
}

public struct MenuIngredient: Codable, Hashable {
    public var ingredient: Ingredient
    public var quantity: Double

    public init(ingredient: Ingredient, quantity: Double) {
        self.ingredient = ingredient
        self.quantity = quantity
    }

    public var isValid: Bool {
        ingredient.isValid && quantity > 0
    }
}

public enum MenuType: Codable, Hashable, CaseIterable {
    case japanese
    case western
    case chinese
    case italian
    case other(String)

    public var displayName: String {
        switch self {
        case .japanese: return "和食"
        case .western: return "洋食"
        case .chinese: return "中華"
        case .italian: return "イタリアン"
        case .other(let name): return name
        }
    }

    public static var presets: [MenuType] {
        [.japanese, .western, .chinese, .italian]
    }

    enum CodingKeys: String, CodingKey {
        case base
        case associated
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .japanese:
            try container.encode("japanese", forKey: .base)
        case .western:
            try container.encode("western", forKey: .base)
        case .chinese:
            try container.encode("chinese", forKey: .base)
        case .italian:
            try container.encode("italian", forKey: .base)
        case .other(let name):
            try container.encode("other", forKey: .base)
            try container.encode(name, forKey: .associated)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let base = try container.decode(String.self, forKey: .base)
        switch base {
        case "japanese": self = .japanese
        case "western": self = .western
        case "chinese": self = .chinese
        case "italian": self = .italian
        case "other":
            let name = try container.decode(String.self, forKey: .associated)
            self = .other(name)
        default:
            self = .other(base)
        }
    }
}

public struct MenuTypeSet: Codable, Hashable, Identifiable {
    public var id: UUID
    public var name: String
    public var includedTypes: [MenuType]

    public init(id: UUID = UUID(), name: String, includedTypes: [MenuType]) {
        self.id = id
        self.name = name
        self.includedTypes = includedTypes
    }
}

public struct Menu: Codable, Hashable, Identifiable {
    public var id: UUID
    public var name: String
    public var type: MenuType
    public var ingredients: [MenuIngredient]

    public init(id: UUID = UUID(), name: String, type: MenuType, ingredients: [MenuIngredient]) {
        self.id = id
        self.name = name
        self.type = type
        self.ingredients = ingredients
    }

    public var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty &&
        !ingredients.isEmpty &&
        ingredients.allSatisfy { $0.isValid }
    }

    public static var sampleMenus: [Menu] {
        return [
            Menu(name: "照り焼きチキン", type: .japanese, ingredients: [
                MenuIngredient(ingredient: Ingredient(name: "鶏もも肉", unit: "g"), quantity: 400),
                MenuIngredient(ingredient: Ingredient(name: "醤油", unit: "ml"), quantity: 30),
                MenuIngredient(ingredient: Ingredient(name: "みりん", unit: "ml"), quantity: 30)
            ]),
            Menu(name: "パスタ", type: .italian, ingredients: [
                MenuIngredient(ingredient: Ingredient(name: "パスタ", unit: "g"), quantity: 200),
                MenuIngredient(ingredient: Ingredient(name: "オリーブオイル", unit: "ml"), quantity: 20)
            ]),
            Menu(name: "サラダ", type: .western, ingredients: [
                MenuIngredient(ingredient: Ingredient(name: "レタス", unit: "g"), quantity: 150),
                MenuIngredient(ingredient: Ingredient(name: "ドレッシング", unit: "ml"), quantity: 30)
            ])
        ]
    }
}

public struct PlanDay: Codable, Hashable, Identifiable {
    public var id: UUID
    public var date: Date
    public var lunch: Menu?
    public var dinner: Menu?

    public init(id: UUID = UUID(), date: Date, lunch: Menu? = nil, dinner: Menu? = nil) {
        self.id = id
        self.date = date
        self.lunch = lunch
        self.dinner = dinner
    }
}

public struct Plan: Codable, Hashable {
    public var startDate: Date
    public var endDate: Date
    public var days: [PlanDay]

    public init(startDate: Date, endDate: Date, days: [PlanDay]) {
        self.startDate = startDate
        self.endDate = endDate
        self.days = days
    }
}

public struct IngredientTotal: Hashable, Identifiable {
    public var id: UUID
    public var ingredient: Ingredient
    public var totalQuantity: Double

    public init(id: UUID = UUID(), ingredient: Ingredient, totalQuantity: Double) {
        self.id = id
        self.ingredient = ingredient
        self.totalQuantity = totalQuantity
    }
}

public enum MealSlot {
    case lunch
    case dinner
}
