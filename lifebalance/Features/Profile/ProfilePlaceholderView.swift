import SwiftUI

struct ProfilePlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Профиль",
                systemImage: "person.crop.circle",
                description: Text("Уровни, статистика и настройки появятся здесь позже.")
            )
            .navigationTitle("Профиль")
        }
    }
}
