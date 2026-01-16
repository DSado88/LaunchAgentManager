import Foundation

public enum PlistParserError: Error {
    case fileNotFound(URL)
    case invalidPlist(URL)
    case missingLabel(URL)
    case missingProgramArguments(URL)
}

public struct PlistParser {

    public static func parse(_ plistPath: URL) throws -> LaunchAgent {
        guard FileManager.default.fileExists(atPath: plistPath.path) else {
            throw PlistParserError.fileNotFound(plistPath)
        }

        let data = try Data(contentsOf: plistPath)

        guard let plist = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) as? [String: Any] else {
            throw PlistParserError.invalidPlist(plistPath)
        }

        guard let label = plist["Label"] as? String else {
            throw PlistParserError.missingLabel(plistPath)
        }

        let programArguments = plist["ProgramArguments"] as? [String] ?? []
        let standardOutPath = plist["StandardOutPath"] as? String
        let standardErrorPath = plist["StandardErrorPath"] as? String

        let scheduleType = determineScheduleType(from: plist)

        return LaunchAgent(
            label: label,
            plistPath: plistPath,
            programArguments: programArguments,
            scheduleType: scheduleType,
            standardOutPath: standardOutPath,
            standardErrorPath: standardErrorPath,
            status: .notLoaded
        )
    }

    public static func scanDirectory(_ directory: URL) throws -> [LaunchAgent] {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        var agents: [LaunchAgent] = []

        for fileURL in contents where fileURL.pathExtension == "plist" {
            do {
                let agent = try parse(fileURL)
                agents.append(agent)
            } catch {
                // Skip invalid plist files but continue scanning
                continue
            }
        }

        return agents
    }

    private static func determineScheduleType(from plist: [String: Any]) -> ScheduleType {
        // Priority order: KeepAlive > StartInterval > StartCalendarInterval > RunAtLoad > OnDemand

        if let keepAlive = plist["KeepAlive"] {
            if let boolValue = keepAlive as? Bool, boolValue {
                return .keepAlive
            }
            if let dictValue = keepAlive as? [String: Any], !dictValue.isEmpty {
                return .keepAlive
            }
        }

        if let interval = plist["StartInterval"] as? Int {
            return .interval(seconds: interval)
        }

        if plist["StartCalendarInterval"] != nil {
            return .calendar
        }

        if let runAtLoad = plist["RunAtLoad"] as? Bool, runAtLoad {
            return .runAtLoad
        }

        return .onDemand
    }
}
