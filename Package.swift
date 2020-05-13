// swift-tools-version:5.2

import PackageDescription

let package = Package(
  name: "BDRemuxer",
  platforms: [
    .macOS(.v10_15)
  ],
  products: [
    .library(name: "MplsParser", targets: ["MplsParser"]),
  ],
  dependencies: [
    .package(url: "https://github.com/kojirou1994/Kwift.git", from: "0.5.0"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.1"),
    .package(url: "https://github.com/kojirou1994/URLFileManager.git", from: "0.0.1"),
    .package(url: "git@github.com:kojirou1994/MediaUtility.git", from: "0.0.2"),
    .package(url: "git@github.com:kojirou1994/Executable.git", from: "0.1.0"),
    .package(url: "https://github.com/onevcat/Rainbow.git", from: "3.0.0")
  ],
  targets: [
    .systemLibrary(
      name: "CBluray",
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
    .target(
      name: "TrackExtension",
      dependencies: [
        .product(name: "MediaTools", package: "MediaUtility")
      ]
    ),
    .target(
      name: "TrackInfo",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        "TrackExtension"
      ]
    ),
    .target(
      name: "BDRemuxer",
      dependencies: [
        "CBluray",
        "MplsParser",
        "Kwift",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        "URLFileManager",
        "TrackExtension",
        "Rainbow"
      ]
    ),
    .target(
      name: "BDRemuxer-cli",
      dependencies: [
        "BDRemuxer",
        "Rainbow"
      ]
    ),
    //        .target(
    //            name: "MKV2MP4",
    //            dependencies: ["Common", "Kwift", "Signals", "ArgumentParser"]),
    .target(
      name: "ChapterRename",
      dependencies: [
        "Executable",
        "MediaUtility",
        .product(name: "ArgumentParser", package: "swift-argument-parser")
    ]),
    .testTarget(
      name: "RemuxerTests",
      dependencies: ["BDRemuxer"]),
  ]
)
