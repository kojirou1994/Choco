import Foundation
import ISOCodes
import Logging
import MediaTools

internal let ChocoTempDirectoryName = "choco_tmp"

public struct ChocoConfiguration {

  public let outputRootDirectory: URL
  public let temperoraryDirectory: URL
  public let mode: ChocoWorkMode
  public let splitBDMV: Bool
  public let split: ChocoSplit?
  public let videoPreference: VideoPreference
  public let audioPreference: AudioPreference
  public let languagePreference: LanguagePreference

  public let ignoreInputPrimaryLang: Bool
  public let copyDirectoryFile: Bool
  public let deleteAfterRemux: Bool
  public let keepTrackName: Bool
  public let keepVideoLanguage: Bool
  public let removeExtraDTS: Bool

  public let ignoreWarning: Bool
  public let organizeOutput: Bool
  public let mainTitleOnly: Bool
  public let keepTempMethod: KeepTempMethod

  public init(outputRootDirectory: URL, temperoraryDirectory: URL, mode: ChocoWorkMode,
              splitBDMV: Bool,
              videoPreference: VideoPreference,
              audioPreference: AudioPreference,
              split: ChocoSplit?, preferedLanguages: LanguageSet, excludeLanguages: LanguageSet?,
              ignoreInputPrimaryLang: Bool,
              copyDirectoryFile: Bool, deleteAfterRemux: Bool,
              keepTrackName: Bool, keepVideoLanguage: Bool, removeExtraDTS: Bool, ignoreWarning: Bool, organize: Bool, mainTitleOnly: Bool,
              keepTempMethod: KeepTempMethod) {
    self.outputRootDirectory = outputRootDirectory
    self.temperoraryDirectory = temperoraryDirectory.appendingPathComponent(ChocoTempDirectoryName)
    self.mode = mode
    self.splitBDMV = splitBDMV
    self.split = split
    self.videoPreference = videoPreference
    self.audioPreference = audioPreference
    self.languagePreference = .init(preferedLanguages: preferedLanguages, excludeLanguages: excludeLanguages)
    self.ignoreInputPrimaryLang = ignoreInputPrimaryLang
    self.copyDirectoryFile = copyDirectoryFile
    self.deleteAfterRemux = deleteAfterRemux
    self.keepTrackName = keepTrackName
    self.keepVideoLanguage = keepVideoLanguage
    self.removeExtraDTS = removeExtraDTS
    self.ignoreWarning = ignoreWarning
    self.organizeOutput = organize
    self.mainTitleOnly = mainTitleOnly
    self.keepTempMethod = keepTempMethod
  }

}

extension ChocoConfiguration {

  public struct MetaPreference: CustomStringConvertible {
    public var description: String {
      ""
    }
  }

  public enum KeepTempMethod: String, CaseIterable, CustomStringConvertible {
    case always
    case failed
    case never

    public var description: String {
      rawValue
    }
  }
}

extension ChocoConfiguration {

  public struct AudioPreference: CustomStringConvertible {
    public init(encodeAudio: Bool, codec: ChocoConfiguration.AudioPreference.AudioCodec,
                codecForLossyAudio: AudioCodec?, lossyAudioChannelBitrate: Int, downmixMethod: ChocoConfiguration.AudioPreference.DownmixMethod, preferedTool: ChocoConfiguration.AudioPreference.PreferedTool, protectedCodecs: Set<ChocoConfiguration.AudioPreference.LosslessAudioCodec>, fixCodecs: Set<ChocoConfiguration.AudioPreference.GrossLossyAudioCodec>) {
      self.encodeAudio = encodeAudio
      self.codec = codec
      self.codecForLossyAudio = codecForLossyAudio ?? codec
      self.lossyAudioChannelBitrate = lossyAudioChannelBitrate
      self.downmixMethod = downmixMethod
      self.preferedTool = preferedTool
      self.protectedCodecs = protectedCodecs
      self.fixCodecs = fixCodecs
    }

    public let encodeAudio: Bool
    public let codec: AudioCodec
    public let codecForLossyAudio: AudioCodec
    public let lossyAudioChannelBitrate: Int
    public let downmixMethod: DownmixMethod
    public let preferedTool: PreferedTool
    public let protectedCodecs: Set<LosslessAudioCodec>
    public let fixCodecs: Set<GrossLossyAudioCodec>

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

  public struct LanguagePreference {
    public init(preferedLanguages: LanguageSet, excludeLanguages: LanguageSet?) {
      self.preferedLanguages = preferedLanguages
      self.excludeLanguages = excludeLanguages
    }

    private let preferedLanguages: LanguageSet
    private let excludeLanguages: LanguageSet?

    func generatePrimaryLanguages<C>(with otherLanguages: C, addUnd: Bool, logger: Logger? = nil) -> Set<Language> where C: Collection, C.Element == Language {
      var result = preferedLanguages.languages
      if addUnd {
        result.insert(.und)
      }
      otherLanguages.forEach { l in
        result.insert(l)
      }
      excludeLanguages?.languages.forEach { l in
        if l == .und {
          logger?.warning("Warning: excluding und language!")
        }
        result.remove(l)
      }
      return result
    }
  }

