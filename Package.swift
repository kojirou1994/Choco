// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Remuxer",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(path: "../SwiftFFmpeg"),
        .package(url: "https://github.com/kojirou1994/Kwift", .branch("master")),
        .package(url: "https://github.com/apple/swift-package-manager", from: "0.3.0"),
        .package(url: "https://github.com/IBM-Swift/BlueSignals", from: "1.0.0")
    ],
    targets: [
        .systemLibrary(
            name: "CLibbluray",
            pkgConfig: "libbluray"
        ),
        .target(
            name: "Common",
            dependencies: ["SwiftFFmpeg", "Kwift", "Utility"]
        ),
        .target(
            name: "Remuxer",
            dependencies: ["Common", "SwiftFFmpeg", "Kwift", "Utility", "CLibbluray", "Signals"]),
        .target(
            name: "Exp",
            dependencies: ["SwiftFFmpeg", "Kwift", "CLibbluray"]),
        .testTarget(
            name: "RemuxerTests",
            dependencies: ["Remuxer"]),
    ]
)
