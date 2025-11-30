import SwiftUI

struct IngredientSummaryView: View {
    var totals: [IngredientTotal]

    var body: some View {
        VStack(alignment: .leading) {
            Text("買い物リスト").font(.headline)
            List(totals) { total in
                HStack {
                    Text(total.ingredient.name)
                    Spacer()
                    Text("\(total.totalQuantity, specifier: "%.1f") \(total.ingredient.unit)")
                }
            }
            .frame(maxHeight: 200)
        }
    }
}
