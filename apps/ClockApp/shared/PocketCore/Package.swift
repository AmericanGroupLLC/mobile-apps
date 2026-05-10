// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PocketCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "PocketCore", targets: ["PocketCore"])
    ],
    targets: [
        .target(
            name: "PocketCore",
            path: "Sources/PocketCore"
        ),
        .testTarget(
            name: "PocketCoreTests",
            dependencies: ["PocketCore"],
            path: "Tests/PocketCoreTests"
        )
    ]
)
