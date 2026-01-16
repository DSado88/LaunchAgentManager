import Foundation
import Combine

@MainActor
public class LaunchAgentService: ObservableObject {
    @Published public private(set) var agents: [LaunchAgent] = []
    @Published public private(set) var groupedAgents: [String: [LaunchAgent]] = [:]
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?
    @Published public var showOnlyUserAgents = true

    private let launchctlService = LaunchctlService()
    private let launchAgentsDirectory: URL

    public init(launchAgentsDirectory: URL? = nil) {
        self.launchAgentsDirectory = launchAgentsDirectory ?? FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
    }

    public func refresh() async {
        isLoading = true
        error = nil

        do {
            // Parse all plist files
            var parsedAgents = try PlistParser.scanDirectory(launchAgentsDirectory)

            // Get current statuses
            let statuses = try await launchctlService.getStatuses()

            // Apply statuses
            LaunchctlService.applyStatusMap(statuses, to: &parsedAgents)

            // Update state
            agents = parsedAgents.sorted { $0.label < $1.label }
            updateGroupedAgents()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    public func loadAgent(_ agent: LaunchAgent) async {
        do {
            try await launchctlService.loadAgent(agent)
            await refresh()
        } catch {
            self.error = error
        }
    }

    public func unloadAgent(_ agent: LaunchAgent) async {
        do {
            try await launchctlService.unloadAgent(agent)
            await refresh()
        } catch {
            self.error = error
        }
    }

    public func toggleAgent(_ agent: LaunchAgent) async {
        if agent.status.isLoaded {
            await unloadAgent(agent)
        } else {
            await loadAgent(agent)
        }
    }

    public func tailLog(for agent: LaunchAgent, type: LogType, lines: Int = 50) async throws -> String {
        guard let path = (type == .stdout ? agent.standardOutPath : agent.standardErrorPath) else {
            return "No \(type.rawValue) log configured for this agent."
        }

        return try await launchctlService.tailLog(path: path, lines: lines)
    }

    public var filteredAgents: [LaunchAgent] {
        if showOnlyUserAgents {
            return agents.filter { ProjectGrouper.isUserAgent($0.label) }
        }
        return agents
    }

    public var filteredGroupedAgents: [String: [LaunchAgent]] {
        if showOnlyUserAgents {
            return groupedAgents.filter { key, _ in
                !["Apple", "Adobe", "Google", "Microsoft", "Homebrew"].contains(key)
            }.mapValues { agents in
                agents.filter { ProjectGrouper.isUserAgent($0.label) }
            }.filter { !$0.value.isEmpty }
        }
        return groupedAgents
    }

    public var sortedGroupNames: [String] {
        let userGroups = ["ORI", "Iceland", "Epoch", "Orchid", "Personal"]
        let filtered = filteredGroupedAgents

        let sorted = filtered.keys.sorted { a, b in
            let aIndex = userGroups.firstIndex(of: a) ?? Int.max
            let bIndex = userGroups.firstIndex(of: b) ?? Int.max
            if aIndex != bIndex {
                return aIndex < bIndex
            }
            return a < b
        }

        return sorted
    }

    private func updateGroupedAgents() {
        groupedAgents = ProjectGrouper.group(agents)
    }

    public enum LogType: String {
        case stdout = "stdout"
        case stderr = "stderr"
    }
}
