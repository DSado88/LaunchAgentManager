import XCTest
@testable import LaunchAgentManager

final class LaunchctlServiceTests: XCTestCase {

    // MARK: - Status Parsing

    func testParseListOutputRunning() {
        let output = """
        1234\t0\tcom.ori.daemon
        -\t0\tcom.iceland.sync
        5678\t-1\tcom.epoch.worker
        """

        let statuses = LaunchctlService.parseListOutput(output)

        XCTAssertEqual(statuses["com.ori.daemon"], .running(pid: 1234))
        XCTAssertEqual(statuses["com.iceland.sync"], .loaded(exitCode: 0))
        XCTAssertEqual(statuses["com.epoch.worker"], .running(pid: 5678))
    }

    func testParseListOutputWithError() {
        let output = "-\t78\tcom.test.failed"

        let statuses = LaunchctlService.parseListOutput(output)

        XCTAssertEqual(statuses["com.test.failed"], .error(exitCode: 78))
    }

    func testParseListOutputIgnoresInvalidLines() {
        let output = """
        1234\t0\tcom.valid.agent
        invalid line without tabs
        \t\t
        5678\t0\tcom.another.valid
        """

        let statuses = LaunchctlService.parseListOutput(output)

        XCTAssertEqual(statuses.count, 2)
        XCTAssertEqual(statuses["com.valid.agent"], .running(pid: 1234))
        XCTAssertEqual(statuses["com.another.valid"], .running(pid: 5678))
    }

    func testParseListOutputEmpty() {
        let output = ""

        let statuses = LaunchctlService.parseListOutput(output)

        XCTAssertTrue(statuses.isEmpty)
    }

    // MARK: - Command Building

    func testBootstrapCommand() {
        let uid = getuid()
        let command = LaunchctlService.bootstrapCommand(
            plistPath: "/Users/test/Library/LaunchAgents/com.test.plist"
        )

        XCTAssertEqual(command, ["launchctl", "bootstrap", "gui/\(uid)", "/Users/test/Library/LaunchAgents/com.test.plist"])
    }

    func testBootoutCommand() {
        let uid = getuid()
        let command = LaunchctlService.bootoutCommand(label: "com.test.agent")

        XCTAssertEqual(command, ["launchctl", "bootout", "gui/\(uid)/com.test.agent"])
    }

    func testLegacyLoadCommand() {
        let command = LaunchctlService.legacyLoadCommand(
            plistPath: "/Users/test/Library/LaunchAgents/com.test.plist"
        )

        XCTAssertEqual(command, ["launchctl", "load", "/Users/test/Library/LaunchAgents/com.test.plist"])
    }

    func testLegacyUnloadCommand() {
        let command = LaunchctlService.legacyUnloadCommand(
            plistPath: "/Users/test/Library/LaunchAgents/com.test.plist"
        )

        XCTAssertEqual(command, ["launchctl", "unload", "/Users/test/Library/LaunchAgents/com.test.plist"])
    }

    // MARK: - Status Map Application

    func testApplyStatusMapToAgents() {
        var agents = [
            makeAgent(label: "com.test.running"),
            makeAgent(label: "com.test.loaded"),
            makeAgent(label: "com.test.notloaded"),
        ]

        let statusMap: [String: AgentStatus] = [
            "com.test.running": .running(pid: 1234),
            "com.test.loaded": .loaded(exitCode: 0),
            // com.test.notloaded is intentionally missing
        ]

        LaunchctlService.applyStatusMap(statusMap, to: &agents)

        XCTAssertEqual(agents[0].status, .running(pid: 1234))
        XCTAssertEqual(agents[1].status, .loaded(exitCode: 0))
        XCTAssertEqual(agents[2].status, .notLoaded)
    }

    // MARK: - Log Tail Command

    func testTailLogCommand() {
        let command = LaunchctlService.tailLogCommand(
            path: "/var/log/test.log",
            lines: 50
        )

        XCTAssertEqual(command, ["tail", "-n", "50", "/var/log/test.log"])
    }

    func testTailLogCommandWithDifferentLineCount() {
        let command = LaunchctlService.tailLogCommand(
            path: "/var/log/test.log",
            lines: 100
        )

        XCTAssertEqual(command, ["tail", "-n", "100", "/var/log/test.log"])
    }

    // MARK: - Helper

    private func makeAgent(label: String) -> LaunchAgent {
        LaunchAgent(
            label: label,
            plistPath: URL(fileURLWithPath: "/test/\(label).plist"),
            programArguments: [],
            scheduleType: .onDemand,
            standardOutPath: nil,
            standardErrorPath: nil,
            status: .notLoaded
        )
    }
}
