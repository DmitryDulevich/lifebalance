import SwiftUI

/// A 1–10 satisfaction rating control with no pre-selected value.
struct RatingScaleView: View {
    @Binding var value: Int?
    var tint: Color = Palette.accent

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(1...10, id: \.self) { number in
                Button {
                    value = (value == number) ? nil : number
                } label: {
                    Text("\(number)")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(
                            Circle()
                                .fill(value == number ? tint : tint.opacity(0.12))
                        )
                        .foregroundStyle(value == number ? .white : tint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Оценка \(number) из 10")
                .accessibilityAddTraits(value == number ? [.isSelected] : [])
            }
        }
    }
}
