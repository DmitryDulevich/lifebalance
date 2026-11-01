import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var showsCloseButton = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Редакция от 1 ноября 2026 года")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                policySection(
                    title: "Какие данные использует приложение",
                    text: "Баланс хранит введённые вами цели, задачи, сферы жизни, оценки баланса и историю фокус-сессий локально на вашем устройстве. Приложение не создаёт учётную запись и не отправляет эти данные разработчику."
                )

                policySection(
                    title: "Аналитика и передача третьим лицам",
                    text: "Приложение не использует рекламные системы, трекеры, сторонние аналитические SDK и не продаёт пользовательские данные. Вся показанная в приложении аналитика вычисляется на устройстве."
                )

                policySection(
                    title: "Локальные уведомления",
                    text: "С вашего разрешения приложение создаёт локальное уведомление о завершении фокус-сессии. Для этого данные не отправляются на сервер. Разрешение можно отозвать в системных настройках iOS."
                )

                policySection(
                    title: "Хранение и удаление",
                    text: "Данные хранятся на устройстве, пока вы изменяете, архивируете или удаляете их средствами приложения. Все локальные данные можно удалить, удалив приложение с устройства. Системная резервная копия устройства может содержать данные приложения в соответствии с настройками и политикой Apple."
                )

                policySection(
                    title: "Изменения политики",
                    text: "Если способы обработки данных изменятся, политика будет обновлена до выпуска соответствующей версии приложения. Актуальная версия политики также должна быть доступна по ссылке на странице приложения в App Store."
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .navigationTitle("Конфиденциальность")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCloseButton {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }

    private func policySection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(text)
                .font(.body)
                .foregroundStyle(Palette.textSecondary)
        }
    }
}
