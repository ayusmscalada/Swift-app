// swift-tools-version:5.9
import PackageDescription

// Optional quick runner: open this file in Xcode and run the `BaccaratApp` scheme without
// generating the .xcodeproj. The libraries and tests live in Packages/BaccaratKit.
let package = Package(
    name: "BaccaratAssistant",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "BaccaratApp", targets: ["BaccaratApp"]),
    ],
    dependencies: [
        .package(path: "Packages/BaccaratKit"),
    ],
    targets: [
        .executableTarget(
            name: "BaccaratApp",
            dependencies: [
                .product(name: "BaccaratDomain", package: "BaccaratKit"),
                .product(name: "BaccaratData", package: "BaccaratKit"),
            ],
            path: "App"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
