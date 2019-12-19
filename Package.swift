// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Remuxer",
    products: [
        .executable(name: "BD-Remuxer", targets: ["BD-Remuxer"]),
//        .executable(name: "MKV2MP4", targets: ["MKV2MP4"])
        .library(name: "MplsParser", targets: ["MplsParser"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kojirou1994/Kwift.git", from: "0.4.0"),
        .package(url: "https://github.com/kojirou1994/ArgumentParser.git", from: "0.1.0"),
        .package(url: "https://github.com/IBM-Swift/BlueSignals.git", from: "1.0.0"),
        .package(url: "https://github.com/kojirou1994/URLFileManager.git", from: "0.0.1"),
        .package(url: "git@github.com:kojirou1994/MediaUtility.git", from: "0.0.2"),
        .package(url: "git@github.com:kojirou1994/Executable.git", from: "0.0.1")
    ],
    targets: [
        .systemLibrary(
            name: "CLibbluray",
            pkgConfig: "libbluray",
            providers: [.brew(["libbluray"])]
        ),
        .target(
            name: "MplsParser",
            dependencies: [
                "Kwift",
                "MediaUtility"
            ]
        ),
//        .target(
//            name: "MplsTest",
//            dependencies: [
//                "Kwift",
//                "MplsParser",
//                "URLFileManager"
//            ]
//        ),
        .target(
            name: "TrackExtension",
            dependencies: [
                "MediaTools"
            ]
        ),
        .target(
            name: "TrackInfo",
            dependencies: [
                "TrackExtension"
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
                "URLFileManager",
                "TrackExtension"
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
            dependencies: ["Executable", "MediaUtility"]),
        .testTarget(
            name: "RemuxerTests",
            dependencies: ["BD-Remuxer"]),
    ]
)
