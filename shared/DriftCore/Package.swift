// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DriftCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "DriftCore", targets: ["DriftCore"])
    ],
    targets: [
        .target(
            name: "DriftCore",
            path: "Sources/DriftCore"
        ),
        .testTarget(
            name: "DriftCoreTests",
            dependencies: ["DriftCore"],
            path: "Tests/DriftCoreTests"
        )
    ]
)
