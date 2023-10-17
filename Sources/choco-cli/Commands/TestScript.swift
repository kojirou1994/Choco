import ArgumentParser
import TSCExecutableLauncher
import Foundation
import libChoco
import FPExecutableLauncher
import URLFileManager

struct TestScript: ParsableCommand {

  @Option
  var previewDirectory: String?

  @Option(name: .shortAndLong, help: "preview images output format")
  var format: String = "jpeg"

  @Option
  var start: Int?

  @Option
  var end: Int?

  @Option(help: "vs output depth")
  var depth: Int?

  @Option
  var crop: CropTime?

  enum CropTime: String, ExpressibleByArgument {
    case vs
//    case encode
  }

  @Argument
  var template: String

  @Argument
  var input: String

  func run() throws {

    let encodeScript = try String(contentsOfFile: template)

    let inputURL = URL(fileURLWithPath: input)
    let inputBasename = inputURL.deletingPathExtension().lastPathComponent

    let vsCrop: CropInfo? = if crop == .vs {
      try ffmpegCrop(file: input, baseFilter: "", limit: nil, round: 2, skip: 0, logger: nil).get()
    } else {
      nil
    }
    if let vsCrop {
      print("crop at vspipe: \(vsCrop)")
    }

    let script = try generateScript(
      encodeScript: encodeScript, filePath: input,
      trackIndex: 0,
      cropInfo: vsCrop,
      encoderDepth: depth ?? 10,
      fps: nil
    )
    let scriptFileURL = inputURL
      .deletingLastPathComponent()
      .appendingPathComponent("\(inputBasename)-gen_script.py")
    try! script.write(to: scriptFileURL, atomically: false, encoding: .utf8)

    try AnyExecutable(executableName: "vspipe", arguments: ["--info", scriptFileURL.path])
      .launch(use: TSCExecutableLauncher(outputRedirection: .none), options: .init(checkNonZeroExitCode: false))

    if let outputDirectoryURL = previewDirectory.map({ URL(fileURLWithPath: $0).appendingPathComponent(inputBasename) }) {

      try URLFileManager.default.createDirectory(at: outputDirectoryURL)

      var vspipeArgs = [String]()

      vspipeArgs.append(contentsOf: ["-c", "y4m", scriptFileURL.path, "-"])

      if let start {
        vspipeArgs.append("--start")
        vspipeArgs.append(start.description)
      }

      if let end {
        vspipeArgs.append("--end")
        vspipeArgs.append(end.description)
      }

      let pipeline = try ContiguousPipeline(AnyExecutable(executableName: "vspipe", arguments: vspipeArgs))

      let outputFile = outputDirectoryURL.appendingPathComponent("%05d.\(format)")
      var outputOptions = [FFmpeg.InputOutputOption]()
      outputOptions.append(.format("image2"))

      let ffmpeg = FFmpeg(global: .init(hideBanner: true, overwrite: true, enableStdin: false), ios: [
        .input(url: "pipe:"),
        .output(url: outputFile.path, options: outputOptions)
      ])

      print(ffmpeg.arguments)

      try pipeline.append(ffmpeg, isLast: true)
      try pipeline.run()
      pipeline.waitUntilExit()
    }
  }
}
