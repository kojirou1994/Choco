import Foundation
import ISOCodes
import Logging
import MediaTools

internal let ChocoTempDirectoryName = "tmp_choco"

public struct BDMVRemuxOptions {
  public init(splitPlaylist: Bool, organizeOutput: Bool, mainTitleOnly: Bool, directMode: Bool) {
    self.splitPlaylist = splitPlaylist
    self.organizeOutput = organizeOutput
    self.mainTitleOnly = mainTitleOnly
    self.directMode = directMode
  }

  public let splitPlaylist: Bool
  public let organizeOutput: Bool
  public let mainTitleOnly: Bool
  public let directMode: Bool
}

public struct FileRemuxOptions {
  public init(recursive: Bool, copyNormalFiles: Bool, copyOverwrite: Bool, removeSourceFiles: Bool, fileTypes: Set<String>) {
    self.recursive = recursive
    self.copyNormalFiles = copyNormalFiles
    self.copyOverwrite = copyOverwrite
    self.removeSourceFiles = removeSourceFiles
    self.fileTypes = fileTypes
  }

  public let recursive: Bool
  public let copyNormalFiles: Bool
  public let copyOverwrite: Bool
  public let removeSourceFiles: Bool
  public let fileTypes: Set<String>

  public static var defaultFileTypes: Set<String> {
    ["mkv", "mp4", "ts", "m2ts", "vob"]
  }
}

public struct ChocoCommonOptions {

  public let io: IOOptions
  public let meta: MetaOptions
  public let video: VideoOptions
  public let audio: AudioOptions
  public let language: LanguageOptions

  public init(io: ChocoCommonOptions.IOOptions, meta: ChocoCommonOptions.MetaOptions, video: ChocoCommonOptions.VideoOptions, audio: ChocoCommonOptions.AudioOptions, language: ChocoCommonOptions.LanguageOptions) {
    self.io = io
    self.meta = meta
    self.video = video
    self.audio = audio
    self.language = language
  }
}

extension ChocoCommonOptions {
  public struct IOOptions: CustomStringConvertible {
    public init(outputRootDirectory: URL, temperoraryDirectory: URL, split: ChocoSplit?, ignoreWarning: Bool, keepTempMethod: KeepTempMethod) {
      self.outputRootDirectory = outputRootDirectory
      self.temperoraryDirectory = temperoraryDirectory.appendingPathComponent(ChocoTempDirectoryName)
      self.split = split
      self.ignoreWarning = ignoreWarning
      self.keepTempMethod = keepTempMethod
    }

    public var description: String { "" }

    public let outputRootDirectory: URL
    public let temperoraryDirectory: URL

    public let split: ChocoSplit?
    public let ignoreWarning: Bool
    public let keepTempMethod: KeepTempMethod

    public enum KeepTempMethod: String, CaseIterable, CustomStringConvertible {
      case always
      case failed
      case never

      public var description: String {
        rawValue
      }
    }
  }
}

extension ChocoCommonOptions {

  public struct MetaOptions: CustomStringConvertible {
    public init(keepMetadatas: Set<Metadata>,
                sortTrackType: Bool,
                minPGSCount: Int) {
      self.keepMetadatas = keepMetadatas
      self.sortTrackType = sortTrackType
      self.minPGSCount = minPGSCount
    }

    public enum Metadata: String, CaseIterable {
      case attachments
      case tags
      case trackName
      case videoLanguage
      case title
      case disabled
    }

    private let keepMetadatas: Set<Metadata>
    public let sortTrackType: Bool
    public let minPGSCount: Int

    public func keep(_ metadata: Metadata) -> Bool {
      keepMetadatas.contains(metadata)
    }

    public var description: String {
      ""
    }
  }

}

extension ChocoCommonOptions {

  public struct AudioOptions: CustomStringConvertible {
    public init(encodeAudio: Bool,
                codec: AudioCodec, codecForLossyAudio: AudioCodec?,
                lossyAudioChannelBitrate: Int, reduceBitrate: Bool,
                downmixMethod: DownmixMethod,
                preferedTool: PreferedTool,
                protectedCodecs: Set<LosslessAudioCodec>, fixCodecs: Set<GrossLossyAudioCodec>,
                checkAllTracks: Bool = false,
                removeExtraDTS: Bool) {
      self.encodeAudio = encodeAudio
      self.codec = codec
      self.codecForLossyAudio = codecForLossyAudio ?? codec
      self.lossyAudioChannelBitrate = lossyAudioChannelBitrate
      self.reduceBitrate = reduceBitrate
      self.downmixMethod = downmixMethod
      self.preferedTool = preferedTool
      self.protectedCodecs = protectedCodecs
      self.fixCodecs = fixCodecs
      self.removeExtraDTS = removeExtraDTS
      self.checkAllTracks = checkAllTracks
    }

