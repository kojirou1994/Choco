// swift-tools-version:5.2

import PackageDescription

let package = Package(
  name: "Choco",
  platforms: [
    .macOS(.v10_15)
  ],
  products: [
    .library(name: "MplsParser", targets: ["MplsParser"]),
  ],
  dependencies: [
    .package(url: "https://github.com/kojirou1994/Kwift.git", from: "0.8.0"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
    .package(url: "https://github.com/kojirou1994/URLFileManager.git", from: "0.0.1"),
    .package(url: "https://github.com/kojirou1994/MediaUtility.git", from: "0.2.0"),
    .package(url: "https://github.com/kojirou1994/Executable.git", from: "0.4.0"),
    .package(url: "https://github.com/onevcat/Rainbow.git", from: "3.0.0"),
    .package(url: "https://github.com/apple/swift-log", from: "1.4.0")
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
        .product(name: "KwiftUtility", package: "Kwift"),
        "MediaUtility"
      ]
    ),
    .target(
      name: "libChoco",
      dependencies: [
        "CBluray",
        "MplsParser",
        "Rainbow",
        "URLFileManager",
        .product(name: "KwiftUtility", package: "Kwift"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "MediaUtility", package: "MediaUtility"),
        .product(name: "MediaTools", package: "MediaUtility"),
        .product(name: "Logging", package: "swift-log")
      ]
    ),
    .target(
      name: "choco-cli",
      dependencies: [
        "libChoco",
        "Rainbow"
      ]
    ),
    //        .target(
    //            name: "MKV2MP4",
    //            dependencies: ["Common", "Kwift", "Signals", "ArgumentParser"]),
    .target(
      name: "chapter-tool",
      dependencies: [
        "Executable",
        "URLFileManager",
        .product(name: "MediaTools", package: "MediaUtility"),
        .product(name: "ArgumentParser", package: "swift-argument-parser")
    ]),
    .testTarget(
      name: "MplsParserTests",
      dependencies: ["MplsParser"]),
    .testTarget(
      name: "RemuxerTests",
      dependencies: ["libChoco"]),
  ]
)
