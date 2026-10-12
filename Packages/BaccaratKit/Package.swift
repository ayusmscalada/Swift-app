// swift-tools-version:5.9
import PackageDescription

// Domain logic and SQLite storage for the app. Kept in its own folder because Xcode
// cannot load a local package from the same directory as the .xcodeproj that uses it.
let package = Package(
    name: "BaccaratKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "BaccaratDomain", targets: ["BaccaratDomain"]),
        .library(name: "BaccaratData", targets: ["BaccaratData"]),
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
