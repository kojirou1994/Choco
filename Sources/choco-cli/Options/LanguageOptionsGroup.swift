import ArgumentParser
import libChoco
import ISOCodes

extension Language: ExpressibleByArgument {}
extension LanguageFilter: ExpressibleByArgument {}

struct LanguageOptionsGroup: ParsableArguments {

  @Option(help: "Override input file's primary language")
  var primaryLang: Language?

  @Option(help: "Language filter for all tracks")
  var langs: LanguageFilter?

  @Option(help: "Language filter for audio tracks")
  var audioLangs: LanguageFilter?

  @Option(help: "Language filter for subtitles tracks")
  var subLangs: LanguageFilter?

  var options: ChocoCommonOptions.LanguageOptions {
    .init(primaryLanguage: primaryLang, all: langs, audio: audioLangs, subtitles: subLangs)
  }
}
