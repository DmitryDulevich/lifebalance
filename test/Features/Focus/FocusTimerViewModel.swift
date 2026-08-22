import Foundation
import Observation

@Observable
@MainActor
final class FocusTimerViewModel {
    let task: TaskItem?
    let plannedSeconds: Int

    private(set) var session: FocusSession?
    private(set) var displaySeconds: Int
    var errorMessage: String?
    var didFinish = false

    private var timer: Timer?
    private var pauseStartedAt: Date?

    private let startFocusSessionUseCase: StartFocusSessionUseCase
    private let finishFocusSessionUseCase: FinishFocusSessionUseCase
    private let focusSessionRepository: FocusSessionRepository

    init(task: TaskItem?, plannedSeconds: Int, container: AppContainer) {
        self.task = task
        self.plannedSeconds = plannedSeconds
        self.displaySeconds = plannedSeconds
        self.startFocusSessionUseCase = container.startFocusSessionUseCase
        self.finishFocusSessionUseCase = container.finishFocusSessionUseCase
        self.focusSessionRepository = container.focusSessionRepository
    }

    var isPaused: Bool {
        session?.status == .paused
    }

    /// Remaining-time fraction (1 = just started, 0 = time's up) — the ring
    /// depletes as the session progresses, matching the reference design.
    var progress: Double {
        guard plannedSeconds > 0 else { return 0 }
        return Double(displaySeconds) / Double(plannedSeconds)
    }

    func start() {
        do {
            session = try startFocusSessionUseCase.execute(task: task, plannedSeconds: plannedSeconds)
            beginTicking()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func togglePause() {
        guard let session else { return }
        if session.status == .running {
            session.status = .paused
            pauseStartedAt = .now
            timer?.invalidate()
        } else if session.status == .paused {
            if let pauseStartedAt {
                session.pausedSeconds += Int(Date.now.timeIntervalSince(pauseStartedAt).rounded())
            }
            pauseStartedAt = nil
            session.status = .running
            beginTicking()
        }
        try? focusSessionRepository.save()
    }

    func finish() {
        guard let session else { return }
        timer?.invalidate()
        do {
            try finishFocusSessionUseCase.execute(session, completeTask: false)
            didFinish = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancel() {
        timer?.invalidate()
        guard let session else { return }
        try? finishFocusSessionUseCase.execute(session, completeTask: false, cancelled: true)
    }

    private func beginTicking() {
        timer?.invalidate()
        let newTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
        tick()
    }

    private func tick() {
        guard let session, session.status == .running else { return }
        let elapsed = Date.now.timeIntervalSince(session.startAt) - Double(session.pausedSeconds)
        let remaining = Double(session.plannedSeconds) - elapsed
        displaySeconds = max(0, Int(remaining.rounded()))
        if remaining <= 0 {
            timer?.invalidate()
        }
    }
}
