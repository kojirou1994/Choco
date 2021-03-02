import Foundation
import ExecutableLauncher
import MediaUtility
import MediaTools

struct AudioConverter {
  let input: URL
  let output: URL
  let preference: ChocoConfiguration.AudioPreference
  let ffmpegCodecs: ChocoMuxer.FFmpegCodecs
  let channelCount: Int
  let trackIndex: Int

  private var ffmpeg: AnyExecutable {
    let arguments: [String]
    switch preference.codec {
    case .flac:
      arguments = ["-nostdin", "-i", input.path, output.path]
    case .opus:
      if ffmpegCodecs.libopus {
        arguments = ["-nostdin",
                     "-i", input.path,
                     "-c:a", "libopus",
                     "-b:a", "\(bitrate)k", output.path]
      } else {
        arguments = ["-nostdin", "-strict", "-2",
                     "-i", input.path,
                     "-c:a", "opus",
                     "-b:a", "\(bitrate)k", output.path]
      }
    case .aac:
      arguments = ["-nostdin", "-i", input.path,
                   "-c:a", ffmpegCodecs.aacCodec,
                   "-b:a", "\(bitrate)k", output.path]
    }
    return .init(executableName: "ffmpeg", arguments: arguments)
  }

  var executable: AnyExecutable {
    switch preference.preferedTool {
    case .official:
      switch preference.codec {
      case .flac:
        var flac = FlacEncoder(input: input.path, output: output.path)
        flac.level = 8
        return flac.eraseToAnyExecutable()
      case .opus:
        return .init(executableName: "opusenc", arguments: ["--bitrate", bitrate.description, "--discard-comments", input.path, output.path])
      case .aac:
        return ffmpeg
      }
    case .ffmpeg:
      return ffmpeg
    }
  }

  private var bitrate: Int {
    channelCount * preference.lossyAudioChannelBitrate
  }
}
