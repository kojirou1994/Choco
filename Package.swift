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
    .executable(name: "choco-cli", targets: ["choco-cli"]),
    .executable(name: "chapter-tool", targets: ["chapter-tool"]),
  ],
  dependencies: [
    .package(url: "https://github.com/kojirou1994/Kwift.git", from: "1.0.0"),
    .package(url: "https://github.com/kojirou1994/Precondition.git", from: "1.0.0"),
    .package(url: "https://github.com/kojirou1994/Units.git", from: "0.0.1"),
    .package(url: "https://github.com/kojirou1994/PrettyBytes.git", from: "0.0.1"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
    .package(url: "https://github.com/kojirou1994/URLFileManager.git", from: "0.0.1"),
    .package(url: "https://github.com/kojirou1994/MediaUtility.git", from: "0.6.0"),
    .package(url: "https://github.com/kojirou1994/Executable.git", from: "0.5.0"),
    .package(url: "https://github.com/kojirou1994/IOUtility.git", from: "0.0.1"),
    .package(url: "https://github.com/onevcat/Rainbow.git", from: "3.0.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.4.0"),
    .package(url: "https://github.com/kojirou1994/BufferUtility.git", from: "0.0.1"),
    .package(url: "https://github.com/AlwaysRightInstitute/mustache.git", .upToNextMajor(from: "1.0.0")),
    .package(url: "https://github.com/apple/swift-crypto.git", from: "1.0.0"),
    .package(url: "https://github.com/kojirou1994/ISOCodes.git", .exact("0.1.0")),
  ],
  targets: [
    .target(
      name: "MplsParser",
      dependencies: [
        .product(name: "IOModule", package: "IOUtility"),
        .product(name: "IOStreams", package: "IOUtility"),
        .product(name: "Precondition", package: "Precondition"),
        .product(name: "MediaUtility", package: "MediaUtility"),
      ]
    ),
    .target(
      name: "libChoco",
      dependencies: [
        "MplsParser",
        "Rainbow",
        "URLFileManager",
        "ISOCodes",
        .product(name: "Precondition", package: "Precondition"),
        .product(name: "mustache", package: "mustache"),
        .product(name: "KwiftUtility", package: "Kwift"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "MediaUtility", package: "MediaUtility"),
        .product(name: "MediaTools", package: "MediaUtility"),
        .product(name: "Logging", package: "swift-log"),
        .product(name: "FPExecutableLauncher", package: "Executable"),
      ]
    ),
    .target(
      name: "choco-cli",
      dependencies: [
        "libChoco",
        .product(name: "Rainbow", package: "Rainbow"),
        .product(name: "PrettyBytes", package: "PrettyBytes"),
        .product(name: "Units", package: "Units"),
        .product(name: "BufferUtility", package: "BufferUtility"),
        .product(name: "Crypto", package: "swift-crypto", condition: .when(platforms: [.linux])),
      ]
    ),
    .target(
      name: "chapter-tool",
      dependencies: [
        .product(name: "TSCExecutableLauncher", package: "Executable"),
        "URLFileManager",
        .product(name: "Logging", package: "swift-log"),
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
