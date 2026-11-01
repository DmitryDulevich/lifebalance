import Foundation

/// Navigation payload for pushing `FocusTimerView` from Today or Tasks.
struct FocusNavigationTarget: Identifiable, Hashable {
    let id = UUID()
    let task: TaskItem?

    static func == (lhs: FocusNavigationTarget, rhs: FocusNavigationTarget) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
