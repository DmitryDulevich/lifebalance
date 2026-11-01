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
    private let notificationScheduler: FocusNotificationScheduling

    init(
        task: TaskItem?,
        plannedSeconds: Int,
        startFocusSessionUseCase: StartFocusSessionUseCase,
        finishFocusSessionUseCase: FinishFocusSessionUseCase,
        restoreActiveFocusSessionUseCase: RestoreActiveFocusSessionUseCase,
        focusSessionRepository: FocusSessionRepository,
        notificationScheduler: FocusNotificationScheduling
    ) {
        self.task = task
        self.plannedSeconds = plannedSeconds
        self.displaySeconds = plannedSeconds
        self.startFocusSessionUseCase = startFocusSessionUseCase
        self.finishFocusSessionUseCase = finishFocusSessionUseCase
        self.restoreActiveFocusSessionUseCase = restoreActiveFocusSessionUseCase
        self.focusSessionRepository = focusSessionRepository
        self.notificationScheduler = notificationScheduler
    }

    var isPaused: Bool {
        session?.status == .paused
    }

    var statusText: String {
        if didFinish { return String(localized: "Сессия завершена") }
        return isPaused ? String(localized: "На паузе") : String(localized: "Идёт сессия")
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
                    scheduleCompletionNotification()
                }
            } else {
                session = try startFocusSessionUseCase.execute(task: task, plannedSeconds: plannedSeconds)
                beginTicking()
                scheduleCompletionNotification()
            }
            errorMessage = nil
        } catch {
            AppLogger.error(error, context: "focus.start")
            errorMessage = error.localizedDescription
        }
    }

    func togglePause() {
        guard let session else { return }
        let previousStatus = session.status
        let previousPausedAt = session.pausedAt
        let previousPausedSeconds = session.pausedSeconds

        if session.status == .running {
            session.status = .paused
            session.pausedAt = .now
        } else if session.status == .paused {
            if let pausedAt = session.pausedAt {
                session.pausedSeconds += max(0, Int(Date.now.timeIntervalSince(pausedAt).rounded()))
            }
            session.pausedAt = nil
            session.status = .running
        }
        do {
            try focusSessionRepository.save()
            errorMessage = nil
            if session.status == .paused {
                stopTicking()
                notificationScheduler.cancelCompletion(sessionID: session.id)
            } else if session.status == .running {
                beginTicking()
                scheduleCompletionNotification()
            }
        } catch {
            session.status = previousStatus
            session.pausedAt = previousPausedAt
            session.pausedSeconds = previousPausedSeconds
            if session.status == .running {
                beginTicking()
                scheduleCompletionNotification()
            } else {
                stopTicking()
                notificationScheduler.cancelCompletion(sessionID: session.id)
            }
            AppLogger.error(error, context: "focus.toggle_pause")
            errorMessage = error.localizedDescription
        }
    }

    func applicationDidBecomeActive() {
        guard session?.status == .running, !didFinish else { return }
        tick()
        scheduleCompletionNotification()
    }

    @discardableResult
    func finish(endedAt: Date = .now) -> Bool {
        guard let session else { return false }
        stopTicking()
        notificationScheduler.cancelCompletion(sessionID: session.id)
        do {
            try finishFocusSessionUseCase.execute(
                session,
                completeTask: false,
                endedAt: endedAt
            )
            didFinish = true
            displaySeconds = 0
            errorMessage = nil
            return true
        } catch {
            if session.status == .running {
                beginTicking()
                scheduleCompletionNotification()
            }
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
        notificationScheduler.cancelCompletion(sessionID: session.id)
        do {
            try finishFocusSessionUseCase.execute(session, completeTask: false, cancelled: true)
            errorMessage = nil
            return true
        } catch {
            if session.status == .running {
                beginTicking()
                scheduleCompletionNotification()
            }
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
            _ = finish(endedAt: scheduledEndDate(for: session))
        }
    }

    private func scheduleCompletionNotification() {
        guard let session, session.status == .running, !didFinish else { return }
        let remaining = remainingSeconds(for: session)
        guard remaining > 0 else { return }
        notificationScheduler.scheduleCompletion(
            sessionID: session.id,
            taskTitle: session.taskTitleSnapshot ?? session.task?.title,
            after: TimeInterval(remaining)
        )
    }

    private func remainingSeconds(for session: FocusSession, at now: Date = .now) -> Int {
        let effectiveNow = session.status == .paused ? (session.pausedAt ?? now) : now
        let elapsed = effectiveNow.timeIntervalSince(session.startAt) - Double(session.pausedSeconds)
        return max(0, Int((Double(session.plannedSeconds) - elapsed).rounded()))
    }

    private func scheduledEndDate(for session: FocusSession) -> Date {
        session.startAt.addingTimeInterval(
            TimeInterval(session.plannedSeconds + session.pausedSeconds)
        )
    }
}