    public let encodeAudio: Bool
    public let codec: AudioCodec
    public let codecForLossyAudio: AudioCodec
    public let lossyAudioChannelBitrate: Int
    public let reduceBitrate: Bool
    public let downmixMethod: DownmixMethod
    public let preferedTool: PreferedTool
    public let protectedCodecs: Set<LosslessAudioCodec>
    public let fixCodecs: Set<GrossLossyAudioCodec>
    public let removeExtraDTS: Bool
    private let checkAllTracks: Bool

    func shouldCopy(_ codec: LosslessAudioCodec) -> Bool {
      protectedCodecs.contains(codec)
    }

    func shouldFix(_ codec: GrossLossyAudioCodec) -> Bool {
      fixCodecs.contains(codec)
    }

    public var description: String {
      if !encodeAudio {
        return "Copy"
      } else {
        var str = "Encode(codec: \(codec)"
        if codec != .flac {
          str.append(", bitrate per channel: \(lossyAudioChannelBitrate)k")
        }
        str.append(", downmix: \(downmixMethod)")
        if !protectedCodecs.isEmpty {
          str.append(", protectedAudio: \(protectedCodecs)")
        }
        if !fixCodecs.isEmpty {
          str.append(", fixingAudio: \(fixCodecs), lossyAudioCodec: \(codecForLossyAudio)")
        }
        str.append(")")
        return str
      }
    }

    public enum PreferedTool: String, CaseIterable, CustomStringConvertible {
      case ffmpeg
      case official

      public var description: String { rawValue }
    }

    public enum LosslessAudioCodec: String, CaseIterable, CustomStringConvertible {
      case flac
      case dtshd
      case truehd

      public var description: String { rawValue }
    }

    public enum GrossLossyAudioCodec: String, CaseIterable, CustomStringConvertible {
      case dts

      public var description: String { rawValue }
    }

    public enum AudioCodec: String, CaseIterable, CustomStringConvertible {
      case flac
      case alac
      case opus
      case aac

      public var description: String { rawValue }
    }

    public enum DownmixMethod: String, CaseIterable, CustomStringConvertible {
      case disable
      case auto
      case all

      public var description: String { rawValue }
    }
  }

  public struct LanguageOptions {
    public init(primaryLanguage: Language?, preventNoAudio: Bool, all: LanguageFilter?, audio: LanguageFilter?, subtitles: LanguageFilter?) {
      self.primaryLanguage = primaryLanguage
      self.preventNoAudio = preventNoAudio
      self.all = all
      self.audio = audio
      self.subtitles = subtitles
    }

    public let primaryLanguage: Language?
    public let preventNoAudio: Bool
    public let all: LanguageFilter?
    public let audio: LanguageFilter?
    public let subtitles: LanguageFilter?

    public func shouldMuxTrack(trackLanguage: Language, trackType: MediaTrackType, primaryLanguage: Language, forcePrimary: Bool) -> Bool {
      // und is always OK
      if trackLanguage == .und {
        return true
      }
      // video is always OK
      if trackType == .video {
        return true
      }

      // primaryLanguage is file's first audio track's lang
      let finalPrimaryLanguage: Language
      if let overridePrimaryLang = self.primaryLanguage, !forcePrimary {
        finalPrimaryLanguage = overridePrimaryLang
      } else {
        finalPrimaryLanguage = primaryLanguage
      }

      func shouldMuxTrack(filter: LanguageFilter?) -> Bool {
        guard let filter = filter else {
          return true
        }

        if filter.isExcluded {
          return !filter.languages.contains(trackLanguage)
        } else {
          return trackLanguage == finalPrimaryLanguage || filter.languages.contains(trackLanguage)
        }
      }

      if !shouldMuxTrack(filter: all) {
        return false
      }
      if trackType == .audio, !shouldMuxTrack(filter: audio) {
        return false
      }
      if trackType == .subtitles, !shouldMuxTrack(filter: subtitles) {
        return false
      }

      return true
    }
  }

