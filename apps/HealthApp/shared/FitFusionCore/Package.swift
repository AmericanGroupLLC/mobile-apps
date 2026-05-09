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
    dependencies: [
        // Sentry crash reporting (free Developer tier — 5k errors/month).
        // Used by `CrashReportingService` which is opt-in: the SDK only
        // initializes if the user enables "Crash reports" in Settings AND
        // a build-time `SENTRY_DSN` is configured.
        .package(url: "https://github.com/getsentry/sentry-cocoa.git",
                 from: "8.36.0"),
        // PostHog product analytics (free tier — 1M events/month, OSS).
        // Wired through AnalyticsService — opt-in via Settings.
        .package(url: "https://github.com/PostHog/posthog-ios.git",
                 from: "3.13.0"),
    ],
    targets: [
        .target(
            name: "FitFusionCore",
            dependencies: [
                .product(name: "Sentry", package: "sentry-cocoa"),
                .product(name: "PostHog", package: "posthog-ios"),
            ],
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
