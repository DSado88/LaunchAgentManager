import XCTest
@testable import LaunchAgentManager

final class LaunchAgentTests: XCTestCase {

    // MARK: - Schedule Type

    func testScheduleTypeKeepAlive() {
        let scheduleType = ScheduleType.keepAlive
        XCTAssertEqual(scheduleType.description, "Keep Alive")
    }

    func testScheduleTypeInterval() {
        let scheduleType = ScheduleType.interval(seconds: 300)
        XCTAssertEqual(scheduleType.description, "Every 5 minutes")
    }

    func testScheduleTypeCalendar() {
        let scheduleType = ScheduleType.calendar
        XCTAssertEqual(scheduleType.description, "Calendar")
    }

    func testScheduleTypeOnDemand() {
        let scheduleType = ScheduleType.onDemand
        XCTAssertEqual(scheduleType.description, "On Demand")
    }

    func testScheduleTypeRunAtLoad() {
        let scheduleType = ScheduleType.runAtLoad
        XCTAssertEqual(scheduleType.description, "Run at Load")
    }

    // MARK: - LaunchAgent Creation

    func testLaunchAgentInitialization() {
        let agent = LaunchAgent(
            label: "com.ori.daemon",
            plistPath: URL(fileURLWithPath: "/Users/test/Library/LaunchAgents/com.ori.daemon.plist"),
            programArguments: ["/usr/local/bin/ori", "--daemon"],
            scheduleType: .keepAlive,
            standardOutPath: "/tmp/ori.stdout.log",
            standardErrorPath: "/tmp/ori.stderr.log",
            status: .notLoaded
        )

        XCTAssertEqual(agent.label, "com.ori.daemon")
        XCTAssertEqual(agent.plistPath.lastPathComponent, "com.ori.daemon.plist")
        XCTAssertEqual(agent.programArguments, ["/usr/local/bin/ori", "--daemon"])
        XCTAssertEqual(agent.scheduleType, .keepAlive)
        XCTAssertEqual(agent.standardOutPath, "/tmp/ori.stdout.log")
        XCTAssertEqual(agent.standardErrorPath, "/tmp/ori.stderr.log")
        XCTAssertEqual(agent.status, .notLoaded)
    }

    func testLaunchAgentIdentifiable() {
        let agent = LaunchAgent(
            label: "com.ori.daemon",
            plistPath: URL(fileURLWithPath: "/test.plist"),
            programArguments: [],
            scheduleType: .onDemand,
            standardOutPath: nil,
            standardErrorPath: nil,
            status: .notLoaded
        )

        XCTAssertEqual(agent.id, "com.ori.daemon")
    }

    func testLaunchAgentWithNilLogPaths() {
        let agent = LaunchAgent(
            label: "com.test.agent",
            plistPath: URL(fileURLWithPath: "/test.plist"),
            programArguments: ["/bin/test"],
            scheduleType: .runAtLoad,
            standardOutPath: nil,
            standardErrorPath: nil,
            status: .running(pid: 123)
        )

        XCTAssertNil(agent.standardOutPath)
        XCTAssertNil(agent.standardErrorPath)
    }

    // MARK: - Computed Properties

    func testExecutableName() {
        let agent = LaunchAgent(
            label: "com.ori.daemon",
            plistPath: URL(fileURLWithPath: "/test.plist"),
            programArguments: ["/usr/local/bin/ori", "--daemon"],
            scheduleType: .keepAlive,
            standardOutPath: nil,
            standardErrorPath: nil,
            status: .notLoaded
        )

        XCTAssertEqual(agent.executableName, "ori")
    }

    func testExecutableNameWithEmptyArgs() {
        let agent = LaunchAgent(
            label: "com.test.agent",
            plistPath: URL(fileURLWithPath: "/test.plist"),
            programArguments: [],
            scheduleType: .onDemand,
            standardOutPath: nil,
            standardErrorPath: nil,
            status: .notLoaded
        )

        XCTAssertNil(agent.executableName)
    }

    func testShortLabel() {
        let agent = LaunchAgent(
            label: "com.ori.sync.daemon",
            plistPath: URL(fileURLWithPath: "/test.plist"),
            programArguments: [],
            scheduleType: .onDemand,
            standardOutPath: nil,
            standardErrorPath: nil,
            status: .notLoaded
        )

        XCTAssertEqual(agent.shortLabel, "sync.daemon")
    }

    func testShortLabelForTwoPartLabel() {
        let agent = LaunchAgent(
            label: "com.apple",
            plistPath: URL(fileURLWithPath: "/test.plist"),
            programArguments: [],
            scheduleType: .onDemand,
            standardOutPath: nil,
            standardErrorPath: nil,
            status: .notLoaded
        )

        XCTAssertEqual(agent.shortLabel, "com.apple")
    }

    // MARK: - Interval Description

    func testIntervalDescriptionForMinutes() {
        let scheduleType = ScheduleType.interval(seconds: 180)
        XCTAssertEqual(scheduleType.description, "Every 3 minutes")
    }

    func testIntervalDescriptionForOneMinute() {
        let scheduleType = ScheduleType.interval(seconds: 60)
        XCTAssertEqual(scheduleType.description, "Every 1 minute")
    }

    func testIntervalDescriptionForHours() {
        let scheduleType = ScheduleType.interval(seconds: 7200)
        XCTAssertEqual(scheduleType.description, "Every 2 hours")
    }

    func testIntervalDescriptionForOneHour() {
        let scheduleType = ScheduleType.interval(seconds: 3600)
        XCTAssertEqual(scheduleType.description, "Every 1 hour")
    }

    func testIntervalDescriptionForSeconds() {
        let scheduleType = ScheduleType.interval(seconds: 30)
        XCTAssertEqual(scheduleType.description, "Every 30 seconds")
    }

    func testIntervalDescriptionForOneSecond() {
        let scheduleType = ScheduleType.interval(seconds: 1)
        XCTAssertEqual(scheduleType.description, "Every 1 second")
    }
}
