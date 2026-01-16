import SwiftUI

struct MenuBarView: View {
    @ObservedObject var service: LaunchAgentService
    @ObservedObject var poller: StatusPoller
    @State private var searchText = ""
    @State private var selectedAgent: LaunchAgent?
    @State private var showSettings = false
    @State private var expandedGroups: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            searchSection
            Divider()
            agentListSection
            Divider()
            footerSection
        }
        .frame(width: 350)
        .task {
            await service.refresh()
            poller.start()
        }
        .sheet(item: $selectedAgent) { agent in
            AgentDetailView(agent: agent, service: service)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(service: service, poller: poller)
        }
    }

    private var headerSection: some View {
        HStack {
            Text("Launch Agents")
                .font(.headline)

            Spacer()

            if service.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            }

            Button(action: { Task { await service.refresh() } }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .help("Refresh")

            Button(action: { showSettings = true }) {
                Image(systemName: "gear")
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search agents...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var agentListSection: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(service.sortedGroupNames, id: \.self) { groupName in
                    if let agents = service.filteredGroupedAgents[groupName] {
                        let filtered = filterAgents(agents)
                        if !filtered.isEmpty {
                            groupSection(name: groupName, agents: filtered)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: 400)
    }

    private func groupSection(name: String, agents: [LaunchAgent]) -> some View {
        let isExpanded = expandedGroups.contains(name)
        let runningCount = agents.filter { $0.status.isRunning }.count

        return VStack(alignment: .leading, spacing: 0) {
            Button(action: { toggleGroup(name) }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 12)

                    Text(name)
                        .font(.system(size: 12, weight: .semibold))

                    Spacer()

                    Text("\(runningCount)/\(agents.count)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(nsColor: .quaternaryLabelColor).opacity(0.3))
                        .cornerRadius(4)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.15))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(agents) { agent in
                    AgentRowView(
                        agent: agent,
                        onToggle: {
                            Task { await service.toggleAgent(agent) }
                        },
                        onShowDetail: {
                            selectedAgent = agent
                        }
                    )
                    .background(Color(nsColor: .controlBackgroundColor))
                }
            }
        }
    }

    private func toggleGroup(_ name: String) {
        if expandedGroups.contains(name) {
            expandedGroups.remove(name)
        } else {
            expandedGroups.insert(name)
        }
    }

    private func filterAgents(_ agents: [LaunchAgent]) -> [LaunchAgent] {
        if searchText.isEmpty {
            return agents
        }
        return agents.filter { agent in
            agent.label.localizedCaseInsensitiveContains(searchText) ||
            (agent.executableName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var footerSection: some View {
        HStack {
            Text("\(service.filteredAgents.count) agents")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Toggle("My agents only", isOn: $service.showOnlyUserAgents)
                .toggleStyle(.checkbox)
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
