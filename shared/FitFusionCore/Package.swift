// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FitFusionCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        // macOS target is required so `swift test` works on macOS hosts
        // (CI runs Swift Package tests on macos-14 runners).
        // CloudStore uses NSPersistentCloudKitContainer, @MainActor, and
        // Swift Concurrency — all macOS 13+ surfaces.
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "FitFusionCore",
            targets: ["FitFusionCore"]
        ),
    ],
    targets: [
        .target(
            name: "FitFusionCore",
            path: "Sources/FitFusionCore",
            resources: [
                .process("FitFusionModel.xcdatamodeld"),
            ]
        ),
        .testTarget(
            name: "FitFusionCoreTests",
            dependencies: ["FitFusionCore"],
            path: "Tests/FitFusionCoreTests"
        ),
    ]
)
