import SwiftUI

struct MenuPickerView: View {
    @ObservedObject var menuStore: MenuStore
    @State private var selectedType: MenuType? = nil
    @State private var selectedTypeSet: MenuTypeSet? = nil
    var onSelect: (Menu) -> Void

    var body: some View {
        NavigationStack {
            VStack {
                Picker("タイプ", selection: Binding(get: { selectedType ?? menuStore.menuTypes.first }, set: { selectedType = $0 })) {
                    Text("すべて").tag(MenuType?.none)
                    ForEach(menuStore.menuTypes, id: \._self) { type in
                        Text(type.displayName).tag(MenuType?.some(type))
                    }
                }
                .pickerStyle(.segmented)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Button(action: { selectedTypeSet = nil }) {
                            Text("全セット")
                        }
                        ForEach(menuStore.menuTypeSets) { typeSet in
                            Button(action: { selectedTypeSet = typeSet }) {
                                Text(typeSet.name)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }

                List(menuStore.menus(filter: selectedType, typeSet: selectedTypeSet)) { menu in
                    Button(action: { onSelect(menu) }) {
                        VStack(alignment: .leading) {
                            Text(menu.name).font(.headline)
                            Text(menu.type.displayName).font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("メニュー選択")
            .padding()
        }
    }
}
