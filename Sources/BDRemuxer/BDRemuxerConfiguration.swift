import Foundation

public let BDRemuxerTempDirectoryName = "BDRemuxer-tmp"

public struct BDRemuxerConfiguration {

  public let outputRootDirectory: URL
  public let temperoraryDirectory: URL
  public let mode: BDRemuxerMode
  public let splits: [Int]?
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
              audioPreference: AudioPreference,
              splits: [Int]?, preferedLanguages: LanguageSet, excludeLanguages: LanguageSet,
              deleteAfterRemux: Bool, keepTrackName: Bool, keepVideoLanguage: Bool, keepTrueHD: Bool, keepDTSHD: Bool,
              fixDTS: Bool, removeExtraDTS: Bool, ignoreWarning: Bool, organize: Bool, mainTitleOnly: Bool,
              keepFlac: Bool) {
    self.outputRootDirectory = outputRootDirectory
    self.temperoraryDirectory = temperoraryDirectory.appendingPathComponent(BDRemuxerTempDirectoryName)
    self.mode = mode
    self.splits = splits
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

    public enum AudioCodec: String, CaseIterable {
      case flac
      case opus
      case fdkAAC = "fdk-aac"
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
