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
      try ffmpegCrop(file: input, baseFilter: "", limit: nil, round: 2, skip: 0, frames: nil, logger: nil).get()
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

    let output = try VsPipe(script: scriptFileURL.path, output: .info)
      .launch(use: TSCExecutableLauncher(outputRedirection: .collect), options: .init(checkNonZeroExitCode: false))
    do {
      let info = try VsPipe.Info.parse(output.utf8Output())
      print("Info Parsed!")
      print("Resolution: \(info.width)x\(info.height)")
      print("FPS: \(info.fps.0)/\(info.fps.1)")
      print("Frames: \(info.frames)")
      print("Format: \(info.formatName)")
    } catch {
      print("cannot parse vspipe!")
      try? print("stdout:\n\(output.utf8Output())")
      try? print("stderr:\n\(output.utf8stderrOutput())")
    }

    if let outputDirectoryURL = previewDirectory.map({ URL(fileURLWithPath: $0).appendingPathComponent(inputBasename) }) {

      try URLFileManager.default.createDirectory(at: outputDirectoryURL)

      let vspipe = VsPipe(script: scriptFileURL.path, output: .file(.stdout), start: start, end: end, container: .y4m)

      let pipeline = try ContiguousPipeline(vspipe)

      let outputFile = outputDirectoryURL.appendingPathComponent("%05d.\(format)")
      var outputOptions = [FFmpeg.OutputOption]()
      outputOptions.append(.format("image2"))
      if let start {
        outputOptions.append(.avOption(name: "start_number", value: start.description, streamSpecifier: nil))
      }

      let ffmpeg = FFmpeg(
        global: .init(hideBanner: true, overwrite: true, enableStdin: false),
        inputs: [.init(url: "pipe:")],
        outputs: [.init(url: outputFile.path, options: outputOptions)])

      print(ffmpeg.arguments)

      try pipeline.append(ffmpeg, isLast: true)
      try pipeline.run()
      pipeline.waitUntilExit()
    }
  }
}
