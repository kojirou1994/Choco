// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Remuxer",
    products: [
        .library(
            name: "SwiftFFmpeg",
            targets: ["SwiftFFmpeg"]
        ),
        .executable(name: "BD-Remuxer", targets: ["Remuxer"])
    ],
    dependencies: [
        .package(url: "https://github.com/kojirou1994/Kwift", from: "0.1.1"),
        .package(url: "https://github.com/apple/swift-package-manager", .branch("swift-5.0-branch")),
        .package(url: "https://github.com/IBM-Swift/BlueSignals", from: "1.0.0")
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
            dependencies: ["SwiftFFmpeg", "Kwift", "SPMUtility", "MplsReader"]
        ),
        .target(
            name: "Remuxer",
            dependencies: ["Common", "SwiftFFmpeg", "Kwift", "SPMUtility", "CLibbluray", "Signals"]),
        .target(
            name: "Exp",
            dependencies: ["SwiftFFmpeg", "Kwift", "CLibbluray", "Common"]),
        .target(
            name: "ChapterRename",
            dependencies: ["Kwift", "Common"]),
        .testTarget(
            name: "RemuxerTests",
            dependencies: ["Remuxer"]),
    ]
)
