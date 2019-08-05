// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Remuxer",
    products: [
        .executable(name: "BD-Remuxer", targets: ["BD-Remuxer"]),
//        .executable(name: "MKV2MP4", targets: ["MKV2MP4"])
        .library(name: "MediaUtility", targets: ["MediaUtility"]),
        .library(name: "MplsParser", targets: ["MplsParser"]),
        .library(name: "MediaTools", targets: ["MediaTools"])
    ],
    dependencies: [
        .package(url: "https://github.com/kojirou1994/Kwift.git", from: "0.2.0"),
        .package(url: "https://github.com/kojirou1994/ArgumentParser.git", from: "0.0.1"),
        .package(url: "https://github.com/IBM-Swift/BlueSignals.git", from: "1.0.0"),
        .package(url: "https://github.com/kojirou1994/URLFileManager.git", from: "0.0.1"),
    ],
    targets: [
        .systemLibrary(
            name: "CLibbluray",
            pkgConfig: "libbluray",
            providers: [.brew(["libbluray"])]
        ),
        .target(
            name: "MediaUtility",
            dependencies: ["SwiftEnhancement"]
        ),
        .target(
            name: "MplsParser",
            dependencies: [
                "Kwift",
                "MediaUtility"
            ]
        ),
        .target(
            name: "MediaTools",
            dependencies: [
                "Executable",
                "MediaUtility"
            ]
        ),
        .target(
            name: "BD-Remuxer",
            dependencies: [
                "MediaTools",
                "MplsParser",
                "Kwift",
                "ArgumentParser",
                "Signals",
                "URLFileManager"
            ]
        ),
//        .target(
//            name: "MKV2MP4",
//            dependencies: ["Common", "Kwift", "Signals", "ArgumentParser"]),
        .target(
            name: "Exp",
            dependencies: [
                "Kwift", "MediaTools",
                "MplsParser", "CLibbluray"
            ]
        ),
        .target(
            name: "ChapterRename",
            dependencies: ["Executable", "MplsParser"]),
        .testTarget(
            name: "RemuxerTests",
            dependencies: ["BD-Remuxer"]),
    ]
)