  public struct VideoPreference: CustomStringConvertible {
    public init(videoProcess: VideoProcess, encodeScript: String?,
                codec: Codec,
                preset: CodecPreset,
                colorPreset: ColorPreset?,
                tune: String?, profile: String?,
                quality: VideoQuality, autoCrop: Bool,
                useSoftVT: Bool,
                useIntergratedVapoursynth: Bool) {
      self.videoProcess = videoProcess
      self.encodeScript = encodeScript
      self.codec = codec
      self.preset = preset
      self.colorPreset = colorPreset
      self.quality = quality
      self.autoCrop = autoCrop
      self.tune = tune
      self.profile = profile
      self.useSoftVT = useSoftVT
      self.useIntergratedVapoursynth = useIntergratedVapoursynth
    }

    public let videoProcess: VideoProcess
    public let encodeScript: String?
    public let codec: Codec
    public let tune: String?
    public let profile: String?
    public let preset: CodecPreset
    public let colorPreset: ColorPreset?
    public let quality: VideoQuality
    public let autoCrop: Bool
    public let useSoftVT: Bool
    public let useIntergratedVapoursynth: Bool

    public var description: String {
      switch videoProcess {
      case .none:
        return "Disabled"
      case .copy:
        return "Copy"
      case .encode:
        var str = "Encode(codec: \(codec), quality: \(quality), preset: \(preset)"
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
      case h264VT
      case hevcVT

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


    public enum CodecPreset: String, CaseIterable, CustomStringConvertible {
      case ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow, placebo

      public var description: String { rawValue }
    }
  }

}

extension ChocoConfiguration.AudioPreference.AudioCodec {
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

extension ChocoConfiguration.VideoPreference.Codec {

  var supportsCrf: Bool {
    switch self {
    case .h264VT:
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
    case .h264VT:
      return "h264_videotoolbox"
    case .hevcVT:
      return "hevc_videotoolbox"
    }
  }

  var pixelFormat: String {
    switch self {
    case .x264, .h264VT:
      return "yuv420p"
    case .x265:
      return "yuv420p10le"
    case .hevcVT:
      return "p010le"
    }
  }

  var depth: Int {
    switch self {
    case .x264, .h264VT:
      return 8
    case .x265, .hevcVT:
      return 10
    }
  }
}

extension ChocoConfiguration.VideoPreference {

  public enum ChocoX265Tune: String, CaseIterable {
    case vcbs = "vcb-s"
    case vcbsPlus = "vcb-s+"
    case littlepox
    case littlepoxPlus = "littlepox+"
    /// ref: https://tieba.baidu.com/p/6627144750?see_lz=1
    case flyabc
    case flyabcPlus = "flyabc+"
  }

  var ffmpegIOOption: [FFmpeg.InputOutputOption] {
    var options = [FFmpeg.InputOutputOption]()
    options.append(.codec(codec.ffCodec, streamSpecifier: .streamType(.video)))
    options.append(.pixelFormat(codec.pixelFormat, streamSpecifier: nil))

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
      options.append(.bitrate(bitrate, streamSpecifier: .streamType(.video)))
    }

    /*
     -profile 2 for hevcVT
     */
    switch codec {
    case .h264VT, .hevcVT:
      if useSoftVT {
        options.append(.avOption(name: "allow_sw", value: "1", streamSpecifier: nil))
        options.append(.avOption(name: "require_sw", value: "1", streamSpecifier: nil))
      }
    case .x265, .x264:
      options.append(.avOption(name: "preset", value: preset.rawValue, streamSpecifier: nil))
    }

    if let tune = self.tune {
      if codec == .x265, let chocoTune = ChocoX265Tune(rawValue: tune) {
        options.append(.avOption(name: "x265-params",
                                 value: chocoTune.parameterDictionary(preset: preset.rawValue)
                                  .map { (key, value) in
                                    "\(key.rawValue)=\(String(describing: value))"
                                  }.joined(separator: ":"),
                                 streamSpecifier: nil))
      } else {
        options.append(.avOption(name: "tune", value: tune, streamSpecifier: nil))
      }
    }

    if let profile = self.profile {
      options.append(.avOption(name: "profile", value: profile, streamSpecifier: nil))
    }

    return options
  }

}

import CX265

extension ChocoConfiguration.VideoPreference.ChocoX265Tune {

  enum X265ParameterKey: String {
    case merange
    case aqStrength = "aq-strength"
    case rd
    case rdoqLevel = "rdoq-level"
    case sao
    case noSao = "no-sao"
    case selectiveSao = "selective-sao"
    case bframes
    case strongIntraSmoothing = "strong-intra-smoothing"
    case tuQTMaxInterDepth = "tu-inter-depth"
    case tuQTMaxIntraDepth = "tu-intra-depth"
    case maxNumMergeCand = "max-merge"
    case subme
    case keyint
    case minKeyint = "min-keyint"
    case openGOP = "open-gop"
    case ctu
    case maxTuSize = "max-tu-size"
    case qgSize = "qg-size"
    case cbqpoffs, crqpoffs, pbratio, weightb,
         ref, rect, scenecut, me, deblock, rskip
    case psyRd = "psy-rd"
    case psyRdoq = "psy-rdoq"
    case lookaheadDepth = "rc-lookahead"
    case bIntra = "b-intra"
    case limitTu = "limit-tu"
    case lookaheadSlices = "lookahead-slices"
    case noStrongIntraSmoothing = "no-strong-intra-smoothing"
    case earlySkip = "early-skip"
  }

