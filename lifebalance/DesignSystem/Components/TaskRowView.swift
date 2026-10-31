import SwiftUI

struct TaskRowView: View {
    let title: String
    let subtitle: String
    let ringColor: Color
    let isCompleted: Bool
    var onToggle: () -> Void
    var onPlay: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? ringColor : Color.clear)
                    Circle()
                        .strokeBorder(ringColor, lineWidth: isCompleted ? 0 : 2)
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 24, height: 24)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("task.toggle.\(title)")

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                    .strikethrough(isCompleted)
                    .lineLimit(2)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.textSecondary)
            }

            Spacer(minLength: 0)

            if let onPlay, !isCompleted {
                Button(action: onPlay) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.accent)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Palette.softAccentBackground))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("task.play.\(title)")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Palette.cardBackground)
        )
        .opacity(isCompleted ? 0.6 : 1)
    }
}
