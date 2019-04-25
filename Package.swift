// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Remuxer",
    products: [
        .executable(name: "BD-Remuxer", targets: ["BD-Remuxer"]),
//        .executable(name: "MKV2MP4", targets: ["MKV2MP4"])
    ],
    dependencies: [
        .package(url: "https://github.com/kojirou1994/Kwift.git", .exact("0.1.7")),
        .package(url: "https://github.com/kojirou1994/ArgumentParser.git", .branch("master")),
        .package(url: "https://github.com/IBM-Swift/BlueSignals.git", from: "1.0.0")
    ],
    targets: [
        .systemLibrary(
            name: "CLibbluray",
            pkgConfig: "libbluray"
        ),
        .target(
            name: "MplsReader",
            dependencies: ["Kwift"]
        ),
        .target(
            name: "MplsReader-Demo",
            dependencies: ["MplsReader"]
        ),
        .target(
            name: "Common",
            dependencies: ["Kwift", "MplsReader"]
        ),
        .target(
            name: "BD-Remuxer",
            dependencies: ["Common", "Kwift", "ArgumentParser", "CLibbluray", "Signals"]),
//        .target(
//            name: "MKV2MP4",
//            dependencies: ["Common", "Kwift", "Signals", "ArgumentParser"]),
        .target(
            name: "Exp",
            dependencies: ["Kwift", "CLibbluray", "Common"]),
        .target(
            name: "ChapterRename",
            dependencies: ["Kwift", "Common"]),
        .testTarget(
            name: "RemuxerTests",
            dependencies: ["BD-Remuxer"]),
    ]
)
