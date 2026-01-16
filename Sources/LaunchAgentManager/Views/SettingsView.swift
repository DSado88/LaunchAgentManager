import SwiftUI

struct SettingsView: View {
    @ObservedObject var service: LaunchAgentService
    @ObservedObject var poller: StatusPoller
    @Environment(\.dismiss) private var dismiss

    @State private var pollInterval: Double = 5.0
    @State private var customPrefixes: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)

            GroupBox("Polling") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Refresh interval:")
                        Slider(value: $pollInterval, in: 1...30, step: 1) {
                            Text("Interval")
                        }
                        Text("\(Int(pollInterval))s")
                            .monospacedDigit()
                            .frame(width: 30)
                    }

                    Toggle("Auto-refresh enabled", isOn: Binding(
                        get: { poller.isRunning },
                        set: { newValue in
                            if newValue {
                                poller.setInterval(pollInterval)
                                poller.start()
                            } else {
                                poller.stop()
                            }
                        }
                    ))
                }
                .padding(8)
            }

            GroupBox("Display") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Show only my agents", isOn: $service.showOnlyUserAgents)

                    Text("When enabled, hides system agents (Apple, Adobe, etc.)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Done") {
                    poller.setInterval(pollInterval)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400, height: 350)
        .onAppear {
            pollInterval = poller.interval
        }
    }
}
