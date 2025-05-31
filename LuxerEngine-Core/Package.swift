// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LuxerEngine-Core",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .visionOS(.v1)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "LuxerEngine",
            targets: ["LuxerEngine"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // No external dependencies for the core package
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        .target(
            name: "LuxerEngine",
            dependencies: [],
            resources: [
                // Include shader files and other resources
                .process("Resources")
            ],
            swiftSettings: [
                // Enable experimental concurrency features
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "LuxerEngineTests",
            dependencies: ["LuxerEngine"]
        ),
    ]
)
