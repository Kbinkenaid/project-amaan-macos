// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProjectAmaan",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "ProjectAmaan",
            targets: ["ProjectAmaan"]
        )
    ],
    dependencies: [
        // Network utilities
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0")
    ],
    targets: [
        .executableTarget(
            name: "ProjectAmaan",
            dependencies: [
                "SecurityTools",
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOWebSocket", package: "swift-nio"),
                .product(name: "Crypto", package: "swift-crypto")
            ],
            path: "Sources/ProjectAmaan"
        ),
        .target(
            name: "SecurityTools",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "Crypto", package: "swift-crypto")
            ],
            path: "Sources/SecurityTools"
        ),
        .testTarget(
            name: "ProjectAmaanTests",
            dependencies: ["ProjectAmaan", "SecurityTools"],
            path: "Tests/ProjectAmaanTests"
        )
    ]
)