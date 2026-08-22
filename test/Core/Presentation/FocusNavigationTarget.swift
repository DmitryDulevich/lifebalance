import Foundation

/// Navigation payload for pushing `FocusTimerView` from Today or Tasks.
struct FocusNavigationTarget: Identifiable, Hashable {
    let id = UUID()
    let task: TaskItem?
}
