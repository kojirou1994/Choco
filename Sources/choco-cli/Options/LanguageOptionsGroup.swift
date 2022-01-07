import ArgumentParser
import libChoco

extension LanguageSet: ExpressibleByArgument {}

struct LanguageOptionsGroup: ParsableArguments {

  @Flag(help: "Ignore input file's primary language")
  var ignoreInputPrimaryLang: Bool = false

  @Option(help: "Included languages")
  var includeLangs: LanguageSet = .default

  @Option(help: "Excluded languages")
  var excludeLangs: LanguageSet = .empty

  @Option(help: "Included audio languages")
  var includeAudioLangs: LanguageSet = .default

  @Option(help: "Excluded audio languages")
  var excludeAudioLangs: LanguageSet = .empty

  @Option(help: "Included subtitles languages")
  var includeSubLangs: LanguageSet = .default

  @Option(help: "Excluded subtitles languages")
  var excludeSubLangs: LanguageSet = .empty

  var options: ChocoCommonOptions.LanguageOptions {
    .init(
      ignoreInputPrimaryLang: ignoreInputPrimaryLang,
      includeLangs: includeLangs,
      excludeLangs: excludeLangs,
      includeAudioLangs: includeAudioLangs,
      excludeAudioLangs: excludeAudioLangs,
      includeSubLangs: includeSubLangs,
      excludeSubLangs: excludeSubLangs
    )
  }
}
