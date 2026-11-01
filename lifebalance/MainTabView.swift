import SwiftUI

struct MainTabView: View {
    let container: AppContainer

    @State private var dataRevision = 0
    @State private var showQuickAddMenu = false
    @State private var quickAddTask = false
    @State private var quickAddGoal = false
    @State private var quickAddLifeAreas: [LifeArea] = []
    @State private var quickAddGoals: [Goal] = []
    @State private var errorMessage: String?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView {
                TodayView(container: container, refreshToken: dataRevision)
                    .tabItem { Label("Сегодня", systemImage: "sun.max.fill") }

                TasksView(container: container, refreshToken: dataRevision)
                    .tabItem { Label("Задачи", systemImage: "checklist") }

                GoalsView(container: container, refreshToken: dataRevision)
                    .tabItem { Label("Цели", systemImage: "target") }

                BalanceView(container: container)
                    .tabItem { Label("Баланс", systemImage: "chart.pie") }

                ProfileView(container: container)
                    .tabItem { Label("Профиль", systemImage: "person.crop.circle") }
            }
            .tint(Palette.accent)

            Button {
                prepareQuickAddMenu()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Palette.accent))
                    .shadow(color: .black.opacity(0.25), radius: 12, y: 8)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 78)
        }
        .confirmationDialog("Добавить", isPresented: $showQuickAddMenu, titleVisibility: .hidden) {
            Button("Новая задача") { quickAddTask = true }
            Button("Новая цель") { quickAddGoal = true }
            Button("Отмена", role: .cancel) {}
        }
        .sheet(isPresented: $quickAddTask) {
            TaskFormView(
                container: container,
                lifeAreas: quickAddLifeAreas,
                goals: quickAddGoals,
                editingTask: nil,
                onSaved: { dataRevision += 1 }
            )
        }
        .sheet(isPresented: $quickAddGoal) {
            GoalFormView(
                container: container,
                lifeAreas: quickAddLifeAreas,
                onSaved: { dataRevision += 1 }
            )
        }
        .appErrorAlert($errorMessage, title: String(localized: "Не удалось загрузить данные"))
    }

    private func prepareQuickAddMenu() {
        do {
            let lifeAreas = try container.lifeAreaRepository.fetchActiveAreas()
            let goals = try container.goalRepository.fetchActive()

            quickAddLifeAreas = lifeAreas
            quickAddGoals = goals
            showQuickAddMenu = true
        } catch {
            AppLogger.error(error, context: "quick_add.prepare")
            errorMessage = error.localizedDescription
        }
    }
}
