import SwiftUI

struct PeriodSelectionView: View {
    @Binding var range: ClosedRange<Date>
    var onChange: (ClosedRange<Date>) -> Void

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("期間選択").font(.headline)
            HStack {
                DatePicker("開始", selection: Binding(get: { range.lowerBound }, set: { new in
                    range = new...range.upperBound
                    onChange(range)
                }), displayedComponents: .date)
                DatePicker("終了", selection: Binding(get: { range.upperBound }, set: { new in
                    range = range.lowerBound...max(new, range.lowerBound)
                    onChange(range)
                }), displayedComponents: .date)
            }
            Text("選択中: \(dateFormatter.string(from: range.lowerBound)) - \(dateFormatter.string(from: range.upperBound))")
                .font(.subheadline)
        }
        .padding(.vertical)
    }
}
