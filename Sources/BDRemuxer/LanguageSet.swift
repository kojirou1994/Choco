import Foundation

public struct LanguageSet: Codable, CustomStringConvertible {
    @usableFromInline
    internal var languages: Set<String>

    @inlinable
    public init(languages: Set<String>) {
        self.languages = languages
    }

    public static let defaultLanguages: Set<String> = ["und", "chi", "eng", "jpn"]

    public static var `default`: Self {
        .init(languages: Self.defaultLanguages) // , excludeLanguages: [])
    }

    @inlinable
    public func addingUnd() -> Self {
        var v = self
        v.languages.insert("und")
        return v
    }

    public var description: String {
        languages.sorted().description
    }
}
