import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataBackupView: View {
    // ✨ FIX 1: 获取全局注入的本地化管理器实例
    @EnvironmentObject var lm: LocalizationManager
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showShareSheet = false
    @State private var backupURL: URL?
    @State private var showFileImporter = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    var body: some View {
        Form {
            // Section 1: 导出
            Section {
                Button {
                    do {
                        let url = try BackupService.shared.createBackupFile(context: modelContext)
                        self.backupURL = url
                        self.showShareSheet = true
                    } catch {
                        alertMessage = "\(lm.t("Export failed")): \(error.localizedDescription)"
                        showAlert = true
                    }
                } label: {
                    // ✨ FIX 2: 使用 lm.t()
                    Label(lm.t("Export All Data"), systemImage: "square.and.arrow.up")
                }
            } header: {
                Text(lm.t("Backup"))
            } footer: {
                Text(lm.t("Export as .json file to save locally or send to another device."))
            }
            
            // Section 2: 恢复
            Section {
                Button {
                    showFileImporter = true
                } label: {
                    Label(lm.t("Restore from File"), systemImage: "square.and.arrow.down")
                        .foregroundColor(.red)
                }
            } header: {
                Text(lm.t("Restore"))
            } footer: {
                Text(lm.t("Current data will be merged with the backup file."))
            }
            
            // Section 3: 未来云同步占位
            Section(header: Text(lm.t("Cloud Sync"))) {
                HStack {
                    Image(systemName: "icloud")
                    Text("iCloud / Google Drive")
                    Spacer()
                    Text(lm.t("Coming Soon"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(lm.t("Data Backup")) // ✨ FIX 3
        .sheet(isPresented: $showShareSheet) {
            if let url = backupURL {
                ShareSheet(activityItems: [url])
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do {
                    try BackupService.shared.restoreBackup(from: url, context: modelContext)
                    alertMessage = lm.t("Restore Successful!")
                } catch {
                    alertMessage = "\(lm.t("Restore failed")): \(error.localizedDescription)"
                }
                showAlert = true
            case .failure(let error):
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
        .alert("System", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}

// ShareSheet 保持不变
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
