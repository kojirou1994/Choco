import ArgumentParser
import libChoco

extension ChocoCommonOptions.VideoOptions.Codec: ExpressibleByArgument {}
extension ChocoCommonOptions.VideoOptions.ColorPreset: ExpressibleByArgument {}
extension ChocoCommonOptions.VideoOptions.VideoProcess: ExpressibleByArgument {}
extension ChocoCommonOptions.VideoOptions.VideoQuality: ExpressibleByArgument {}
extension ChocoCommonOptions.VideoOptions.VideoSAR: ExpressibleByArgument {}

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

  @Option(help: "Codec preset for video track")
  var videoPreset: String?

  @Option(help: "SAR handling for video track, \(ChocoCommonOptions.VideoOptions.VideoSAR.availableValues)")
  var videoSAR: ChocoCommonOptions.VideoOptions.VideoSAR = .source

  @Option(help: "Codec crf for video track, eg. crf:19 or bitrate:5000k")
  var videoQuality: ChocoCommonOptions.VideoOptions.VideoQuality = .crf(18)

  @Option(help: "Tune for video encoder.")
  var videoTune: String?

  @Option(help: "Profile for video encoder")
  var videoProfile: String?

  @Option(help: "Parameters for video encoder")
  var videoParams: String?

  @Option(name: .customLong("Xavcodec", withSingleDash: true),
          parsing: .unconditionalSingleValue,
          help: "Pass flag through to ffmpeg")
  var avcodecFlags: [String] = []

  @Flag(help: "Auto crop video track")
  var autoCrop: Bool = false

  @Option(help: "FFmpeg base video filter for cropping, videoFilter is used by default.")
  var cropFilter: String?

  @Option(help: "Set higher black value threshold, which can be optionally specified from nothing (0) to everything (255 for 8-bit based formats).")
  var cropLimit: Double?

  @Option(help: "")
  var cropRound: UInt8 = 2

  @Option(help: "")
  var cropSkip: UInt = 0

  @Option(help: "")
  var cropFrames: UInt?

  @Flag(help: "Only encode progressive video track.")
  var progOnly: Bool = false

  @Flag(name: .customLong("keep-pix-fmt"), help: "Always keep input video's pixel format.")
  var keepPixelFormat: Bool = false

  @Flag(help: "Use ffmpeg integrated Vapoursynth")
  var useIntergratedVapoursynth: Bool = false

  private func scriptTemplate() throws -> String? {
    try encodeScript
      .map { try String(contentsOfFile: $0) }
  }

  func getOptions() throws -> ChocoCommonOptions.VideoOptions {
    try .init(process: videoProcess, progressiveOnly: progOnly, filter: videoFilter, cropFilter: cropFilter, encodeScript: scriptTemplate(), codec: videoCodec, preset: videoPreset, sar: videoSAR, colorPreset: videoColor, tune: videoTune, profile: videoProfile, params: videoParams, avcodecFlags: avcodecFlags, quality: videoQuality, autoCrop: autoCrop, cropLimit: cropLimit, cropRound: cropRound, cropSkip: cropSkip, cropFrames: cropFrames, keepPixelFormat: keepPixelFormat, useIntergratedVapoursynth: useIntergratedVapoursynth)
  }
}
