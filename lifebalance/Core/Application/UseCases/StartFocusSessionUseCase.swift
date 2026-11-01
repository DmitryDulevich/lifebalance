import Foundation

@MainActor
final class StartFocusSessionUseCase {
    enum ActiveSessionError: LocalizedError {
        case alreadyRunning
        case invalidDuration

        var errorDescription: String? {
            switch self {
            case .alreadyRunning:
                return String(localized: "Уже есть активная фокус-сессия. Завершите её перед началом новой.")
            case .invalidDuration:
                return String(localized: "Продолжительность фокус-сессии должна быть от 1 минуты до 24 часов.")
            }
        }
    }

    private let focusSessionRepository: FocusSessionRepository

    init(focusSessionRepository: FocusSessionRepository) {
        self.focusSessionRepository = focusSessionRepository
    }

    @discardableResult
    func execute(task: TaskItem?, plannedSeconds: Int) throws -> FocusSession {
        guard (60...86_400).contains(plannedSeconds) else {
            throw ActiveSessionError.invalidDuration
        }
        guard try focusSessionRepository.fetchActiveSession() == nil else {
            throw ActiveSessionError.alreadyRunning
        }
        let session = FocusSession(plannedSeconds: plannedSeconds, task: task)
        try focusSessionRepository.insert(session)
        return session
    }
}
