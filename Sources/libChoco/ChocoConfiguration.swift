import Foundation

internal let ChocoTempDirectoryName = "choco_tmp"

public struct ChocoConfiguration {

  public let outputRootDirectory: URL
  public let temperoraryDirectory: URL
  public let mode: ChocoWorkMode
  public let splits: [Int]?
  public let videoPreference: VideoPreference
  public let audioPreference: AudioPreference
  public let languagePreference: LanguagePreference

  public let deleteAfterRemux: Bool
  public let keepTrackName: Bool
  public let keepVideoLanguage: Bool
  public let keepTrueHD: Bool
  public let keepDTSHD: Bool
  public let fixDTS: Bool
  public let removeExtraDTS: Bool

  public let ignoreWarning: Bool
  public let organizeOutput: Bool
  public let mainTitleOnly: Bool

  public let keepFlac: Bool

  public init(outputRootDirectory: URL, temperoraryDirectory: URL, mode: ChocoWorkMode,
              videoPreference: VideoPreference,
              audioPreference: AudioPreference,
              splits: [Int]?, preferedLanguages: LanguageSet, excludeLanguages: LanguageSet,
              deleteAfterRemux: Bool, keepTrackName: Bool, keepVideoLanguage: Bool, keepTrueHD: Bool, keepDTSHD: Bool,
              fixDTS: Bool, removeExtraDTS: Bool, ignoreWarning: Bool, organize: Bool, mainTitleOnly: Bool,
              keepFlac: Bool) {
    self.outputRootDirectory = outputRootDirectory
    self.temperoraryDirectory = temperoraryDirectory.appendingPathComponent(ChocoTempDirectoryName)
    self.mode = mode
    self.splits = splits
    self.videoPreference = videoPreference
    self.audioPreference = audioPreference
    self.languagePreference = .init(preferedLanguages: preferedLanguages.addingUnd(), excludeLanguages: excludeLanguages)
    self.deleteAfterRemux = deleteAfterRemux
    self.keepTrackName = keepTrackName
    self.keepVideoLanguage = keepVideoLanguage
    self.keepTrueHD = keepTrueHD
    self.keepDTSHD = keepDTSHD
    self.fixDTS = fixDTS
    self.removeExtraDTS = removeExtraDTS
    self.ignoreWarning = ignoreWarning
    self.organizeOutput = organize
    self.mainTitleOnly = mainTitleOnly
    self.keepFlac = keepFlac
  }

}

extension ChocoConfiguration {
  public struct AudioPreference {
    public init(encodeAudio: Bool, codec: ChocoConfiguration.AudioPreference.AudioCodec, lossyAudioChannelBitrate: Int, downmixMethod: ChocoConfiguration.AudioPreference.DownmixMethod) {
      self.encodeAudio = encodeAudio
      self.codec = codec
      self.lossyAudioChannelBitrate = lossyAudioChannelBitrate
      self.downmixMethod = downmixMethod
    }

    public let encodeAudio: Bool
    public let codec: AudioCodec
    public let lossyAudioChannelBitrate: Int
    public let downmixMethod: DownmixMethod

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
    public let preferedLanguages: LanguageSet
    public let excludeLanguages: LanguageSet

    func generatePrimaryLanguages<C>(with otherLanguages: C) -> Set<String> where C: Collection, C.Element == String {
      var result = preferedLanguages.languages
      otherLanguages.forEach { l in
        result.insert(l)
      }
      excludeLanguages.languages.forEach { l in
        result.remove(l)
      }
      return result
    }
  }

  public struct VideoPreference {
    public init(encodeVideo: Bool, encodeScript: String?, codec: ChocoConfiguration.VideoPreference.Codec, preset: ChocoConfiguration.VideoPreference.CodecPreset, crf: Double, autoCrop: Bool) {
      self.encodeVideo = encodeVideo
      self.encodeScript = encodeScript
      self.codec = codec
      self.preset = preset
      self.crf = crf
      self.autoCrop = autoCrop
    }

    public let encodeVideo: Bool
    public let encodeScript: String?
    public let codec: Codec
    public let preset: CodecPreset
    public let crf: Double
    public let autoCrop: Bool

    public enum Codec: String, CaseIterable, CustomStringConvertible {
      case x265
      case x264

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
  var pixelFormat: String {
    switch self {
    case .x264:
      return "yuv420p"
    case .x265:
      return "yuv420p10le"
    }
  }
}
