import SwiftUI

struct ProfileView: View {
    let container: AppContainer

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Palette.accent)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Мой профиль")
                                .font(.headline)
                            Text("Настройки приложения и баланса")
                                .font(.subheadline)
                                .foregroundStyle(Palette.textSecondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("Настройки") {
                    NavigationLink {
                        AnalyticsView(container: container)
                    } label: {
                        Label("Аналитика и история", systemImage: "chart.xyaxis.line")
                    }
                    .accessibilityIdentifier("profile.analytics")

                    NavigationLink {
                        LifeAreasSettingsView(container: container)
                    } label: {
                        Label("Сферы жизни", systemImage: "circle.grid.2x2.fill")
                    }
                    .accessibilityIdentifier("profile.life_areas")
                }

                Section("О приложении") {
                    NavigationLink {
                        DiagnosticsView()
                    } label: {
                        Label("Диагностика", systemImage: "stethoscope")
                    }
                    .accessibilityIdentifier("profile.diagnostics")

                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Label("Политика конфиденциальности", systemImage: "hand.raised.fill")
                    }
                    .accessibilityIdentifier("profile.privacy_policy")

                    LabeledContent("Версия", value: appVersion)
                    Label("Данные хранятся на устройстве", systemImage: "lock.shield")
                        .foregroundStyle(Palette.textSecondary)
                }
            }
            .navigationTitle("Профиль")
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }
}
