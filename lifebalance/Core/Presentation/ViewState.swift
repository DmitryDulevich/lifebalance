import Foundation

enum ViewState<Content> {
    case idle
    case loading
    case content(Content)
    case empty
    case error(String)
}
