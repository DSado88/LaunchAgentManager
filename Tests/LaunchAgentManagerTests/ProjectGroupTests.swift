import XCTest
@testable import LaunchAgentManager

final class ProjectGroupTests: XCTestCase {

    // MARK: - Default Prefix Mappings

    func testOriPrefix() {
        let groupName = ProjectGrouper.groupName(for: "com.ori.daemon")
        XCTAssertEqual(groupName, "ORI")
    }

    func testIcelandPrefix() {
        let groupName = ProjectGrouper.groupName(for: "com.iceland.sync")
        XCTAssertEqual(groupName, "Iceland")
    }

    func testEpochPrefix() {
        let groupName = ProjectGrouper.groupName(for: "com.epoch.worker")
        XCTAssertEqual(groupName, "Epoch")
    }

    func testOrchidComPrefix() {
        let groupName = ProjectGrouper.groupName(for: "com.orchid.server")
        XCTAssertEqual(groupName, "Orchid")
    }

    func testOrchidAiPrefix() {
        let groupName = ProjectGrouper.groupName(for: "ai.orchidstudio.agent")
        XCTAssertEqual(groupName, "Orchid")
    }

    func testDavidPrefix() {
        let groupName = ProjectGrouper.groupName(for: "com.david.utility")
        XCTAssertEqual(groupName, "Personal")
    }

    // MARK: - Known Vendor Groups

    func testApplePrefix() {
        let groupName = ProjectGrouper.groupName(for: "com.apple.something")
        XCTAssertEqual(groupName, "Apple")
    }

    func testHomebrewPrefix() {
        let groupName = ProjectGrouper.groupName(for: "homebrew.mxcl.postgresql")
        XCTAssertEqual(groupName, "Homebrew")
    }

    func testAdobePrefix() {
        let groupName = ProjectGrouper.groupName(for: "com.adobe.AAMUpdater")
        XCTAssertEqual(groupName, "Adobe")
    }

    func testGooglePrefix() {
        let groupName = ProjectGrouper.groupName(for: "com.google.keystone")
        XCTAssertEqual(groupName, "Google")
    }

    func testMicrosoftPrefix() {
        let groupName = ProjectGrouper.groupName(for: "com.microsoft.update")
        XCTAssertEqual(groupName, "Microsoft")
    }

    // MARK: - Unknown/Other Groups

    func testUnknownPrefixFallsBackToVendor() {
        let groupName = ProjectGrouper.groupName(for: "com.unknowncompany.app")
        XCTAssertEqual(groupName, "unknowncompany")
    }

    func testOrgPrefixExtractsVendor() {
        let groupName = ProjectGrouper.groupName(for: "org.someorg.service")
        XCTAssertEqual(groupName, "someorg")
    }

    func testIoPrefixExtractsVendor() {
        let groupName = ProjectGrouper.groupName(for: "io.github.someproject")
        XCTAssertEqual(groupName, "github")
    }

    func testShortLabelReturnsOther() {
        let groupName = ProjectGrouper.groupName(for: "simple")
        XCTAssertEqual(groupName, "Other")
    }

    func testTwoPartLabelReturnsSecondPart() {
        let groupName = ProjectGrouper.groupName(for: "com.test")
        XCTAssertEqual(groupName, "test")
    }

    // MARK: - Custom Prefix Registration

    func testCustomPrefixRegistration() {
        var grouper = ProjectGrouper()
        grouper.registerPrefix("com.mycompany", groupName: "My Company")

        let groupName = grouper.groupName(for: "com.mycompany.app")
        XCTAssertEqual(groupName, "My Company")
    }

    func testCustomPrefixOverridesDefault() {
        var grouper = ProjectGrouper()
        grouper.registerPrefix("com.apple", groupName: "Cupertino")

        let groupName = grouper.groupName(for: "com.apple.finder")
        XCTAssertEqual(groupName, "Cupertino")
    }

    // MARK: - Grouping Agents

    func testGroupAgentsByProject() {
        let agents = [
            makeAgent(label: "com.ori.daemon"),
            makeAgent(label: "com.ori.sync"),
            makeAgent(label: "com.iceland.worker"),
            makeAgent(label: "com.apple.something"),
        ]

        let grouped = ProjectGrouper.group(agents)

        XCTAssertEqual(grouped.count, 3)
        XCTAssertEqual(grouped["ORI"]?.count, 2)
        XCTAssertEqual(grouped["Iceland"]?.count, 1)
        XCTAssertEqual(grouped["Apple"]?.count, 1)
    }

    func testGroupedAgentsAreSortedByLabel() {
        let agents = [
            makeAgent(label: "com.ori.zebra"),
            makeAgent(label: "com.ori.alpha"),
            makeAgent(label: "com.ori.beta"),
        ]

        let grouped = ProjectGrouper.group(agents)

        let oriAgents = grouped["ORI"] ?? []
        XCTAssertEqual(oriAgents.map(\.label), [
            "com.ori.alpha",
            "com.ori.beta",
            "com.ori.zebra"
        ])
    }

    // MARK: - Project Filter

    func testIsUserAgentWithKnownPrefix() {
        XCTAssertTrue(ProjectGrouper.isUserAgent("com.ori.daemon"))
        XCTAssertTrue(ProjectGrouper.isUserAgent("com.iceland.sync"))
        XCTAssertTrue(ProjectGrouper.isUserAgent("com.david.utility"))
    }

    func testIsUserAgentWithSystemPrefix() {
        XCTAssertFalse(ProjectGrouper.isUserAgent("com.apple.finder"))
        XCTAssertFalse(ProjectGrouper.isUserAgent("com.adobe.AAMUpdater"))
        XCTAssertFalse(ProjectGrouper.isUserAgent("homebrew.mxcl.postgresql"))
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
