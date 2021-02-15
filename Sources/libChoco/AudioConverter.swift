import Foundation
import ExecutableLauncher
import MediaUtility
import MediaTools

struct AudioConverter: Executable {
  let input: URL
  let output: URL
  let preference: ChocoConfiguration.AudioPreference
  let ffmpegCodecs: ChocoMuxer.FFmpegCodecs
  let channelCount: Int
  let trackIndex: Int

  static var executableName: String { fatalError() }

  var executableName: String {
    switch preference.codec {
    case .flac:
      return FlacEncoder.executableName
    case .opus:
      return "opusenc"
    case .aac:
      return "ffmpeg"
    }
  }

  var bitrate: Int {
    channelCount * preference.lossyAudioChannelBitrate
  }

  var arguments: [String] {
    switch preference.codec {
    case .flac:
      var flac = FlacEncoder(input: input.path, output: output.path)
      flac.level = 8
//      flac.forceOverwrite = true
      return flac.arguments
    case .opus:
      return ["--bitrate", bitrate.description, "--discard-comments", input.path, output.path]
    case .aac:
      return ["-nostdin", "-i", input.path,
              "-c:a", ffmpegCodecs.fdkAAC ? "libfdk_aac" : "aac",
              "-b:a", "\(bitrate)k", output.path]
    }
  }
}
