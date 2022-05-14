import ArgumentParser
import ExecutableLauncher
import Foundation
import libChoco

struct Verify: ParsableCommand {

  @Flag
  var videoOnly: Bool = false

  @Argument()
  var inputs: [String]

  func run() throws {
    inputs.forEach { input in
      do {
        print("verifying \(input)...")
        let startDate = Date()

        var outputOptions = [FFmpeg.InputOutputOption]()
        outputOptions.append(.map(inputFileID: 0, streamSpecifier: .streamType(.video), isOptional: false, isNegativeMapping: false))
        if !videoOnly {
          outputOptions.append(.map(inputFileID: 0, streamSpecifier: .streamType(.audio), isOptional: false, isNegativeMapping: false))
        }
        outputOptions.append(.format("null"))

        var inputOptions = [FFmpeg.InputOutputOption]()

        let ffmpeg = FFmpeg(global: .init(logLevel: .init(enabledFlags: [.level], level: .warning), enableStdin: false), ios: [
          .input(url: input, options: inputOptions),
          .output(url: "-", options: outputOptions)
        ])
        print(ffmpeg.arguments)
        let result = try ffmpeg.launch(use: TSCExecutableLauncher(outputRedirection: .none), options: .init(checkNonZeroExitCode: false))
        print("ffmpeg termination status: \(result.exitStatus)")
        let time = Date().timeIntervalSince(startDate)
        print("time used: \(String(format: "%.3f", time)) seconds.")
      } catch {
        print("failed to verify! error: \(error)")
      }
      print("\n")
    }
  }
}