  func parameterDictionary(preset: String) -> [X265ParameterKey : Any] {

    var libx265Param = x265_param()
    x265_param_default_preset(&libx265Param, preset, nil)

    var x265Params = [X265ParameterKey : Any]()

    switch self {
    case .vcbs, .vcbsPlus, .littlepox, .littlepoxPlus:
      x265Params[.merange] = 25
      x265Params[.aqStrength] = 0.8
      if libx265Param.rdLevel < 4 {
        x265Params[.rd] = 4
      }
      x265Params[.rdoqLevel] = 2
      x265Params[.sao] = 0
      x265Params[.strongIntraSmoothing] = 0

      for _ in 1...2 {
        if libx265Param.bframes + 1 < libx265Param.lookaheadDepth {
          libx265Param.bframes += 1
        }
      }
      x265Params[.bframes] = libx265Param.bframes
      if libx265Param.tuQTMaxInterDepth > 3 {
        libx265Param.tuQTMaxInterDepth -= 1
        x265Params[.tuQTMaxInterDepth] = libx265Param.tuQTMaxInterDepth
      }
      if libx265Param.tuQTMaxIntraDepth > 3 {
        libx265Param.tuQTMaxIntraDepth -= 1
        x265Params[.tuQTMaxIntraDepth] = libx265Param.tuQTMaxIntraDepth
      }
      if libx265Param.maxNumMergeCand > 3 {
        libx265Param.maxNumMergeCand -= 1
        x265Params[.maxNumMergeCand] = libx265Param.maxNumMergeCand
      }
      if libx265Param.subpelRefine < 3 {
        libx265Param.subpelRefine = 3
        x265Params[.subme] = 3
      }
      x265Params[.minKeyint] = 1
      x265Params[.keyint] = 360
      x265Params[.openGOP] = 0
      //        param->deblockingFilterBetaOffset = -1;
      //        param->deblockingFilterTCOffset = -1;
      x265Params[.ctu] = 32
      x265Params[.maxTuSize] = 32
      x265Params[.qgSize] = 8
      x265Params[.cbqpoffs] = -2
      x265Params[.crqpoffs] = -2
      x265Params[.pbratio] = 1.2
      x265Params[.weightb] = 1
      switch self {
      case .littlepox, .littlepoxPlus:
        // Mid bitrate anime
        x265Params[.psyRd] = 1.5
        x265Params[.psyRdoq] = 0.8

        if self == .littlepoxPlus {
          if libx265Param.maxNumReferences < 2 {
            libx265Param.maxNumReferences = 2
            x265Params[.ref] = 2
          }
          x265Params[.subme] = 3
          if libx265Param.lookaheadDepth < 60 {
            libx265Param.lookaheadDepth = 60
            x265Params[.lookaheadDepth] = 60
          }
          x265Params[.merange] = 38
        }
      case .vcbs, .vcbsPlus:
        // High bitrate anime (bluray) or film
        x265Params[.psyRd] = 1.8
        x265Params[.psyRdoq] = 1

        if self == .vcbsPlus {
          if libx265Param.maxNumReferences < 3 {
            libx265Param.maxNumReferences = 3
            x265Params[.ref] = 3
          }
          x265Params[.subme] = 3
          x265Params[.bIntra] = 1
          x265Params[.rect] = 1
          x265Params[.limitTu] = 4
          if libx265Param.lookaheadDepth < 60 {
            libx265Param.lookaheadDepth = 60
            x265Params[.lookaheadDepth] = 60
          }
          x265Params[.merange] = 38
        }
      default: break
      }
    case .flyabc, .flyabcPlus:
      x265Params[.minKeyint] = 5
      x265Params[.scenecut] = 50
      x265Params[.openGOP] = 0
      x265Params[.lookaheadDepth] = 60
      x265Params[.lookaheadSlices] = 0
      x265Params[.me] = "hex"
      x265Params[.subme] = 2
      x265Params[.merange] = 57
      x265Params[.ref] = 3
      x265Params[.maxNumMergeCand] = 3
      x265Params[.noStrongIntraSmoothing] = 1
      x265Params[.noSao] = 1
      x265Params[.selectiveSao] = 0
      x265Params[.deblock] = "-3,-3"
      x265Params[.ctu] = 32
      x265Params[.rdoqLevel] = 2
      x265Params[.psyRdoq] = 1.0
      x265Params[.rskip] = 2

      if self == .flyabcPlus {
        x265Params[.earlySkip] = 0
      }
    }

    return x265Params
  }
}
