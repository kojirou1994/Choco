import Foundation

public let BDRemuxerTempDirectoryName = "BDRemuxer-tmp"

public struct BDRemuxerConfiguration {

  public let outputRootDirectory: URL
  public let temperoraryDirectory: URL
  public let mode: BDRemuxerMode
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

  public init(outputRootDirectory: URL, temperoraryDirectory: URL, mode: BDRemuxerMode,
              videoPreference: VideoPreference,
              audioPreference: AudioPreference,
              splits: [Int]?, preferedLanguages: LanguageSet, excludeLanguages: LanguageSet,
              deleteAfterRemux: Bool, keepTrackName: Bool, keepVideoLanguage: Bool, keepTrueHD: Bool, keepDTSHD: Bool,
              fixDTS: Bool, removeExtraDTS: Bool, ignoreWarning: Bool, organize: Bool, mainTitleOnly: Bool,
              keepFlac: Bool) {
    self.outputRootDirectory = outputRootDirectory
    self.temperoraryDirectory = temperoraryDirectory.appendingPathComponent(BDRemuxerTempDirectoryName)
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

extension BDRemuxerConfiguration {
  public struct AudioPreference {
    public let codec: AudioCodec
    public let lossyAudioChannelBitrate: Int
    public let generateStereo: Bool

    public init(codec: AudioCodec, channelBitrate: Int, generateStereo: Bool) {
      self.codec = codec
      self.lossyAudioChannelBitrate = channelBitrate
      self.generateStereo = generateStereo
    }

    public enum AudioCodec: String, CaseIterable, CustomStringConvertible {
      case flac
      case opus
      case fdkAAC = "fdk-aac"

      public var description: String { rawValue }
    }
  }

  public struct LanguagePreference {
    public let preferedLanguages: LanguageSet
    public let excludeLanguages: LanguageSet

    @usableFromInline
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
    public init(encodeVideo: Bool, codec: BDRemuxerConfiguration.VideoPreference.Codec, preset: BDRemuxerConfiguration.VideoPreference.CodecPreset, crf: Int, autoCrop: Bool) {
      self.encodeVideo = encodeVideo
      self.codec = codec
      self.preset = preset
      self.crf = crf
      self.autoCrop = autoCrop
    }


    public let encodeVideo: Bool
    public let codec: Codec
    public let preset: CodecPreset
    public let crf: Int
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

extension BDRemuxerConfiguration.AudioPreference.AudioCodec {
  var outputFileExtension: String {
    switch self {
    case .flac:
      return "flac"
    case .opus:
      return "opus"
    case .fdkAAC:
      return "m4a"
    }
  }
}

extension BDRemuxerConfiguration.VideoPreference.Codec {
  var pixelFormat: String {
    switch self {
    case .x264:
      return "yuv420p"
    case .x265:
      return "yuv420p10le"
    }
  }
}
