import AppIntents

struct AddTransactionIntent: AppIntent {
    static var title: LocalizedStringResource = "Note a Bill"
    static var description: IntentDescription = IntentDescription("Add a transaction via voice or text input.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Input Text", requestValueDialog: "What did you spend?")
    var text: String

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        QuickActionManager.shared.handleIncomingText(text)
        return .result()
    }
}

struct iPurseLightShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTransactionIntent(),
            phrases: [
                "Note a bill in \(.applicationName)",
                "Add transaction in \(.applicationName)",
                "记一笔 \(.applicationName)"
            ],
            shortTitle: "Note Bill",
            systemImageName: "square.and.pencil"
        )
    }
}
