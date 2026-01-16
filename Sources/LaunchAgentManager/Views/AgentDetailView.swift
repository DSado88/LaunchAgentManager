import SwiftUI
import AppKit

struct AgentDetailView: View {
    let agent: LaunchAgent
    @ObservedObject var service: LaunchAgentService
    @Environment(\.dismiss) private var dismiss

    @State private var stdoutLog: String = ""
    @State private var stderrLog: String = ""
    @State private var selectedLogTab: LogTab = .stdout
    @State private var isLoadingLogs = false

    enum LogTab {
        case stdout, stderr
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            Divider()
            infoSection
            Divider()
            actionsSection
            Divider()
            logsSection
        }
        .padding()
        .frame(width: 500, height: 600)
        .task {
            await loadLogs()
        }
    }

    private var headerSection: some View {
        HStack {
            Circle()
                .fill(agent.status.color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading) {
                Text(agent.label)
                    .font(.headline)
                Text(agent.status.displayText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Close") {
                dismiss()
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Information")
                .font(.headline)

            LabeledContent("Label", value: agent.label)
            LabeledContent("Schedule", value: agent.scheduleType.description)
            LabeledContent("Plist", value: agent.plistPath.lastPathComponent)

            if let executable = agent.executableName {
                LabeledContent("Executable", value: executable)
            }

            if let stdout = agent.standardOutPath {
                LabeledContent("Stdout Log", value: stdout)
            }

            if let stderr = agent.standardErrorPath {
                LabeledContent("Stderr Log", value: stderr)
            }
        }
        .font(.system(size: 12))
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Actions")
                .font(.headline)

            HStack(spacing: 12) {
                Button(agent.status.isLoaded ? "Unload" : "Load") {
                    Task {
                        await service.toggleAgent(agent)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(agent.status.isLoaded ? .orange : .green)

                Button("Reveal Plist") {
                    NSWorkspace.shared.selectFile(agent.plistPath.path, inFileViewerRootedAtPath: "")
                }

                Button("Open in Console") {
                    openInConsole()
                }

                Button("Refresh Logs") {
                    Task {
                        await loadLogs()
                    }
                }
            }
        }
    }

    private var logsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Logs")
                    .font(.headline)

                Spacer()

                Picker("", selection: $selectedLogTab) {
                    Text("stdout").tag(LogTab.stdout)
                    Text("stderr").tag(LogTab.stderr)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }

            if isLoadingLogs {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    Text(selectedLogTab == .stdout ? stdoutLog : stderrLog)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 200)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(4)
            }
        }
    }

    private func loadLogs() async {
        isLoadingLogs = true

        do {
            stdoutLog = try await service.tailLog(for: agent, type: .stdout)
        } catch {
            stdoutLog = "Error loading stdout: \(error.localizedDescription)"
        }

        do {
            stderrLog = try await service.tailLog(for: agent, type: .stderr)
        } catch {
            stderrLog = "Error loading stderr: \(error.localizedDescription)"
        }

        isLoadingLogs = false
    }

    private func openInConsole() {
        if let path = agent.standardOutPath ?? agent.standardErrorPath {
            let url = URL(fileURLWithPath: path)
            NSWorkspace.shared.open(url)
        }
    }
}
