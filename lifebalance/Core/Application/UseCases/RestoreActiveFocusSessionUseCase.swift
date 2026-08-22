import Foundation

/// Restores the persisted timer after navigation or an application restart.
/// A running session whose planned time has elapsed is completed immediately,
/// so stale data cannot block all future focus sessions.
@MainActor
final class RestoreActiveFocusSessionUseCase {
    private let focusSessionRepository: FocusSessionRepository
    private let finishFocusSessionUseCase: FinishFocusSessionUseCase

    init(
        focusSessionRepository: FocusSessionRepository,
        finishFocusSessionUseCase: FinishFocusSessionUseCase
    ) {
        self.focusSessionRepository = focusSessionRepository
        self.finishFocusSessionUseCase = finishFocusSessionUseCase
    }

    func execute(at now: Date = .now) throws -> FocusSession? {
        guard let session = try focusSessionRepository.fetchActiveSession() else {
            return nil
        }

        if session.status == .running && remainingSeconds(for: session, at: now) <= 0 {
            try finishFocusSessionUseCase.execute(session, completeTask: false, endedAt: now)
        }

        return session
    }

    private func remainingSeconds(for session: FocusSession, at now: Date) -> TimeInterval {
        let elapsed = now.timeIntervalSince(session.startAt) - Double(session.pausedSeconds)
        return Double(session.plannedSeconds) - elapsed
    }
}
