import Foundation
import ExecutableLauncher
import MediaUtility
import MediaTools

struct AudioConverter {
  let input: URL
  let output: URL
  let codec: ChocoConfiguration.AudioPreference.AudioCodec
  let lossyAudioChannelBitrate: Int
  //  let downmixMethod: ChocoConfiguration.AudioPreference.DownmixMethod
  let preferedTool: ChocoConfiguration.AudioPreference.PreferedTool
  let ffmpegCodecs: ChocoMuxer.FFmpegCodecs
  let channelCount: Int
  let trackIndex: Int
  
  private var ffmpeg: AnyExecutable {
    var options = [FFmpeg.InputOutputOption]()
    switch codec {
    case .flac:
      break
    case .opus:
      let codec: String
      if ffmpegCodecs.libopus {
        codec = "libopus"
      } else {
        codec = "opus"
        options.append(.strict(level: .experimental))
      }
      options.append(.codec(codec, streamSpecifier: .streamType(.audio)))
    case .aac:
      options.append(.codec(ffmpegCodecs.aacCodec, streamSpecifier: .streamType(.audio)))
    }
    options.append(.bitrate("\(bitrate)k", streamSpecifier: .streamType(.audio)))
    return FFmpeg(global: .init(enableStdin: false), ios: [
      .input(url: input.path),
      .output(url: output.path, options: options)
    ])
    .eraseToAnyExecutable()
  }
  
  var executable: AnyExecutable {
    switch preferedTool {
    case .official:
      switch codec {
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
    channelCount * lossyAudioChannelBitrate
  }
}
