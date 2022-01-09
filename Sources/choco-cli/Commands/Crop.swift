import ArgumentParser
import ExecutableLauncher
import Foundation
import URLFileManager
import Precondition
import libChoco

private func sysTempDir() -> String {
  if let envV = ProcessInfo.processInfo.environment["TMPDIR"] {
    return envV
  }

  return URLFileManager.default.temporaryDirectory.path
}

enum OutputFormat: String, ExpressibleByArgument, CaseIterable, CustomStringConvertible {
  case text
  case ffmpeg

  var description: String { rawValue }
}

extension CropTool: ExpressibleByArgument {}

struct Crop: ParsableCommand {

  @Option(help: "Available: \(OutputFormat.allCases)")
  var format: OutputFormat = .text

  @Option(help: "Available: \(CropTool.allCases)")
  var tool: CropTool

  @Option(help: "How many preview images are generated, for handbrake.")
  var previews: Int = 200

  @Option(help: "Set higher black value threshold, which can be optionally specified from nothing (0) to everything (255 for 8-bit based formats).")
  var limit: UInt8 = 24

  @Option()
  var tmp: String = sysTempDir()

  @Argument()
  var input: String

  func run() throws {
    let tempDirURL = URL(fileURLWithPath: tmp)
    let tempFileURL = tempDirURL.appendingPathComponent("\(UUID()).mkv")
    let info: CropInfo
    switch tool {
    case .ffmpeg:
      info = try ffmpegCrop(file: input, limit: limit)
    case .handbrake:
      info = try handbrakeCrop(at: input, previews: previews, tempFile: tempFileURL)
    }
    switch format {
    case .text:
      print(info)
    case .ffmpeg:
      print(info.ffmpegArgument)
    }
  }
}

