import ArgumentParser
import libChoco

extension ChocoCommonOptions.MetaOptions.Metadata: EnumerableFlag {

  var argumentName: String {
    switch self {
    case .trackName: return "track-name"
    case .tags: return "global-tags"
    case .videoLanguage: return "video-language"
    case .title, .attachments, .disabled: return rawValue
    }
  }

  public static func name(for value: Self) -> NameSpecification {
    .customLong("keep-\(value.argumentName)")
  }

  public static func help(for value: Self) -> ArgumentHelp? {
    switch value {
    case .trackName: return "Keep original track name"
    case .videoLanguage: return "Keep original video track's language"
    default: return nil
    }
  }
}

struct MetaOptionsGroup: ParsableArguments {

  @Flag
  var keepMetadatas: [ChocoCommonOptions.MetaOptions.Metadata] = []

  @Flag(help: "Sort track order by track type, priority: video > audio > subtitle.")
  var sortTrackType: Bool = false

  @Option(help: "Filter pgs subtitle by minimum count.")
  var minPGSCount = 3

  var options: ChocoCommonOptions.MetaOptions {
    .init(keepMetadatas: .init(keepMetadatas), sortTrackType: sortTrackType, minPGSCount: minPGSCount)
  }
}
