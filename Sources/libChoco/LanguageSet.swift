import Foundation

public struct LanguageSet: Codable, CustomStringConvertible {

  internal var languages: Set<String>

  public init(languages: Set<String>) {
    self.languages = languages
  }

  public static let defaultLanguages: Set<String> = ["und", "chi", "jpn"]

  public static var `default`: Self {
    .init(languages: defaultLanguages)
  }

  public func addingUnd() -> Self {
    var v = self
    v.languages.insert("und")
    return v
  }

  public var description: String {
    languages.sorted().description
  }
}
