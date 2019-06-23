// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Remuxer",
    products: [
        .executable(name: "BD-Remuxer", targets: ["BD-Remuxer"]),
//        .executable(name: "MKV2MP4", targets: ["MKV2MP4"])
        .library(name: "MediaTools", targets: ["MediaTools"])
    ],
    dependencies: [
        .package(url: "https://github.com/kojirou1994/Kwift.git", from: "0.2.0"),
        .package(url: "https://github.com/kojirou1994/ArgumentParser.git", .branch("master")),
        .package(url: "https://github.com/IBM-Swift/BlueSignals.git", from: "1.0.0"),
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
            name: "MovieDatabase",
            dependencies: ["SwiftEnhancement", "FoundationEnhancement", "MediaTools"]
        ),
        .target(
            name: "MovieOrganizer",
            dependencies: ["Kwift", "MediaTools", "MovieDatabase", "ArgumentParser"]
        ),
        .target(
            name: "MplsReader-Demo",
            dependencies: ["MplsReader"]
        ),
        .target(
            name: "MediaTools",
            dependencies: ["Executable"]
        ),
        .target(
            name: "BD-Remuxer",
            dependencies: ["MediaTools", "MplsReader", "Kwift", "ArgumentParser", "Signals"]),
//        .target(
//            name: "MKV2MP4",
//            dependencies: ["Common", "Kwift", "Signals", "ArgumentParser"]),
        .target(
            name: "Exp",
            dependencies: ["Kwift", "MediaTools", "MplsReader", "CLibbluray"]),
        .target(
            name: "ChapterRename",
            dependencies: ["Executable", "MplsReader"]),
        .testTarget(
            name: "RemuxerTests",
            dependencies: ["BD-Remuxer"]),
    ]
)
