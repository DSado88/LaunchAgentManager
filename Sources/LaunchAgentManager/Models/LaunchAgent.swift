import Foundation

public enum ScheduleType: Equatable, CustomStringConvertible {
    case keepAlive
    case interval(seconds: Int)
    case calendar
    case onDemand
    case runAtLoad

    public var description: String {
        switch self {
        case .keepAlive:
            return "Keep Alive"
        case .interval(let seconds):
            return formatInterval(seconds)
        case .calendar:
            return "Calendar"
        case .onDemand:
            return "On Demand"
        case .runAtLoad:
            return "Run at Load"
        }
    }

    private func formatInterval(_ seconds: Int) -> String {
        if seconds >= 3600 && seconds % 3600 == 0 {
            let hours = seconds / 3600
            return "Every \(hours) hour\(hours == 1 ? "" : "s")"
        } else if seconds >= 60 && seconds % 60 == 0 {
            let minutes = seconds / 60
            return "Every \(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            return "Every \(seconds) second\(seconds == 1 ? "" : "s")"
        }
    }
}

public struct LaunchAgent: Identifiable, Equatable {
    public let label: String
    public let plistPath: URL
    public let programArguments: [String]
    public let scheduleType: ScheduleType
    public let standardOutPath: String?
    public let standardErrorPath: String?
    public var status: AgentStatus

    public var id: String { label }

    public init(
        label: String,
        plistPath: URL,
        programArguments: [String],
        scheduleType: ScheduleType,
        standardOutPath: String?,
        standardErrorPath: String?,
        status: AgentStatus
    ) {
        self.label = label
        self.plistPath = plistPath
        self.programArguments = programArguments
        self.scheduleType = scheduleType
        self.standardOutPath = standardOutPath
        self.standardErrorPath = standardErrorPath
        self.status = status
    }

    public var executableName: String? {
        guard let firstArg = programArguments.first else { return nil }
        return URL(fileURLWithPath: firstArg).lastPathComponent
    }

    public var shortLabel: String {
        let parts = label.split(separator: ".")
        if parts.count > 2 {
            return parts.dropFirst(2).joined(separator: ".")
        }
        return label
    }
}
