import Foundation
import ISOCodes

extension Language {
  public init?(argument: String) {
    if let v = Language(alpha2Code: argument) {
      self = v
    } else if let v = Language(alpha3Code: argument) {
      self = v
    } else {
      return nil
    }
  }
}

public struct LanguageFilter {

  let isExcluded: Bool
  let languages: Set<Language>

  public static var `default`: Self {
    .init(isExcluded: false, languages: [.chi, .jpn])
  }

  public static var removeAll: Self {
    .included(languages: [])
  }

  public static var keepAll: Self {
    .excluded(languages: [])
  }

  public static func included(languages: Set<Language>) -> Self {
    .init(isExcluded: false, languages: languages)
  }

  public static func excluded(languages: Set<Language>) -> Self {
    .init(isExcluded: true, languages: languages)
  }

}

extension LanguageFilter: Equatable {}

extension LanguageFilter: CustomStringConvertible {
  public var description: String {
    (isExcluded ? "excluded" : "included") + ": " + languages.map(\.alpha3BibliographicCode).joined(separator: ", ")
  }

}

extension LanguageFilter {
  public init?(argument: String) {
    var argument = argument[argument.startIndex...]
    if argument[argument.startIndex] == "!" {
      self.isExcluded = true
      argument = argument.dropFirst()
    } else {
      self.isExcluded = false
    }
    var languages = Set<Language>()
    for str in argument.lazySplit(separator: ",") {
      if let code = Language(argument: String(str)) {
        languages.insert(code)
      } else {
        print("Invalid language code: \(str)!")
        return nil
      }
    }
    self.languages = languages
  }
}
