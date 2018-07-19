// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "QXTCPServer-Vapor",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "QXTCPServer-Vapor",
            targets: ["QXTCPServer-Vapor"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.7.3"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "QXTCPServer-Vapor",
            dependencies: ["NIO","NIOConcurrencyHelpers"]),
        .testTarget(
            name: "QXTCPServer-VaporTests",
            dependencies: ["QXTCPServer-Vapor"]),
    ]
)
