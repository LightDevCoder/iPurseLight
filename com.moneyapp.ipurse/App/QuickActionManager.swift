import SwiftUI

@MainActor
final class QuickActionManager: ObservableObject {
    static let shared = QuickActionManager()

    @Published private(set) var pendingInputText: String?
    @Published var shouldShowAddTransaction = false

    private init() {}

    func handleIncomingText(_ text: String) {
        pendingInputText = text
        shouldShowAddTransaction = true
    }

    func consumePendingText() -> String? {
        let text = pendingInputText
        pendingInputText = nil
        return text
    }
}