  public struct VideoOptions: CustomStringConvertible {
    public init(process: VideoProcess,
                progressiveOnly: Bool,
                filter: String,
                encodeScript: String?,
                codec: Codec,
                preset: String?,
                colorPreset: ColorPreset?,
                tune: String?, profile: String?,
                params: String?,
                avcodecFlags: [String],
                quality: VideoQuality,
                autoCrop: Bool, cropLimit: UInt8, cropRound: UInt8, cropSkip: UInt,
                keepPixelFormat: Bool,
                useIntergratedVapoursynth: Bool) {
      self.process = process
      self.progressiveOnly = progressiveOnly
      self.filter = filter
      self.encodeScript = encodeScript
      self.codec = codec
      self.preset = preset
      self.colorPreset = colorPreset
      self.quality = quality
      self.autoCrop = autoCrop
      self.cropLimit = cropLimit
      self.cropRound = cropRound
      self.cropSkip = cropSkip
      self.tune = tune
      self.profile = profile
      self.params = params
      self.avcodecFlags = avcodecFlags
      self.keepPixelFormat = keepPixelFormat
      self.useIntergratedVapoursynth = useIntergratedVapoursynth
    }

    public let process: VideoProcess
    public let progressiveOnly: Bool
    public let filter: String
    public let encodeScript: String?
    public let codec: Codec
    public let tune: String?
    public let profile: String?
    public let params: String?
    public let avcodecFlags: [String]
    public let preset: String?
    public let colorPreset: ColorPreset?
    public let quality: VideoQuality
    public let autoCrop: Bool
    public let cropLimit: UInt8
    public let cropRound: UInt8
    public let cropSkip: UInt
    public let keepPixelFormat: Bool
    public let useIntergratedVapoursynth: Bool

    public var description: String {
      switch process {
      case .none:
        return "Disabled"
      case .copy:
        return "Copy"
      case .encode:
        var str = "Encode(codec: \(codec), quality: \(quality), preset: \(preset?.description ?? "nil")"
        if let v = profile {
          str.append(", profile: \(v)")
        }
        if let v = tune {
          str.append(", tune: \(v)")
        }
        if autoCrop {
          str.append(", autocrop")
        }
        if encodeScript != nil {
          str.append(", vapoursynth script template loaded")
        }
        str.append(")")
        return str
      }
    }

    public enum VideoQuality: RawRepresentable, CustomStringConvertible {
      case crf(Double)
      case bitrate(String)

      public init?(rawValue: String) {
        guard let (left, right) = rawValue.splitTwoPart(":") else {
          return nil
        }
        switch left {
        case "crf":
          guard let crf = Double(right) else {
            return nil
          }
          self = .crf(crf)
        case "bitrate":
          guard !right.isEmpty else {
            return nil
          }
          self = .bitrate(String(right))
        default:
          return nil
        }
      }

      public var rawValue: String {
        switch self {
        case .crf(let crf):
          return "crf:\(crf)"
        case .bitrate(let bitrate):
          return "bitrate:\(bitrate)"
        }
      }

      public var description: String { rawValue }
    }

    public enum VideoProcess: String, CaseIterable, CustomStringConvertible {
      case copy
      case encode
      case none

      public var description: String { rawValue }
    }

    public enum Codec: String, CaseIterable, CustomStringConvertible {
      case x265
      case x264
      case h264VT = "h264_vt"
      case hevcVT = "hevc_vt"
      case h264VTSW = "h264_vt_sw"
      case hevcVTSW = "hevc_vt_sw"

      public var description: String { rawValue }
    }

    public enum ColorPreset: String, CaseIterable, CustomStringConvertible {
      case bt709
      case bt709RGB

      // --colormatrix in x265
      var colorspace: String {
        switch self {
        case .bt709:
          return "bt709"
        case .bt709RGB:
          return "rgb"
        }
      }

      // --colorprim in x265
      var colorPrimaries: String {
        switch self {
        case .bt709, .bt709RGB:
          return "bt709"
        }
      }

      // --transfer in x265
      var colorTransferCharacteristics: String {
        switch self {
        case .bt709, .bt709RGB:
          return "bt709"
        }
      }

