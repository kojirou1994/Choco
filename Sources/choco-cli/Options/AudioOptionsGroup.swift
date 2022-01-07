import ArgumentParser
import libChoco

extension ChocoCommonOptions.AudioOptions.AudioCodec: ExpressibleByArgument {}

extension ChocoCommonOptions.AudioOptions.DownmixMethod: ExpressibleByArgument {}

extension ChocoCommonOptions.AudioOptions.LosslessAudioCodec: EnumerableFlag {
  public static func name(for value: Self) -> NameSpecification {
    .customLong("keep-\(value.rawValue)")
  }
}

extension ChocoCommonOptions.AudioOptions.GrossLossyAudioCodec: EnumerableFlag {
  public static func name(for value: Self) -> NameSpecification {
    .customLong("fix-\(value.rawValue)")
  }
}

struct AudioOptionsGroup: ParsableArguments {

  @Flag
  var protectedCodecs: [ChocoCommonOptions.AudioOptions.LosslessAudioCodec] = []

  @Flag
  var fixCodecs: [ChocoCommonOptions.AudioOptions.GrossLossyAudioCodec] = []
  
  @Flag(inversion: FlagInversion.prefixedNo, help: "Encode audio.")
  var encodeAudio: Bool = true

  @Option(help: "Codec for lossless audio track, \(ChocoCommonOptions.AudioOptions.AudioCodec.availableValues)")
  var audioCodec: ChocoCommonOptions.AudioOptions.AudioCodec = .flac

  @Option(help: "Codec for fixing lossy audio track, \(ChocoCommonOptions.AudioOptions.AudioCodec.availableValues)")
  var audioLossyCodec: ChocoCommonOptions.AudioOptions.AudioCodec = .opus

  @Option(help: "Audio kbps per channel")
  var audioBitrate: Int = 128

  @Option(help: "Downmix method, \(ChocoCommonOptions.AudioOptions.DownmixMethod.availableValues)")
  var downmix: ChocoCommonOptions.AudioOptions.DownmixMethod = .disable

  @Flag(help: "Remove dts when another same spec truehd exists")
  var removeExtraDTS: Bool = false
  
  var options: ChocoCommonOptions.AudioOptions {
    .init(encodeAudio: encodeAudio, codec: audioCodec, codecForLossyAudio: audioLossyCodec, lossyAudioChannelBitrate: audioBitrate, downmixMethod: downmix, preferedTool: .official, protectedCodecs: .init(protectedCodecs), fixCodecs: .init(fixCodecs), removeExtraDTS: removeExtraDTS)
  }
}
