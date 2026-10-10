// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BaccaratAssistant",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "BaccaratDomain", targets: ["BaccaratDomain"]),
        .library(name: "BaccaratData", targets: ["BaccaratData"]),
        .executable(name: "BaccaratApp", targets: ["BaccaratApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0"),
    ],
    targets: [
        // Pure Baccarat logic: roads, patterns, strategies, betting maths. No UI, no database.
        .target(name: "BaccaratDomain"),

        // SQLite storage (GRDB), repositories, legacy-file inspection, CSV export.
        .target(
            name: "BaccaratData",
            dependencies: [
                "BaccaratDomain",
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),

        // SwiftUI app. The Xcode project generated from project.yml builds the same sources
        // as a sandboxed .app; this target lets you run it straight from Package.swift.
        .executableTarget(
            name: "BaccaratApp",
            dependencies: ["BaccaratDomain", "BaccaratData"]
        ),

        .testTarget(
            name: "BaccaratDomainTests",
            dependencies: ["BaccaratDomain"],
            resources: [.copy("Reference")]
        ),
        .testTarget(
            name: "BaccaratDataTests",
            dependencies: ["BaccaratData"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
