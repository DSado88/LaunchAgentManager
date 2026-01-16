import XCTest
@testable import LaunchAgentManager

final class AgentStatusTests: XCTestCase {

    // MARK: - Status Cases

    func testRunningStatusExists() {
        let status = AgentStatus.running(pid: 1234)
        XCTAssertNotNil(status)
    }

    func testLoadedStatusExists() {
        let status = AgentStatus.loaded(exitCode: 0)
        XCTAssertNotNil(status)
    }

    func testNotLoadedStatusExists() {
        let status = AgentStatus.notLoaded
        XCTAssertNotNil(status)
    }

    func testErrorStatusExists() {
        let status = AgentStatus.error(exitCode: 1)
        XCTAssertNotNil(status)
    }

    // MARK: - Properties

    func testIsRunningReturnsTrueForRunning() {
        let status = AgentStatus.running(pid: 1234)
        XCTAssertTrue(status.isRunning)
    }

    func testIsRunningReturnsFalseForLoaded() {
        let status = AgentStatus.loaded(exitCode: 0)
        XCTAssertFalse(status.isRunning)
    }

    func testIsRunningReturnsFalseForNotLoaded() {
        let status = AgentStatus.notLoaded
        XCTAssertFalse(status.isRunning)
    }

    func testIsLoadedReturnsTrueForRunning() {
        let status = AgentStatus.running(pid: 1234)
        XCTAssertTrue(status.isLoaded)
    }

    func testIsLoadedReturnsTrueForLoadedStatus() {
        let status = AgentStatus.loaded(exitCode: 0)
        XCTAssertTrue(status.isLoaded)
    }

    func testIsLoadedReturnsFalseForNotLoaded() {
        let status = AgentStatus.notLoaded
        XCTAssertFalse(status.isLoaded)
    }

    // MARK: - Color

    func testColorForRunningIsGreen() {
        let status = AgentStatus.running(pid: 1234)
        XCTAssertEqual(status.color, .green)
    }

    func testColorForLoadedIsYellow() {
        let status = AgentStatus.loaded(exitCode: 0)
        XCTAssertEqual(status.color, .yellow)
    }

    func testColorForNotLoadedIsGray() {
        let status = AgentStatus.notLoaded
        XCTAssertEqual(status.color, .gray)
    }

    func testColorForErrorIsOrange() {
        let status = AgentStatus.error(exitCode: 78)
        XCTAssertEqual(status.color, .orange)
    }

    // MARK: - Display Text

    func testDisplayTextForRunning() {
        let status = AgentStatus.running(pid: 1234)
        XCTAssertEqual(status.displayText, "Running (PID: 1234)")
    }

    func testDisplayTextForLoaded() {
        let status = AgentStatus.loaded(exitCode: 0)
        XCTAssertEqual(status.displayText, "Loaded (stopped)")
    }

    func testDisplayTextForNotLoaded() {
        let status = AgentStatus.notLoaded
        XCTAssertEqual(status.displayText, "Not loaded")
    }

    func testDisplayTextForError() {
        let status = AgentStatus.error(exitCode: 78)
        XCTAssertEqual(status.displayText, "Error (exit: 78)")
    }

    // MARK: - Parsing from launchctl list output

    func testParseFromLaunchctlRunning() {
        // launchctl list format: PID<tab>Status<tab>Label
        let status = AgentStatus.parse(pid: "1234", exitStatus: "0")
        XCTAssertEqual(status, .running(pid: 1234))
    }

    func testParseFromLaunchctlLoadedNotRunning() {
        // "-" for PID means loaded but not running
        let status = AgentStatus.parse(pid: "-", exitStatus: "0")
        XCTAssertEqual(status, .loaded(exitCode: 0))
    }

    func testParseFromLaunchctlError() {
        // Non-zero exit status indicates error
        let status = AgentStatus.parse(pid: "-", exitStatus: "78")
        XCTAssertEqual(status, .error(exitCode: 78))
    }

    func testParseFromLaunchctlRunningWithNonZeroExit() {
        // Running but had previous non-zero exit - still running
        let status = AgentStatus.parse(pid: "5678", exitStatus: "1")
        XCTAssertEqual(status, .running(pid: 5678))
    }
}
