// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CardCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "CardCore", targets: ["CardCore"])
    ],
    targets: [
        .target(
            name: "CardCore",
            path: "Sources/CardCore"
        ),
        .testTarget(
            name: "CardCoreTests",
            dependencies: ["CardCore"],
            path: "Tests/CardCoreTests"
        )
    ]
)
