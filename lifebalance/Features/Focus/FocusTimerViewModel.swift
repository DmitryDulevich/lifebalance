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

    private var tickingTask: Task<Void, Never>?
    private let startFocusSessionUseCase: StartFocusSessionUseCase
    private let finishFocusSessionUseCase: FinishFocusSessionUseCase
    private let restoreActiveFocusSessionUseCase: RestoreActiveFocusSessionUseCase
    private let focusSessionRepository: FocusSessionRepository

    init(task: TaskItem?, plannedSeconds: Int, container: AppContainer) {
        self.task = task
        self.plannedSeconds = plannedSeconds
        self.displaySeconds = plannedSeconds
        self.startFocusSessionUseCase = container.startFocusSessionUseCase
        self.finishFocusSessionUseCase = container.finishFocusSessionUseCase
        self.restoreActiveFocusSessionUseCase = container.restoreActiveFocusSessionUseCase
        self.focusSessionRepository = container.focusSessionRepository
    }

    var isPaused: Bool {
        session?.status == .paused
    }

    var statusText: String {
        if didFinish { return "Сессия завершена" }
        return isPaused ? "На паузе" : "Идёт сессия"
    }

    /// Remaining-time fraction (1 = just started, 0 = time's up) — the ring
    /// depletes as the session progresses, matching the reference design.
    var progress: Double {
        guard plannedSeconds > 0 else { return 0 }
        return Double(displaySeconds) / Double(plannedSeconds)
    }

    func start() {
        guard session == nil, !didFinish else { return }
        do {
            if let activeSession = try restoreActiveFocusSessionUseCase.execute() {
                session = activeSession
                displaySeconds = remainingSeconds(for: activeSession)
                if activeSession.status == .completed {
                    didFinish = true
                } else if activeSession.status == .running {
                    beginTicking()
                }
            } else {
                session = try startFocusSessionUseCase.execute(task: task, plannedSeconds: plannedSeconds)
                beginTicking()
            }
        } catch {
            AppLogger.error(error, context: "focus.start")
            errorMessage = error.localizedDescription
        }
    }

    func togglePause() {
        guard let session else { return }
        if session.status == .running {
            session.status = .paused
            session.pausedAt = .now
            stopTicking()
        } else if session.status == .paused {
            if let pausedAt = session.pausedAt {
                session.pausedSeconds += max(0, Int(Date.now.timeIntervalSince(pausedAt).rounded()))
            }
            session.pausedAt = nil
            session.status = .running
            beginTicking()
        }
        do {
            try focusSessionRepository.save()
        } catch {
            AppLogger.error(error, context: "focus.toggle_pause")
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func finish() -> Bool {
        guard let session else { return false }
        stopTicking()
        do {
            try finishFocusSessionUseCase.execute(session, completeTask: false)
            didFinish = true
            displaySeconds = 0
            return true
        } catch {
            AppLogger.error(error, context: "focus.finish")
            errorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func cancel() -> Bool {
        stopTicking()
        guard let session else { return true }
        guard !didFinish else { return true }
        do {
            try finishFocusSessionUseCase.execute(session, completeTask: false, cancelled: true)
            return true
        } catch {
            AppLogger.error(error, context: "focus.cancel")
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func beginTicking() {
        stopTicking()
        tick()
        tickingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self?.tick()
            }
        }
    }

    private func stopTicking() {
        tickingTask?.cancel()
        tickingTask = nil
    }

    private func tick() {
        guard let session, session.status == .running else { return }
        displaySeconds = remainingSeconds(for: session)
        if displaySeconds <= 0 {
            stopTicking()
            _ = finish()
        }
    }

    private func remainingSeconds(for session: FocusSession, at now: Date = .now) -> Int {
        let effectiveNow = session.status == .paused ? (session.pausedAt ?? now) : now
        let elapsed = effectiveNow.timeIntervalSince(session.startAt) - Double(session.pausedSeconds)
        return max(0, Int((Double(session.plannedSeconds) - elapsed).rounded()))
    }
}
