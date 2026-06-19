import SwiftUI

struct DebugView: View {
    @EnvironmentObject private var lm: LocalizationManager

    @State private var log = ""
    @State private var testingProvider: AIProvider?

    var body: some View {
        VStack(spacing: 20) {
            ScrollView {
                Text(log.isEmpty ? lm.t("准备就绪，请点击下方按钮测试...") : log)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding()
            }
            .frame(height: 300)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 12) {
                providerButton(.gemini, color: .blue)
                providerButton(.deepSeek, color: .purple)
                providerButton(.openAI, color: .green)
            }
        }
        .padding()
        .navigationTitle(lm.t("网络诊断实验室"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func providerButton(_ provider: AIProvider, color: Color) -> some View {
        Button {
            test(provider)
        } label: {
            VStack(spacing: 2) {
                if testingProvider == provider {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(lm.t("测试"))
                        .font(.caption2)
                    Text(provider.rawValue)
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 34)
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
        .disabled(testingProvider != nil)
    }

    private func test(_ provider: AIProvider) {
        testingProvider = provider
        log = "Connecting to \(provider.rawValue)…"

        Task {
            do {
                let response = try await AIService.shared.testConnection(to: provider)
                await MainActor.run {
                    log = "\(provider.rawValue): OK\n\n\(response)"
                    testingProvider = nil
                }
            } catch {
                await MainActor.run {
                    log = "\(provider.rawValue): \(error.localizedDescription)"
                    testingProvider = nil
                }
            }
        }
    }
}
