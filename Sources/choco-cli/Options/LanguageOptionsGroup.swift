import ArgumentParser
import libChoco
import ISOCodes

extension Language: @retroactive ExpressibleByArgument {
  public static var allValueStrings: [String] {
    [Self.jpn, .eng, .chi, .fre].map(\.alpha3BibliographicCode)
  }
}

extension LanguageFilter: ExpressibleByArgument {}

struct LanguageOptionsGroup: ParsableArguments {

  @Option(help: "Override input file's primary language")
  var primaryLang: Language?

  @Flag(inversion: .prefixedNo)
  var preventNoAudio: Bool = true

  @Option(help: "Language filter for all tracks")
  var langs: LanguageFilter?

  @Option(help: "Language filter for audio tracks")
  var audioLangs: LanguageFilter?

  @Option(help: "Language filter for subtitles tracks")
  var subLangs: LanguageFilter?

  var options: ChocoCommonOptions.LanguageOptions {
    .init(primaryLanguage: primaryLang, preventNoAudio: preventNoAudio, all: langs, audio: audioLangs, subtitles: subLangs)
  }
}
