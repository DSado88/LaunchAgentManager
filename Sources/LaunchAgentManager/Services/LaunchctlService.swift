import Foundation

public actor LaunchctlService {

    public enum LaunchctlError: Error {
        case commandFailed(String)
        case unexpectedOutput(String)
    }

    private static var currentUID: uid_t {
        getuid()
    }

    // MARK: - Status Parsing

    public static func parseListOutput(_ output: String) -> [String: AgentStatus] {
        var statuses: [String: AgentStatus] = [:]

        for line in output.split(separator: "\n") {
            let parts = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard parts.count >= 3 else { continue }

            let pid = String(parts[0])
            let exitStatus = String(parts[1])
            let label = String(parts[2])

            guard !label.isEmpty else { continue }

            let status = AgentStatus.parse(pid: pid, exitStatus: exitStatus)
            statuses[label] = status
        }

        return statuses
    }

    // MARK: - Command Building

    public static func bootstrapCommand(plistPath: String) -> [String] {
        ["launchctl", "bootstrap", "gui/\(currentUID)", plistPath]
    }

    public static func bootoutCommand(label: String) -> [String] {
        ["launchctl", "bootout", "gui/\(currentUID)/\(label)"]
    }

    public static func legacyLoadCommand(plistPath: String) -> [String] {
        ["launchctl", "load", plistPath]
    }

    public static func legacyUnloadCommand(plistPath: String) -> [String] {
        ["launchctl", "unload", plistPath]
    }

    public static func tailLogCommand(path: String, lines: Int) -> [String] {
        ["tail", "-n", "\(lines)", path]
    }

    // MARK: - Status Map Application

    public static func applyStatusMap(_ statusMap: [String: AgentStatus], to agents: inout [LaunchAgent]) {
        for i in agents.indices {
            if let status = statusMap[agents[i].label] {
                agents[i].status = status
            } else {
                agents[i].status = .notLoaded
            }
        }
    }

    // MARK: - Command Execution

    public func getStatuses() async throws -> [String: AgentStatus] {
        let output = try await runCommand(["launchctl", "list"])
        return Self.parseListOutput(output)
    }

    public func loadAgent(_ agent: LaunchAgent) async throws {
        // Try modern bootstrap first
        do {
            try await runCommand(Self.bootstrapCommand(plistPath: agent.plistPath.path))
        } catch {
            // Fall back to legacy load
            try await runCommand(Self.legacyLoadCommand(plistPath: agent.plistPath.path))
        }
    }

    public func unloadAgent(_ agent: LaunchAgent) async throws {
        // Try modern bootout first
        do {
            try await runCommand(Self.bootoutCommand(label: agent.label))
        } catch {
            // Fall back to legacy unload
            try await runCommand(Self.legacyUnloadCommand(plistPath: agent.plistPath.path))
        }
    }

    public func tailLog(path: String, lines: Int = 50) async throws -> String {
        try await runCommand(Self.tailLogCommand(path: path, lines: lines))
    }

    @discardableResult
    private func runCommand(_ arguments: [String]) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            throw LaunchctlError.commandFailed(output)
        }

        return output
    }
}
