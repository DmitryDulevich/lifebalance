import Foundation

@MainActor
final class StartFocusSessionUseCase {
    enum ActiveSessionError: LocalizedError {
        case alreadyRunning

        var errorDescription: String? {
            "Уже есть активная фокус-сессия. Завершите её перед началом новой."
        }
    }

    private let focusSessionRepository: FocusSessionRepository

    init(focusSessionRepository: FocusSessionRepository) {
        self.focusSessionRepository = focusSessionRepository
    }

    @discardableResult
    func execute(task: TaskItem?, plannedSeconds: Int) throws -> FocusSession {
        guard try focusSessionRepository.fetchActiveSession() == nil else {
            throw ActiveSessionError.alreadyRunning
        }
        let session = FocusSession(plannedSeconds: plannedSeconds, task: task)
        try focusSessionRepository.insert(session)
        return session
    }
}
