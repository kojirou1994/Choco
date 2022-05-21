import Foundation
@_exported import MediaTools
@_exported import MediaUtility
import ISOCodes

extension MkvMerge.Input.InputOption.TrackSelect {
  static func enabledLANGs(_ langs: Set<Language>) -> Self {
    .enabledLANGs(Set(langs.map(\.alpha3BibliographicCode)))
  }
}

extension MkvMergeIdentification.Track {

  public var trackLanguageCode: Language {
    properties?.language.flatMap { Language(alpha3Code: $0) } ?? .und
  }

  public var isFlac: Bool {
    codec == "FLAC"
  }

  public var isLosslessAudio: Bool {
    guard trackType == .audio else {
      return false
    }
    switch codec {
    case "FLAC", "ALAC" , "DTS-HD Master Audio", "PCM", "TrueHD Atmos", "TrueHD":
      return true
    default:
      return false
    }
  }

  public var isDTSHD: Bool {
    switch codec {
    case "DTS-HD Master Audio":
      return true
    default:
      return false
    }
  }

  public var isGarbageDTS: Bool {
    codec == "DTS"
  }

  public var isAC3: Bool {
    switch codec {
    case "E-AC-3", "AC-3", "AC-3 Dolby Surround EX":
      return true
    default:
      return false
    }
  }

  public var isTrueHD: Bool {
    switch codec {
    case "TrueHD Atmos", "TrueHD":
      return true
    default:
      return false
    }
  }

  public var remuxerInfo: String {
    var str = "\(id): \(trackType.mark) \(codec)"
    if let lang = properties?.language {
      str.append(" \(lang)")
    }
    if trackType == .video {
      str.append(" ")
      str.append(properties?.pixelDimensions ?? "")
    } else if trackType == .audio {
      str.append(" \(isLosslessAudio ? "lossless" : "lossy")")
      str.append(" \(properties?.audioBitsPerSample ?? 0)bits")
      str.append(" \(properties?.audioSamplingFrequency ?? 0)Hz")
      str.append(" \(properties?.audioChannels ?? 0)ch")
    }
    return str
  }
}

extension MediaTrackType {
  public var mark: String {
    switch self {
    case .audio: return "A"
    case .subtitles: return "S"
    case .video: return "V"
    }
  }
}
