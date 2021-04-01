import Foundation
import ISOCodes
import Logging
import MediaTools

internal let ChocoTempDirectoryName = "choco_tmp"

public struct ChocoConfiguration {

  public let outputRootDirectory: URL
  public let temperoraryDirectory: URL
  public let mode: ChocoWorkMode
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
                quality: VideoQuality, autoCrop: Bool) {
      self.videoProcess = videoProcess
      self.encodeScript = encodeScript
      self.codec = codec
      self.preset = preset
      self.colorPreset = colorPreset
      self.quality = quality
      self.autoCrop = autoCrop
      self.tune = tune
      self.profile = profile
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
    public let allowSoftVT: Bool = true

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
//      case hevcVT

      public var description: String { rawValue }
    }

    public enum ColorPreset: String, CaseIterable, CustomStringConvertible {
      case bt709

      var ffmpegName: String {
        rawValue
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
    case .aac:
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
    }
  }

  var pixelFormat: String {
    switch self {
    case .x264, .h264VT:
      return "yuv420p"
    case .x265:
      return "yuv420p10le"
    }
  }

  var depth: Int {
    switch self {
    case .x264, .h264VT:
      return 8
    case .x265:
      return 10
    }
  }
}

extension ChocoConfiguration.VideoPreference {

  enum ChocoX265Tune: String {
    case vcbs = "vcb-s"
    case vcbsPlus = "vcb-s++"
    case littlepox
    case littlepoxPlus = "littlepox++"
  }

  var ffmpegIOOption: [FFmpeg.InputOutputOption] {
    var options = [FFmpeg.InputOutputOption]()
    options.append(.codec(codec.ffCodec, streamSpecifier: .streamType(.video)))
    options.append(.pixelFormat(codec.pixelFormat, streamSpecifier: nil))
    colorPreset.map { colorPreset in
      options.append(contentsOf: [
        .colorspace(colorPreset.ffmpegName, streamSpecifier: .streamType(.video)),
        .colorPrimaries(colorPreset.ffmpegName, streamSpecifier: .streamType(.video)),
        .colorTransferCharacteristics(colorPreset.ffmpegName, streamSpecifier: .streamType(.video))
      ])
    }
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
    case .h264VT:
      if allowSoftVT {
        options.append(.avOption(name: "allow_sw", value: "1", streamSpecifier: nil))
      }
    case .x265, .x264:
      options.append(.avOption(name: "preset", value: preset.rawValue, streamSpecifier: nil))
    }

    if let tune = self.tune {
      if codec == .x265, let chocoTune = ChocoX265Tune(rawValue: tune) {
        options.append(.avOption(name: "x265-params",
                                 value: chocoTune.parameterDictionary.map { param in
                                  //          if param.value.isEmpty {
                                  //            return param.key
                                  //          }
                                  return "\(param.key)=\(param.value)"
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


extension ChocoConfiguration.VideoPreference.ChocoX265Tune {
  var parameterDictionary: [String : String] {
    var x265Params = [String : String]()

    x265Params["merange"] = "25"
    x265Params["aq-strength"] = "0.8"
    x265Params["rd"] = "4"
    //        if (param->rdLevel < 4) param->rdLevel = 4;
    x265Params["rdoq-level"] = "2"
    x265Params["sao"] = "0"
    x265Params["strong-intra-smoothing"] = "0"

    //        if (param->bframes + 1 < param->lookaheadDepth) param->bframes++;
    //        if (param->bframes + 1 < param->lookaheadDepth) param->bframes++; //from tune animation
    //        if (param->tuQTMaxInterDepth > 3) param->tuQTMaxInterDepth--;
    //        if (param->tuQTMaxIntraDepth > 3) param->tuQTMaxIntraDepth--;
    //        if (param->maxNumMergeCand > 3) param->maxNumMergeCand--;
    //        if (param->subpelRefine < 3) param->subpelRefine = 3;
    x265Params["min-keyint"] = "1"
    x265Params["keyint"] = "360"
    x265Params["open-gop"] = "0"

    //        param->deblockingFilterBetaOffset = -1;
    //        param->deblockingFilterTCOffset = -1;
    x265Params["ctu"] = "32"
    x265Params["max-tu-size"] = "32"
    x265Params["qg-size"] = "8"
    x265Params["cbqpoffs"] = "-2"
    x265Params["crqpoffs"] = "-2"
    x265Params["pbratio"] = "1.2"
    x265Params["weightb"] = "1"

    switch self {
    case .littlepox, .littlepoxPlus:
      // Mid bitrate anime
      //          param->rc.rfConstant = 20;
      x265Params["psy-rd"] = "1.5"
      x265Params["psy-rdoq"] = "0.8"

      if self == .littlepoxPlus {
        //            if (param->maxNumReferences < 2) param->maxNumReferences = 2;
        x265Params["subme"] = "3"
        //            if (param->lookaheadDepth < 60) param->lookaheadDepth = 60;
        x265Params["merange"] = "38"
      }
    case .vcbs, .vcbsPlus:
      // High bitrate anime (bluray) or film
      //          param->rc.rfConstant = 18;
      x265Params["psy-rd"] = "1.8"
      x265Params["psy-rdoq"] = "1.0"

      if self == .vcbsPlus {
        //            if (param->maxNumReferences < 3) param->maxNumReferences = 3;
        x265Params["subme"] = "3"
        x265Params["b-intra"] = "1"
        x265Params["rect"] = "1"
        x265Params["limit-tu"] = "4"
        //            if (param->lookaheadDepth < 60) param->lookaheadDepth = 60;
        x265Params["merange"] = "38"
      }
    }

    return x265Params
  }
}
