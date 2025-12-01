#if canImport(SwiftUI)
import SwiftUI

struct MenuPickerView: View {
    @ObservedObject var menuStore: MenuStore
    @State private var selectedType: MenuType? = nil
    @State private var selectedTypeSet: MenuTypeSet? = nil
    var onSelect: (Menu) -> Void
    var onClear: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Spacer()
                    Button("未設定にする", action: onClear)
                        .buttonStyle(.bordered)
                }

                Picker("タイプ", selection: Binding(get: { selectedType }, set: { selectedType = $0 })) {
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
                        .buttonStyle(selectedTypeSet == nil ? .borderedProminent : .bordered)

                        ForEach(menuStore.menuTypeSets) { typeSet in
                            Button(action: {
                                if selectedTypeSet?.id == typeSet.id {
                                    selectedTypeSet = nil
                                } else {
                                    selectedTypeSet = typeSet
                                }
                            }) {
                                Text(typeSet.name)
                            }
                            .buttonStyle(selectedTypeSet?.id == typeSet.id ? .borderedProminent : .bordered)
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
#endif
