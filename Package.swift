// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "KeyManager",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
    ],
    products: [
        .library(
            name: "KeyManager",
            targets: ["KeyManager"]),
    ],
    targets: [
        .target(
            name: "KeyManager",
            dependencies: []),
        .testTarget(
            name: "KeyManagerTests",
            dependencies: ["KeyManager"]),
    ]
)
