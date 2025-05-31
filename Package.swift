// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LuxerEngine",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .visionOS(.v1)
    ],
    products: [
        // Main product that includes both core and Metal implementation
        .library(
            name: "LuxerEngine",
            targets: ["LuxerEngine"]),
        
        // Individual products for more granular dependencies
        .library(
            name: "LuxerEngineCore",
            targets: ["LuxerEngineCore"]),
        .library(
            name: "LuxerEngineMetal",
            targets: ["LuxerEngineMetal"]),
    ],
    dependencies: [
        // Dependencies on the local packages
        .package(path: "LuxerEngine-Core"),
        .package(path: "LuxerEngine-Metal")
    ],
    targets: [
        // Main target that re-exports both core and Metal
        .target(
            name: "LuxerEngine",
            dependencies: [
                .target(name: "LuxerEngineCore"),
                .target(name: "LuxerEngineMetal")
            ],
            path: "Sources/LuxerEngine"
        ),
        
        // Core target that re-exports LuxerEngine-Core
        .target(
            name: "LuxerEngineCore",
            dependencies: [
                .product(name: "LuxerEngine", package: "LuxerEngine-Core")
            ],
            path: "Sources/LuxerEngineCore"
        ),
        
        // Metal target that re-exports LuxerEngine-Metal
        .target(
            name: "LuxerEngineMetal",
            dependencies: [
                .product(name: "LuxerMetal", package: "LuxerEngine-Metal")
            ],
            path: "Sources/LuxerEngineMetal"
        ),
        
        // Tests
        .testTarget(
            name: "LuxerEngineTests",
            dependencies: ["LuxerEngine"],
            path: "Tests/LuxerEngineTests"
        ),
    ],
    swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency")
    ]
)
