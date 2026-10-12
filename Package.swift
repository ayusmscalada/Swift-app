// swift-tools-version:5.9
import PackageDescription

// Optional quick runner: open this file in Xcode and run the `BaccaratApp` scheme without
// generating the .xcodeproj.
let package = Package(
    name: "BaccaratAssistant",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "BaccaratApp", targets: ["BaccaratApp"]),
    ],
    dependencies: [
        // Local copy, because the GitHub download kept failing. Get it with:
        //   mkdir -p Packages && cd Packages && git clone --depth 1 https://github.com/groue/GRDB.swift.git
        // To download from GitHub again instead, use:
        //   .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0"),
        .package(path: "Packages/GRDB.swift"),
    ],
    targets: [
        // The whole app: SwiftUI views and view models (App/), pure Baccarat logic
        // (App/Domain) and SQLite storage (App/Data).
        .executableTarget(
            name: "BaccaratApp",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "App"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
