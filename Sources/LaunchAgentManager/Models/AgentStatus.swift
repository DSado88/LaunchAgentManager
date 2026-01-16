import Foundation
import SwiftUI

public enum AgentStatus: Equatable {
    case running(pid: Int)
    case loaded(exitCode: Int)
    case notLoaded
    case error(exitCode: Int)

    public var isRunning: Bool {
        if case .running = self {
            return true
        }
        return false
    }

    public var isLoaded: Bool {
        switch self {
        case .running, .loaded, .error:
            return true
        case .notLoaded:
            return false
        }
    }

    public var color: Color {
        switch self {
        case .running:
            return .green
        case .loaded:
            return .yellow
        case .notLoaded:
            return .gray
        case .error:
            return .orange
        }
    }

    public var displayText: String {
        switch self {
        case .running(let pid):
            return "Running (PID: \(pid))"
        case .loaded:
            return "Loaded (stopped)"
        case .notLoaded:
            return "Not loaded"
        case .error(let exitCode):
            return "Error (exit: \(exitCode))"
        }
    }

    public static func parse(pid: String, exitStatus: String) -> AgentStatus {
        let exitCode = Int(exitStatus) ?? 0

        if pid != "-", let pidInt = Int(pid) {
            return .running(pid: pidInt)
        }

        if exitCode != 0 {
            return .error(exitCode: exitCode)
        }

        return .loaded(exitCode: exitCode)
    }
}
