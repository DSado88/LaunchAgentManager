import XCTest
@testable import LaunchAgentManager

final class PlistParserTests: XCTestCase {

    var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Basic Parsing

    func testParseMinimalPlist() throws {
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.test.minimal</string>
            <key>ProgramArguments</key>
            <array>
                <string>/usr/bin/true</string>
            </array>
        </dict>
        </plist>
        """

        let plistPath = tempDir.appendingPathComponent("com.test.minimal.plist")
        try plistContent.write(to: plistPath, atomically: true, encoding: .utf8)

        let agent = try PlistParser.parse(plistPath)

        XCTAssertEqual(agent.label, "com.test.minimal")
        XCTAssertEqual(agent.programArguments, ["/usr/bin/true"])
        XCTAssertEqual(agent.scheduleType, .onDemand)
        XCTAssertNil(agent.standardOutPath)
        XCTAssertNil(agent.standardErrorPath)
    }

    func testParseWithKeepAlive() throws {
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.test.keepalive</string>
            <key>ProgramArguments</key>
            <array>
                <string>/usr/local/bin/daemon</string>
                <string>--foreground</string>
            </array>
            <key>KeepAlive</key>
            <true/>
        </dict>
        </plist>
        """

        let plistPath = tempDir.appendingPathComponent("com.test.keepalive.plist")
        try plistContent.write(to: plistPath, atomically: true, encoding: .utf8)

        let agent = try PlistParser.parse(plistPath)

        XCTAssertEqual(agent.label, "com.test.keepalive")
        XCTAssertEqual(agent.programArguments, ["/usr/local/bin/daemon", "--foreground"])
        XCTAssertEqual(agent.scheduleType, .keepAlive)
    }

    func testParseWithStartInterval() throws {
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.test.interval</string>
            <key>ProgramArguments</key>
            <array>
                <string>/usr/bin/periodic</string>
            </array>
            <key>StartInterval</key>
            <integer>300</integer>
        </dict>
        </plist>
        """

        let plistPath = tempDir.appendingPathComponent("com.test.interval.plist")
        try plistContent.write(to: plistPath, atomically: true, encoding: .utf8)

        let agent = try PlistParser.parse(plistPath)

        XCTAssertEqual(agent.scheduleType, .interval(seconds: 300))
    }

    func testParseWithStartCalendarInterval() throws {
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.test.calendar</string>
            <key>ProgramArguments</key>
            <array>
                <string>/usr/bin/daily</string>
            </array>
            <key>StartCalendarInterval</key>
            <dict>
                <key>Hour</key>
                <integer>3</integer>
                <key>Minute</key>
                <integer>0</integer>
            </dict>
        </dict>
        </plist>
        """

        let plistPath = tempDir.appendingPathComponent("com.test.calendar.plist")
        try plistContent.write(to: plistPath, atomically: true, encoding: .utf8)

        let agent = try PlistParser.parse(plistPath)

        XCTAssertEqual(agent.scheduleType, .calendar)
    }

    func testParseWithRunAtLoad() throws {
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.test.runatload</string>
            <key>ProgramArguments</key>
            <array>
                <string>/usr/bin/startup</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
        </dict>
        </plist>
        """

        let plistPath = tempDir.appendingPathComponent("com.test.runatload.plist")
        try plistContent.write(to: plistPath, atomically: true, encoding: .utf8)

        let agent = try PlistParser.parse(plistPath)

        XCTAssertEqual(agent.scheduleType, .runAtLoad)
    }

    func testParseWithLogPaths() throws {
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.test.logs</string>
            <key>ProgramArguments</key>
            <array>
                <string>/usr/bin/logger</string>
            </array>
            <key>StandardOutPath</key>
            <string>/var/log/test.stdout.log</string>
            <key>StandardErrorPath</key>
            <string>/var/log/test.stderr.log</string>
        </dict>
        </plist>
        """

        let plistPath = tempDir.appendingPathComponent("com.test.logs.plist")
        try plistContent.write(to: plistPath, atomically: true, encoding: .utf8)

        let agent = try PlistParser.parse(plistPath)

        XCTAssertEqual(agent.standardOutPath, "/var/log/test.stdout.log")
        XCTAssertEqual(agent.standardErrorPath, "/var/log/test.stderr.log")
    }

    // MARK: - Directory Scanning

    func testScanDirectoryReturnsAllPlists() throws {
        // Create multiple plist files
        let plist1 = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.test.first</string>
            <key>ProgramArguments</key>
            <array><string>/bin/true</string></array>
        </dict>
        </plist>
        """

        let plist2 = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.test.second</string>
            <key>ProgramArguments</key>
            <array><string>/bin/false</string></array>
        </dict>
        </plist>
        """

        try plist1.write(to: tempDir.appendingPathComponent("com.test.first.plist"), atomically: true, encoding: .utf8)
        try plist2.write(to: tempDir.appendingPathComponent("com.test.second.plist"), atomically: true, encoding: .utf8)

        let agents = try PlistParser.scanDirectory(tempDir)

        XCTAssertEqual(agents.count, 2)
        XCTAssertTrue(agents.contains { $0.label == "com.test.first" })
        XCTAssertTrue(agents.contains { $0.label == "com.test.second" })
    }

    func testScanDirectoryIgnoresNonPlistFiles() throws {
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.test.valid</string>
            <key>ProgramArguments</key>
            <array><string>/bin/true</string></array>
        </dict>
        </plist>
        """

        try plist.write(to: tempDir.appendingPathComponent("valid.plist"), atomically: true, encoding: .utf8)
        try "not a plist".write(to: tempDir.appendingPathComponent("readme.txt"), atomically: true, encoding: .utf8)

        let agents = try PlistParser.scanDirectory(tempDir)

        XCTAssertEqual(agents.count, 1)
        XCTAssertEqual(agents.first?.label, "com.test.valid")
    }

    // MARK: - Error Handling

    func testParseMissingLabelThrows() throws {
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>ProgramArguments</key>
            <array>
                <string>/usr/bin/true</string>
            </array>
        </dict>
        </plist>
        """

        let plistPath = tempDir.appendingPathComponent("missing-label.plist")
        try plistContent.write(to: plistPath, atomically: true, encoding: .utf8)

        XCTAssertThrowsError(try PlistParser.parse(plistPath)) { error in
            XCTAssertTrue(error is PlistParserError)
        }
    }

    func testParseInvalidPlistThrows() throws {
        let invalidContent = "this is not a plist"

        let plistPath = tempDir.appendingPathComponent("invalid.plist")
        try invalidContent.write(to: plistPath, atomically: true, encoding: .utf8)

        XCTAssertThrowsError(try PlistParser.parse(plistPath))
    }

    // MARK: - Schedule Type Priority

    func testKeepAliveTakesPriorityOverRunAtLoad() throws {
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.test.priority</string>
            <key>ProgramArguments</key>
            <array>
                <string>/usr/bin/test</string>
            </array>
            <key>KeepAlive</key>
            <true/>
            <key>RunAtLoad</key>
            <true/>
        </dict>
        </plist>
        """

        let plistPath = tempDir.appendingPathComponent("com.test.priority.plist")
        try plistContent.write(to: plistPath, atomically: true, encoding: .utf8)

        let agent = try PlistParser.parse(plistPath)

        XCTAssertEqual(agent.scheduleType, .keepAlive)
    }
}
