// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FitFusionCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
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
