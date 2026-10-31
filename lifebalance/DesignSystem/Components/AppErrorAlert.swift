import SwiftUI

extension View {
    func appErrorAlert(
        _ message: Binding<String?>,
        title: String = "Не удалось выполнить действие"
    ) -> some View {
        alert(
            title,
            isPresented: Binding(
                get: { message.wrappedValue != nil },
                set: { if !$0 { message.wrappedValue = nil } }
            )
        ) {
            Button("ОК", role: .cancel) {
                message.wrappedValue = nil
            }
        } message: {
            Text(message.wrappedValue ?? "Неизвестная ошибка")
        }
    }
}
