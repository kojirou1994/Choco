import ArgumentParser
import TSCExecutableLauncher
import Foundation
import libChoco

enum HardwareDecoding: String, ExpressibleByArgument, CaseIterable {
  case videotoolbox
  case cuvid
}

struct Verify: ParsableCommand {

  @Flag
  var videoOnly: Bool = false

  @Option
  var hw: HardwareDecoding?

  @Flag(name: .shortAndLong)
  var verbose: Bool = false

  @Argument()
  var inputs: [String]

  func run() throws {
    inputs.forEach { input in
      do {
        print("verifying \(input)...")
        let startDate = Date()

        var outputOptions = [FFmpeg.OutputOption]()
        outputOptions.append(.map(inputFileID: 0, streamSpecifier: .streamType(.video), isOptional: true, isNegativeMapping: false))
        if !videoOnly {
          outputOptions.append(.map(inputFileID: 0, streamSpecifier: .streamType(.audio), isOptional: true, isNegativeMapping: false))
        }
        outputOptions.append(.format("null"))

        var inputOptions = [FFmpeg.InputOption]()

        switch hw {
        case .cuvid:
          // reference: https://developer.nvidia.com/blog/nvidia-ffmpeg-transcoding-guide/
          inputOptions.append(.hardwareAcceleration("cuda", streamSpecifier: nil))
          inputOptions.append(.avOption(name: "hwaccel_output_format", value: "cuda", streamSpecifier: nil))
        case .videotoolbox:
          inputOptions.append(.hardwareAcceleration("videotoolbox", streamSpecifier: nil))
          // inputOptions.append(.avOption(name: "videotoolbox_pixfmt", value: "nv12", streamSpecifier: nil))
        default: break
        }

        let ffmpeg = FFmpeg(
          global: .init(logLevel: .init(enabledFlags: [.level], level: verbose ? .info : .warning), hideBanner: true, enableStdin: false),
          inputs: [.init(url: input, options: inputOptions)],
          outputs: [.init(url: "-", options: outputOptions)])
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
