// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Remuxer",
    products: [
        .executable(name: "BD-Remuxer", targets: ["BD-Remuxer"]),
//        .executable(name: "MKV2MP4", targets: ["MKV2MP4"])
        .library(name: "MplsReader", targets: ["MplsReader"]),
        .library(name: "MediaTools", targets: ["MediaTools"])
    ],
    dependencies: [
        .package(url: "https://github.com/kojirou1994/Kwift.git", from: "0.2.0"),
        .package(url: "https://github.com/kojirou1994/ArgumentParser.git", .branch("master")),
        .package(url: "https://github.com/IBM-Swift/BlueSignals.git", from: "1.0.0"),
        .package(url: "https://github.com/mxcl/Path.swift.git", from: "0.16.0")
    ],
    targets: [
        .systemLibrary(
            name: "CLibbluray",
            pkgConfig: "libbluray",
            providers: [.brew(["libbluray"])]
        ),
//        .systemLibrary(name: <#T##String#>, path: <#T##String?#>, pkgConfig: <#T##String?#>, providers: <#T##[SystemPackageProvider]?#>)
        .target(
            name: "MediaUtility",
            dependencies: ["SwiftEnhancement"]
        ),
        .target(
            name: "MplsReader",
            dependencies: ["Kwift", "MediaUtility"]
        ),
        .target(
            name: "MediaTools",
            dependencies: ["Executable", "MediaUtility"]
        ),
        .target(
            name: "MovieDatabase",
            dependencies: ["SwiftEnhancement", "FoundationEnhancement", "MediaTools"]
        ),
        .target(
            name: "MovieOrganizer",
            dependencies: [
                "Kwift",
                "MediaTools",
                "MovieDatabase",
                "ArgumentParser",
                "Path"
            ]
        ),
        .target(
            name: "MplsReader-Demo",
            dependencies: ["MplsReader", "MediaTools"]
        ),
        .target(
            name: "BD-Remuxer",
            dependencies: ["MediaTools", "MplsReader", "Kwift", "ArgumentParser", "Signals", "Path"]),
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
