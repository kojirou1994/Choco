// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "Choco",
  platforms: [
    .macOS(.v10_15)
  ],
  products: [
    .library(name: "MplsParser", targets: ["MplsParser"]),
    .library(name: "libChoco", targets: ["libChoco"]),
  ],
  dependencies: [
    .package(url: "https://github.com/kojirou1994/Kwift.git", from: "0.8.0"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
    .package(url: "https://github.com/kojirou1994/URLFileManager.git", from: "0.0.1"),
    .package(url: "https://github.com/kojirou1994/MediaUtility.git", from: "0.2.0"),
    .package(url: "https://github.com/kojirou1994/Executable.git", from: "0.4.0"),
    .package(url: "https://github.com/onevcat/Rainbow.git", from: "3.0.0"),
    .package(url: "https://github.com/apple/swift-log", from: "1.4.0"),
    .package(url: "https://github.com/kojirou1994/BufferUtility.git", .branch("main")),
    .package(url: "https://github.com/AlwaysRightInstitute/mustache.git", .upToNextMajor(from: "1.0.0")),
    .package(url: "https://github.com/apple/swift-crypto.git", from: "1.0.0"),
    .package(url: "https://github.com/kojirou1994/ISOCodes.git", .exact("0.1.0")),
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
        "ISOCodes",
        .product(name: "mustache", package: "mustache"),
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
        "Rainbow",
        .product(name: "BufferUtility", package: "BufferUtility"),
        .product(name: "Crypto", package: "swift-crypto", condition: .when(platforms: [.linux])),
      ]
    ),
    .target(
      name: "chapter-tool",
      dependencies: [
        "Executable",
        "URLFileManager",
        .product(name: "MediaUtility", package: "MediaUtility"),
        .product(name: "MediaTools", package: "MediaUtility"),
        .product(name: "ArgumentParser", package: "swift-argument-parser")
    ]),
    .testTarget(
      name: "MplsParserTests",
      dependencies: ["MplsParser"]),
    .testTarget(
      name: "ChocoTests",
      dependencies: ["libChoco"]),
  ]
)
