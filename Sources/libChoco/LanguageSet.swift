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

public struct LanguageSet: CustomStringConvertible {
  internal init(languages: Set<Language>) {
    self.languages = languages
  }

  var languages: Set<Language>

  public init?(argument: String) {
    languages = Set(argument.components(separatedBy: ",").compactMap { str in
      if let code = Language(alpha3Code: str) {
        return code
      } else {
        print("Invalid language code: \(str), ignored.")
        return nil
      }
    })
  }

  public static var `default`: Self {
    .init(languages: [.und, .chi, .jpn])
  }

  public var description: String {
    languages.map(\.alpha3BibliographicCode).joined(separator: ", ")
  }

}
