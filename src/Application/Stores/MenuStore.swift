import Foundation
import Combine

public final class MenuStore: ObservableObject {
    @Published public private(set) var menus: [Menu] = []
    public private(set) var menuTypes: [MenuType]
    public private(set) var menuTypeSets: [MenuTypeSet]

    private let repository: MenuRepository
    private var cancellables: Set<AnyCancellable> = []

    public init(repository: MenuRepository) {
        self.repository = repository
        self.menuTypes = repository.menuTypes
        self.menuTypeSets = repository.menuTypeSets
        repository.menus()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.menus = $0 }
            .store(in: &cancellables)
    }

    public func menus(filter type: MenuType? = nil, typeSet: MenuTypeSet? = nil) -> [Menu] {
        menus.filter { menu in
            let matchesType = type.map { $0 == menu.type } ?? true
            let matchesSet: Bool
            if let set = typeSet {
                matchesSet = set.includedTypes.contains(menu.type)
            } else {
                matchesSet = true
            }
            return matchesType && matchesSet
        }
    }

    public func addMenu(name: String, type: MenuType, ingredients: [MenuIngredient]) {
        let menu = Menu(name: name, type: type, ingredients: ingredients)
        repository.add(menu: menu)
    }
}
