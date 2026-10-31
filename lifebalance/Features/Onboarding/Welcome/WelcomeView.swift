import SwiftUI

struct WelcomeView: View {
    @State private var viewModel: WelcomeViewModel
    let onStart: () -> Void

    init(container: AppContainer, onStart: @escaping () -> Void) {
        _viewModel = State(initialValue: container.makeWelcomeViewModel())
        self.onStart = onStart
    }

    private let benefits: [(icon: String, title: String)] = [
        ("target", "Приоритеты"),
        ("timer", "Фокус"),
        ("chart.pie.fill", "Баланс")
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 24)

            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Palette.accent)
                    .accessibilityHidden(true)

                Text("Баланс")
                    .font(.title.bold())
                    .foregroundStyle(Palette.textPrimary)

                Text("Превращай цели в понятные действия и сохраняй баланс")
                    .font(.body)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            HStack(spacing: 24) {
                ForEach(benefits, id: \.title) { benefit in
                    VStack(spacing: 8) {
                        Image(systemName: benefit.icon)
                            .font(.title2)
                            .foregroundStyle(Palette.accent)
                        Text(benefit.title)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Palette.textPrimary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }

            Spacer()

            VStack(spacing: 16) {
                Button("Начать") {
                    if viewModel.start() {
                        onStart()
                    }
                }
                .buttonStyle(.primary())
                .accessibilityIdentifier("onboarding.start")

                Button("Политика конфиденциальности") {
                    viewModel.showPrivacyPolicy = true
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .sheet(isPresented: $viewModel.showPrivacyPolicy) {
            PrivacyPolicyPlaceholderView()
        }
        .appErrorAlert($viewModel.errorMessage)
    }
}

private struct PrivacyPolicyPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text("Здесь будет размещена политика конфиденциальности продукта.")
                    .padding()
            }
            .navigationTitle("Политика конфиденциальности")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}
