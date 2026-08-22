import SwiftUI

struct HeroFocusCard: View {
    let title: String
    let subtitle: String
    var onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("ГЛАВНЫЙ ФОКУС")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.white.opacity(0.8))

            Text(title)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 2)
                .lineLimit(2)

            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.top, 2)

            Button(action: onStart) {
                Text("Начать фокус →")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 11)
                    .background(Capsule().fill(.white.opacity(0.22)))
            }
            .buttonStyle(.plain)
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: Palette.heroGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
