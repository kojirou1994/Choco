import ArgumentParser
import Executable
import Foundation
import URLFileManager
import Precondition
import BDRemuxer

let fm = URLFileManager.default

func sysTempDir() -> String {
  if let envV = ProcessInfo.processInfo.environment["TMPDIR"] {
    return envV
  }

  return fm.temporaryDirectory.path
}

enum OutputFormat: String, ExpressibleByArgument {
  case text
  case ffmpeg
  case origin
}

struct Crop: ParsableCommand {

  @Option()
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

