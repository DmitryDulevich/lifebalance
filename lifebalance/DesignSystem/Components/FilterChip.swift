import SwiftUI

/// A pill chip used for the sphere legend row (no action) and for the
/// tappable filter row on the Tasks screen (with action + active state).
struct FilterChip: View {
    let label: String
    var dotColor: Color?
    var isActive: Bool = false
    var action: (() -> Void)?

    var body: some View {
        if let action {
            Button(action: action) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: 6) {
            if let dotColor {
                Circle()
                    .fill(dotColor)
                    .frame(width: 7, height: 7)
            }
            Text(label)
                .font(.system(size: 12, weight: .semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule().fill(isActive ? Palette.accent : Palette.cardBackground)
        )
        .foregroundStyle(isActive ? .white : Palette.textPrimary)
    }
}
