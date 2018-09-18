// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Remuxer",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(path: "../SwiftFFmpeg"),
        .package(url: "https://github.com/kojirou1994/Kwift", .branch("master"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Remuxer",
            dependencies: ["SwiftFFmpeg", "Kwift"]),
        .target(
            name: "Exp",
            dependencies: ["SwiftFFmpeg", "Kwift"]),
        .testTarget(
            name: "RemuxerTests",
            dependencies: ["Remuxer"]),
    ]
)
