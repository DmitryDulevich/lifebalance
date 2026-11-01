import SwiftUI

struct FocusTimerView: View {
    @State private var viewModel: FocusTimerViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    init(task: TaskItem?, plannedSeconds: Int, container: AppContainer) {
        _viewModel = State(initialValue: container.makeFocusTimerViewModel(task: task, plannedSeconds: plannedSeconds))
    }

    var body: some View {
        ZStack {
            ScreenBackground()

            VStack {
                HStack {
                    Button {
                        if viewModel.cancel() {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Palette.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Palette.softAccentBackground))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()

                VStack(spacing: 26) {
                    VStack(spacing: 6) {
                        Text("ФОКУС-СЕССИЯ")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(0.5)
                            .foregroundStyle(Palette.textSecondary)
                            .accessibilityIdentifier("focus.title")

                        Text(viewModel.task?.title ?? "Свободная сессия")
                            .font(.system(size: 21, weight: .bold))
                            .foregroundStyle(Palette.textPrimary)
                            .multilineTextAlignment(.center)

                        if let subtitle {
                            Text(subtitle)
                                .font(.system(size: 14))
                                .foregroundStyle(Palette.textSecondary)
                        }
                    }
                    .padding(.horizontal, 24)

                    ZStack {
                        CircularProgressRing(progress: viewModel.progress, lineWidth: 10)
                            .frame(width: 230, height: 230)

                        VStack(spacing: 2) {
                            Text(formattedTime)
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(Palette.textPrimary)
                            Text(viewModel.statusText)
                                .font(.system(size: 13))
                                .foregroundStyle(Palette.textSecondary)
                        }
                    }

                    HStack(spacing: 14) {
                        Button {
                            if viewModel.didFinish {
                                dismiss()
                            } else {
                                viewModel.togglePause()
                            }
                        } label: {
                            Image(systemName: viewModel.didFinish ? "checkmark" : (viewModel.isPaused ? "play.fill" : "pause.fill"))
                                .font(.system(size: 20))
                                .foregroundStyle(Palette.textPrimary)
                                .frame(width: 64, height: 64)
                                .background(Circle().fill(Palette.softAccentBackground))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("focus.pause")

                        Button {
                            if viewModel.didFinish || viewModel.finish() {
                                dismiss()
                            }
                        } label: {
                            Text(viewModel.didFinish ? "Готово" : "Завершить")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 30)
                                .frame(height: 64)
                                .background(Capsule().fill(Palette.accent))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("focus.finish")
                    }

                }

                Spacer()
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            viewModel.start()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.applicationDidBecomeActive()
            }
        }
        .appErrorAlert($viewModel.errorMessage)
    }

    private var subtitle: String? {
        guard let task = viewModel.task else { return nil }
        var parts: [String] = []
        if let area = task.lifeArea { parts.append(area.name) }
        if let goal = task.goal { parts.append(goal.title) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private var formattedTime: String {
        let minutes = viewModel.displaySeconds / 60
        let seconds = viewModel.displaySeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
