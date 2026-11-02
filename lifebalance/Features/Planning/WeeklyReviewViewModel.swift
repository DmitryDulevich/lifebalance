import Foundation
import Observation

@Observable
@MainActor
final class WeeklyReviewViewModel {
    var report: WeeklyReviewReport?
    var history: [WeeklyReview] = []
    var selectedTaskIDs: Set<UUID> = []
    var note = ""
    var priorities = ""
    var didSave = false
    var errorMessage: String?

    private let buildUseCase: BuildWeeklyReviewUseCase
    private let reviewRepository: WeeklyReviewRepository
    private let rescheduleTasksUseCase: RescheduleTasksUseCase

    init(
        buildUseCase: BuildWeeklyReviewUseCase,
        reviewRepository: WeeklyReviewRepository,
        rescheduleTasksUseCase: RescheduleTasksUseCase
    ) {
        self.buildUseCase = buildUseCase
        self.reviewRepository = reviewRepository
        self.rescheduleTasksUseCase = rescheduleTasksUseCase
    }

    func load() {
        do {
            let report = try buildUseCase.execute()
            self.report = report
            history = try reviewRepository.fetchAll()
            selectedTaskIDs = Set(report.unfinishedTasks.map(\.id))
            if let saved = history.first(where: { Calendar.current.isDate($0.weekStart, inSameDayAs: report.weekStart) }) {
                note = saved.note ?? ""
                priorities = saved.priorities ?? ""
                didSave = true
            }
            errorMessage = nil
        } catch {
            AppLogger.error(error, context: "weekly_review.load")
            errorMessage = error.localizedDescription
        }
    }

    func toggleSelection(_ task: TaskItem) {
        if selectedTaskIDs.contains(task.id) { selectedTaskIDs.remove(task.id) }
        else { selectedTaskIDs.insert(task.id) }
    }

    func completeReview() {
        guard let report else { return }
        do {
            let selected = report.unfinishedTasks.filter { selectedTaskIDs.contains($0.id) }
            try rescheduleTasksUseCase.move(selected, to: report.weekEnd)
            try reviewRepository.upsert(WeeklyReview(
                weekStart: report.weekStart,
                completedTaskCount: report.completedTasks.count,
                focusMinutes: report.focusMinutes,
                habitCheckInCount: report.habitCheckInCount,
                balanceAverage: report.balanceAverage,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                priorities: priorities.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ))
            didSave = true
            load()
        } catch {
            AppLogger.error(error, context: "weekly_review.save")
            errorMessage = error.localizedDescription
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
