import SwiftUI

struct AgentRowView: View {
    let agent: LaunchAgent
    let onToggle: () -> Void
    let onShowDetail: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(agent.status.color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(agent.shortLabel)
                    .font(.system(size: 13))

                Text(agent.status.displayText)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onToggle) {
                Image(systemName: agent.status.isLoaded ? "stop.circle" : "play.circle")
                    .foregroundColor(agent.status.isLoaded ? .orange : .green)
            }
            .buttonStyle(.plain)
            .help(agent.status.isLoaded ? "Unload" : "Load")

            Button(action: onShowDetail) {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.plain)
            .help("Show details")
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
    }
}