      var colorRange: String {
        switch self {
        case .bt709, .bt709RGB:
          return "tv"
        }
      }

      public var description: String { rawValue }
    }

  }

}

extension ChocoCommonOptions.AudioOptions.AudioCodec {
  var outputFileExtension: String {
    switch self {
    case .flac:
      return "flac"
    case .opus:
      return "opus"
    case .aac, .alac:
      return "m4a"
    }
  }
}

extension ChocoCommonOptions.VideoOptions.Codec {

  var supportsCrf: Bool {
    switch self {
    case .h264VT, .hevcVT, .h264VTSW, .hevcVTSW:
      return false
    default:
      return true
    }
  }

  var ffCodec: String {
    switch self {
    case .x264:
      return "libx264"
    case .x265:
      return "libx265"
    case .h264VT, .h264VTSW:
      return "h264_videotoolbox"
    case .hevcVT, .hevcVTSW:
      return "hevc_videotoolbox"
    }
  }

  var recommendedPixelFormat: String {
    switch self {
    case .x264, .h264VT, .h264VTSW:
      return "yuv420p"
    case .x265:
      return "yuv420p10le"
    case .hevcVT, .hevcVTSW:
      return "p010le"
    }
  }

  var depth: Int {
    switch self {
    case .x264, .h264VT, .h264VTSW:
      return 8
    case .x265, .hevcVT, .hevcVTSW:
      return 10
    }
  }
}

extension ChocoCommonOptions.VideoOptions {

  func ffmpegIOOptions(cropInfo: CropInfo?) -> [FFmpeg.InputOutputOption] {
    var options = [FFmpeg.InputOutputOption]()
    options.append(.codec(codec.ffCodec, streamSpecifier: .streamType(.video)))
    if !keepPixelFormat {
      options.append(.pixelFormat(codec.recommendedPixelFormat, streamSpecifier: nil))
    }

    // filter
    do {
      var usedFilters = [String]()
      if !filter.isEmpty {
        usedFilters.append(filter)
      }
      if let cropInfo = cropInfo {
        usedFilters.append(cropInfo.ffmpegArgument)
      }
      if !usedFilters.isEmpty {
        options.append(.filter(filtergraph: usedFilters.joined(separator: ","), streamSpecifier: .streamType(.video)))
      }
    }

    // color
    colorPreset.map { colorPreset in
      options.append(contentsOf: [
        .colorspace(colorPreset.colorspace, streamSpecifier: .streamType(.video)),
        .colorPrimaries(colorPreset.colorPrimaries, streamSpecifier: .streamType(.video)),
        .colorTransferCharacteristics(colorPreset.colorTransferCharacteristics, streamSpecifier: .streamType(.video)),
        .avOption(name: "color_range", value: colorPreset.colorRange, streamSpecifier: .streamType(.video)),
      ])
    }

    // quality
    switch quality {
    case .crf(let crf):
      options.append(.avOption(name: "crf", value: crf.description, streamSpecifier: nil))
    case .bitrate(let bitrate):
      // must set :v to silence warning
      options.append(.bitrate(bitrate, streamSpecifier: .streamType(.video)))
    }

    /*
     -profile 2 for hevcVT
     */
    switch codec {
    case .h264VTSW, .hevcVTSW:
      options.append(.avOption(name: "allow_sw", value: "1", streamSpecifier: nil))
      options.append(.avOption(name: "require_sw", value: "1", streamSpecifier: nil))
    case .x265, .x264:
      if let preset = self.preset {
        options.append(.avOption(name: "preset", value: preset, streamSpecifier: nil))
      }
      if let tune = self.tune {
        options.append(.avOption(name: "tune", value: tune, streamSpecifier: nil))
      }
      if let params = self.params {
        options.append(.avOption(name: "\(codec.rawValue)-params",
                                 value: params,
                                 streamSpecifier: nil))
      }
    default: break
    }

    // apple compatibility
    if codec == .x265 {
      options.append(.avOption(name: "tag", value: "hvc1", streamSpecifier: nil))
    }

    if let profile = self.profile {
      options.append(.avOption(name: "profile", value: profile, streamSpecifier: nil))
    }

    avcodecFlags.forEach { flag in
      options.append(.raw(flag))
    }

    return options
  }

}
