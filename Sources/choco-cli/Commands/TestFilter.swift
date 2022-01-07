import ArgumentParser
import ExecutableLauncher
import Foundation
import URLFileManager
import libChoco

struct TestFilter: ParsableCommand {

  @Option(help: "Start position.")
  var start: String?

  @Option(help: "Specific filter to use.")
  var filter: String?

  @Option(help: "Frames output count limit.")
  var frames: Int = 25

  @Option(help: "Output root directory.")
  var output: String = "./"

  @Argument()
  var inputs: [String]

  func run() throws {
    let defaultFilters = [
      "fieldmatch",
      "fieldmatch,yadif=deint=interlaced",
      "fieldmatch,yadif=deint=interlaced,decimate",
      "yadif=1",
    ]
    let filters = filter.map { [$0] } ?? defaultFilters
    let fm = URLFileManager.default
    inputs.forEach { input in
      let inputInfo = try! MkvMergeIdentification(filePath: input)
      let videoTrackID = inputInfo.tracks.first(where: {$0.type == .video})!.id

      filters.forEach { filter in
        do {
          let mainFilename = URL(fileURLWithPath: input).lastPathComponentWithoutExtension
          let outputDirectoryURL = fm.makeUniqueFileURL(URL(fileURLWithPath: output).appendingPathComponent("\(mainFilename)_\(filter.safeFilename())"))
          try fm.createDirectory(at: outputDirectoryURL)
          let outputFile = outputDirectoryURL.appendingPathComponent("%05d.png")

          var outputOptions = [FFmpeg.InputOutputOption]()
          outputOptions.append(.format("image2"))
          outputOptions.append(.filter(filtergraph: filter, streamSpecifier: nil))
          outputOptions.append(.map(inputFileID: 0, streamSpecifier: .streamIndex(videoTrackID), isOptional: false, isNegativeMapping: false))
          outputOptions.append(.frameCount(frames, streamSpecifier: .streamID(0)))

          var inputOptions = [FFmpeg.InputOutputOption]()
          if let start = start {
            inputOptions.append(.startPosition(start))
          }

          let ffmpeg = FFmpeg(global: .init(enableStdin: false), ios: [
            .input(url: input, options: inputOptions),
            .output(url: outputFile.path, options: outputOptions)
          ])
          print(ffmpeg.arguments)
          try ffmpeg.launch(use: TSCExecutableLauncher(outputRedirection: .none))

        } catch {
          print("error handling input \(input) for filter \(filter): \(error)")
        }
      }
    }
  }
}