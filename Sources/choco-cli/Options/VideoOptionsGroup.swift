import ArgumentParser
import libChoco

extension ChocoCommonOptions.VideoOptions.Codec: ExpressibleByArgument {}
extension ChocoCommonOptions.VideoOptions.CodecPreset: ExpressibleByArgument {}
extension ChocoCommonOptions.VideoOptions.ColorPreset: ExpressibleByArgument {}
extension ChocoCommonOptions.VideoOptions.VideoProcess: ExpressibleByArgument {}
extension ChocoCommonOptions.VideoOptions.VideoQuality: ExpressibleByArgument {}

struct VideoOptionsGroup: ParsableArguments {
  @Option(name: [.customShort("v"), .long], help: "Video processing method, \(ChocoCommonOptions.VideoOptions.VideoProcess.availableValues).")
  var videoProcess: ChocoCommonOptions.VideoOptions.VideoProcess = .copy

  @Option(help: "FFmpeg video filter argument.")
  var videoFilter: String = ""

  @Option(help: "Codec for video track, \(ChocoCommonOptions.VideoOptions.Codec.availableValues)")
  var videoCodec: ChocoCommonOptions.VideoOptions.Codec = .x265

  @Option(help: "Color preset for video track, \(ChocoCommonOptions.VideoOptions.ColorPreset.availableValues)")
  var videoColor: ChocoCommonOptions.VideoOptions.ColorPreset?

  @Option(help: "VS script template path.")
  var encodeScript: String?

  @Option(help: "Codec preset for video track, \(ChocoCommonOptions.VideoOptions.CodecPreset.availableValues)")
  var videoPreset: ChocoCommonOptions.VideoOptions.CodecPreset = .medium

  @Option(help: "Codec crf for video track, eg. crf:19 or bitrate:5000k")
  var videoQuality: ChocoCommonOptions.VideoOptions.VideoQuality = .crf(18)

  @Option(help: "Tune for video encoder, std or choco-provided, x265-\(ChocoCommonOptions.VideoOptions.ChocoX265Tune.availableValues)")
  var videoTune: String?

  @Option(help: "Profile for video encoder")
  var videoProfile: String?

  @Flag(help: "Auto crop video track")
  var autoCrop: Bool = false

  @Flag(help: "Only encode progressive video track.")
  var progOnly: Bool = false

  @Flag(name: .customLong("keep-pix-fmt"), help: "Always keep input video's pixel format.")
  var keepPixelFormat: Bool = false

  @Flag(help: "Use ffmpeg integrated Vapoursynth")
  var useIntergratedVapoursynth: Bool = false

  private func scriptTemplate() -> String? {
    // replace error
    try? encodeScript
      .map { try String(contentsOfFile: $0) }
  }

  var options: ChocoCommonOptions.VideoOptions {
    .init(process: videoProcess, progressiveOnly: progOnly, filter: videoFilter, encodeScript: scriptTemplate(), codec: videoCodec, preset: videoPreset, colorPreset: videoColor, tune: videoTune, profile: videoProfile, quality: videoQuality, autoCrop: autoCrop, keepPixelFormat: keepPixelFormat, useIntergratedVapoursynth: useIntergratedVapoursynth)
  }
}
