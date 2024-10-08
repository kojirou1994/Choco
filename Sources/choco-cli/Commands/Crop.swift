import ArgumentParser
import ExecutableLauncher
import Foundation
import SystemUp
import SystemPackage
import Precondition
import libChoco
import Logging

enum OutputFormat: String, ExpressibleByArgument, CaseIterable, CustomStringConvertible {
  case text
  case ffmpeg

  var description: String { rawValue }
}

extension CropTool: ExpressibleByArgument {}

struct Crop: ParsableCommand {

  @Option(name: .shortAndLong, help: "Available: \(OutputFormat.allCases)")
  var format: OutputFormat = .text

  @Option(name: .shortAndLong, help: "Available: \(CropTool.allCases)")
  var tool: CropTool

  @Option(help: "Base filter for ffmpeg")
  var filter: String?

  @Option(help: "Hardware accel for ffmpeg")
  var hw: String?

  @Option(help: "How many preview images are generated, for handbrake.")
  var previews: Int = 200

  @Option(help: "Set higher black value threshold, which can be optionally specified from nothing (0) to everything (255 for 8-bit based formats).")
  var limit: Double?

  @Option(help: "")
  var round: UInt8 = 2

  @Option(help: "")
  var skip: UInt = 0

  @Option(help: "")
  var frames: UInt?

  @OptionGroup
  var temp: TempOptions

  @Argument()
  var input: String

  func run() throws {
    let tempDirPath = temp.tmpDirPath()
    let tempFilePath = tempDirPath.appending("\(UUID()).mkv")
    let logger = Logger(label: "crop", factory: StreamLogHandler.standardError(label:))
    let info: CropInfo
    switch tool {
    case .ffmpeg:
      info = try ffmpegCrop(file: input, baseFilter: filter ?? "", limit: limit, round: round, skip: skip, frames: frames, hw: hw, logger: logger).get()
    case .handbrake:
      info = try handbrakeCrop(at: input, previews: previews, tempFile: tempFilePath)
    }
    switch format {
    case .text:
      print(info)
    case .ffmpeg:
      print(info.ffmpegArgument)
    }
  }
}

