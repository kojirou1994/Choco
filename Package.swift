// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Remuxer",
    products: [
        .library(
            name: "SwiftFFmpeg",
            targets: ["SwiftFFmpeg"]
        ),
        .executable(name: "BD-Remuxer", targets: ["BD-Remuxer"]),
        .executable(name: "MKV2MP4", targets: ["MKV2MP4"])
    ],
    dependencies: [
        .package(url: "https://github.com/kojirou1994/Kwift.git", .exact("0.1.6")),
//        .package(url: "https://github.com/apple/swift-package-manager.git", .branch("swift-5.0-branch")),
        .package(url: "https://github.com/kojirou1994/ArgumentParser.git", .branch("master")),
        .package(url: "https://github.com/IBM-Swift/BlueSignals.git", from: "1.0.0")
    ],
    targets: [
        .systemLibrary(
            name: "CLibavcodec",
            pkgConfig: "libavcodec"
        ),
        .systemLibrary(
            name: "CLibavfilter",
            pkgConfig: "libavfilter"
        ),
        .systemLibrary(
            name: "CLibavformat",
            pkgConfig: "libavformat"
        ),
        .systemLibrary(
            name: "CLibavutil",
            pkgConfig: "libavutil"
        ),
        .systemLibrary(
            name: "CLibswresample",
            pkgConfig: "libswresample"
        ),
        .systemLibrary(
            name: "CLibswscale",
            pkgConfig: "libswscale"
        ),
        .systemLibrary(
            name: "CFFmpeg",
            pkgConfig: "libavformat"
        ),
        .target(
            name: "SwiftFFmpeg",
            dependencies: ["CFFmpeg"]
        ),
        .target(
            name: "SwiftFFmpeg-Demo",
            dependencies: ["SwiftFFmpeg"]
        ),
        .testTarget(
            name: "SwiftFFmpegTests",
            dependencies: ["SwiftFFmpeg"]
        ),
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
        .target(
            name: "MKV2MP4",
            dependencies: ["Common", "SwiftFFmpeg", "Kwift", "Signals", "ArgumentParser"]),
        .target(
            name: "Exp",
            dependencies: ["SwiftFFmpeg", "Kwift", "CLibbluray", "Common"]),
        .target(
            name: "ChapterRename",
            dependencies: ["Kwift", "Common"]),
        .testTarget(
            name: "RemuxerTests",
            dependencies: ["BD-Remuxer"]),
    ]
)
