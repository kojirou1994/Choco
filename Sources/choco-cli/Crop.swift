import ArgumentParser
import ExecutableLauncher
import Foundation
import URLFileManager
import Precondition
import libChoco

let fm = URLFileManager.default

func sysTempDir() -> String {
  if let envV = ProcessInfo.processInfo.environment["TMPDIR"] {
    return envV
  }

  return fm.temporaryDirectory.path
}

enum OutputFormat: String, ExpressibleByArgument, CaseIterable, CustomStringConvertible {
  case text
  case ffmpeg
  case origin

  var description: String { rawValue }
}

struct Crop: ParsableCommand {

  @Option(help: "Available: \(OutputFormat.allCases)")
  var format: OutputFormat = .text

  @Option(help: "How many preview images are generated")
  var previews: Int = 10

  @Option()
  var tmp: String = sysTempDir()

  @Argument()
  var input: String

  func run() throws {
    let tempDirURL = URL(fileURLWithPath: tmp)
    let tempFileURL = tempDirURL.appendingPathComponent("\(UUID()).mkv")
    let info = try calculateAutoCrop(at: input, previews: previews, tempFile: tempFileURL)
    switch format {
    case .origin:
      print(info.plainText)
    case .text:
      print(info)
    case .ffmpeg:
      print(info.ffmpegArgument)
    }
  }
}

