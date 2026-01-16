import Foundation

public struct ProjectGrouper {
    private var customPrefixes: [String: String] = [:]

    private static let defaultPrefixes: [String: String] = [
        "com.ori": "ORI",
        "com.iceland": "Iceland",
        "com.epoch": "Epoch",
        "com.orchid": "Orchid",
        "ai.orchidstudio": "Orchid",
        "com.david": "Personal",
        "com.apple": "Apple",
        "homebrew": "Homebrew",
        "com.adobe": "Adobe",
        "com.google": "Google",
        "com.microsoft": "Microsoft",
    ]

    private static let userPrefixes: Set<String> = [
        "com.ori",
        "com.iceland",
        "com.epoch",
        "com.orchid",
        "ai.orchidstudio",
        "com.david",
    ]

    public init() {}

    public mutating func registerPrefix(_ prefix: String, groupName: String) {
        customPrefixes[prefix] = groupName
    }

    public func groupName(for label: String) -> String {
        // Check custom prefixes first
        for (prefix, name) in customPrefixes {
            if label.hasPrefix(prefix) {
                return name
            }
        }

        // Then check default prefixes
        return Self.groupName(for: label)
    }

    public static func groupName(for label: String) -> String {
        // Check known prefixes
        for (prefix, name) in defaultPrefixes {
            if label.hasPrefix(prefix) {
                return name
            }
        }

        // Extract vendor from label
        let parts = label.split(separator: ".")
        if parts.count >= 2 {
            return String(parts[1])
        }

        return "Other"
    }

    public static func isUserAgent(_ label: String) -> Bool {
        for prefix in userPrefixes {
            if label.hasPrefix(prefix) {
                return true
            }
        }
        return false
    }

    public static func group(_ agents: [LaunchAgent]) -> [String: [LaunchAgent]] {
        var grouped: [String: [LaunchAgent]] = [:]

        for agent in agents {
            let group = groupName(for: agent.label)
            grouped[group, default: []].append(agent)
        }

        // Sort agents within each group by label
        for (key, value) in grouped {
            grouped[key] = value.sorted { $0.label < $1.label }
        }

        return grouped
    }
}
