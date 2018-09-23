// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Remuxer",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(path: "../SwiftFFmpeg"),
        .package(url: "https://github.com/kojirou1994/Kwift", .branch("master")),
        .package(url: "https://github.com/apple/swift-package-manager", from: "0.2.0")
    ],
    targets: [
        .target(
            name: "Common",
            dependencies: ["SwiftFFmpeg", "Kwift", "Utility"]
        ),
        .target(
            name: "Remuxer",
            dependencies: ["Common", "SwiftFFmpeg", "Kwift", "Utility"]),
        .target(
            name: "Exp",
            dependencies: ["SwiftFFmpeg", "Kwift"]),
        .testTarget(
            name: "RemuxerTests",
            dependencies: ["Remuxer"]),
    ]
)
