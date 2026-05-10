// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BuddyAICore",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(name: "BuddyAICore", targets: ["BuddyAICore"]),
    ],
    targets: [
        .target(
            name: "BuddyAICore",
            path: "Sources/BuddyAICore"
        ),
        .testTarget(
            name: "BuddyAICoreTests",
            dependencies: ["BuddyAICore"],
            path: "Tests/BuddyAICoreTests"
        ),
    ]
)
