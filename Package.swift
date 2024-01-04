// swift-tools-version:5.5

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
    .executable(name: "fix-rarbg", targets: ["fix-rarbg"]),
    .executable(name: "video-encoder", targets: ["video-encoder"]),
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
    .package(url: "https://github.com/kojirou1994/SystemUp.git", from: "0.2.4"),
    .package(url: "https://github.com/kojirou1994/YYJSONEncoder.git", from: "0.0.2"),
    .package(url: "https://github.com/AlwaysRightInstitute/mustache.git", .upToNextMajor(from: "1.0.0")),
    .package(url: "https://github.com/apple/swift-crypto.git", from: "1.0.0"),
    .package(url: "https://github.com/kojirou1994/ISOCodes.git", .exact("0.1.0")),
    .package(url: "https://github.com/objecthub/swift-numberkit.git", from: "2.4.0"),
    .package(url: "https://github.com/kojirou1994/Escape.git", from: "0.0.1"),
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
        .product(name: "JSON", package: "YYJSONEncoder"),
        .product(name: "NumberKit", package: "swift-numberkit"),
        .product(name: "Escape", package: "Escape"),
      ]
    ),
    .executableTarget(
      name: "video-encoder",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Command", package: "SystemUp"),
      ]
    ),
    .executableTarget(
      name: "choco-cli",
      dependencies: [
        "libChoco",
        .product(name: "Rainbow", package: "Rainbow"),
        .product(name: "PrettyBytes", package: "PrettyBytes"),
        .product(name: "Units", package: "Units"),
        .product(name: "BufferUtility", package: "BufferUtility"),
        .product(name: "Crypto", package: "swift-crypto", condition: .when(platforms: [.linux])),
        .product(name: "SystemFileManager", package: "SystemUp"),
      ]
    ),
    .executableTarget(
      name: "chapter-tool",
      dependencies: [
        .product(name: "TSCExecutableLauncher", package: "Executable"),
        "URLFileManager",
        .product(name: "Logging", package: "swift-log"),
        .product(name: "MediaUtility", package: "MediaUtility"),
        .product(name: "MediaTools", package: "MediaUtility"),
        .product(name: "ArgumentParser", package: "swift-argument-parser")
    ]),
    .executableTarget(
      name: "fix-rarbg",
      dependencies: [
        "ISOCodes",
        .product(name: "TSCExecutableLauncher", package: "Executable"),
        .product(name: "Logging", package: "swift-log"),
        .product(name: "MediaUtility", package: "MediaUtility"),
        .product(name: "MediaTools", package: "MediaUtility"),
        .product(name: "SystemFileManager", package: "SystemUp"),
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
