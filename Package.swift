// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LaunchAgentManager",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "LaunchAgentManager",
            targets: ["LaunchAgentManager"]
        )
    ],
    targets: [
        .executableTarget(
            name: "LaunchAgentManager",
            path: "Sources/LaunchAgentManager"
        ),
        .testTarget(
            name: "LaunchAgentManagerTests",
            dependencies: ["LaunchAgentManager"],
            path: "Tests/LaunchAgentManagerTests"
        )
    ]
)
