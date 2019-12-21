import Foundation
import ArgumentParser
import KwiftUtility

public struct RemuxerArgument: ArgumentProtocol {

    private var outputPath: String = "."
    private var temporaryPath: String = "."
    internal private(set) var mode: RemuxMode = .movie
    internal private(set) var splits: [Int]? = nil
    internal private(set) var inputs: [String] = []
    internal private(set) var language: LanguagePreference = .default
    internal private(set) var deleteAfterRemux: Bool = false
    internal private(set) var keepTrackName: Bool = false
    internal private(set) var keepTrueHD: Bool = false
    internal private(set) var help: Bool = false
    internal private(set) var ignoreWarning = false
    internal private(set) var removeExtraDTS = false
    internal private(set) var organize = false

    public init() {}

    var outputRootDirectory: URL {
        URL(fileURLWithPath: self.outputPath)
    }

    var temperoraryDirectory: URL {
        URL(fileURLWithPath: self.temporaryPath).appendingPathComponent("BD-Remuxer-tmp")
    }

    internal func withTemporaryPath(_ body: (URL) -> Void) throws {
        let t = temperoraryDirectory.appendingPathComponent(UUID().uuidString)
        try _fm.createDirectory(at: t)
        body(t)
        try _fm.removeItem(at: t)
    }

    enum RemuxMode: String, CaseIterable, ValueOption {
        // direct mux all mpls
        case movie
        // split all mpls
        case episodes
        // print mpls list
        case dumpBDMV
        // input is *.mkv or something else
        case file

        static var allSelection: String {
            return allCases.map{$0.rawValue}.joined(separator: "|")
        }
    }

    struct LanguagePreference {

        static let defaultLanguages: Set<String> = ["und", "chi", "eng", "jpn"]

        static var `default`: Self {
            .init(languages: Self.defaultLanguages, excludeLanguages: [])
        }

        var languages: Set<String>
        var excludeLanguages: Set<String>

        func generatePrimaryLanguages(with otherLanguages: [String]) -> Set<String> {
            var preferedLanguages = languages
            otherLanguages.forEach { (l) in
                preferedLanguages.insert(l)
            }
            excludeLanguages.forEach { (l) in
                preferedLanguages.remove(l)
            }
            return preferedLanguages
        }
    }

    static func parse() throws -> Self {

        let parser = ArgumentParser<Self>(toolName: "BD-Remuxer", overview: "Automatic remux blu-ray disc or media files.")

        parser.addValueOption(name: "--output", anotherName: "-o", description: "Root output directory", keypath: \.outputPath)
        parser.addValueOption(name: "--temp", anotherName: "-t", description: "Root temp directory", keypath: \.temporaryPath)
        parser.addValueOption(name: "--mode", anotherName: nil, description: "Remux mode", keypath: \.mode)
        parser.addOption(name: "--language", anotherName: nil, requireValue: true, description: "Valid languages") { (v, arg) in
            arg.language.languages = Set(v.components(separatedBy: ",") + CollectionOfOne("und"))
        }
        parser.addOption(name: "--exclude-language", anotherName: nil, requireValue: true, description: "Exclude languages") { (v, arg) in
            arg.language.excludeLanguages = Set(v.components(separatedBy: ","))
        }
        parser.addOption(name: "--splits", anotherName: nil, requireValue: true, description: "Split info") { (v, arg) in
            arg.splits = try v.split(separator: ",").map {try Int(argument: String($0)) }
        }
        parser.addFlagOption(name: "--delete-after-remux", anotherName: nil, description: "Delete the src after remux", keypath: \.deleteAfterRemux)
        parser.addFlagOption(name: "--keep-track-name", anotherName: nil, description: "Keep original track name", keypath: \.keepTrackName)
        parser.addFlagOption(name: "--keep-truehd", anotherName: nil, description: "Keep TrueHD track", keypath: \.keepTrueHD)
        parser.addFlagOption(name: "--ignore-warning", anotherName: nil, description: "ignore mkvmerge warning", keypath: \.ignoreWarning)
        parser.addFlagOption(name: "--remove-extra-dts", anotherName: nil, description: "Remove dts when another same spec truehd exists", keypath: \.removeExtraDTS)
        parser.addFlagOption(name: "--organize", anotherName: nil, description: "Organize the output files to sub folders, not work for file mode", keypath: \.organize)
        parser.addFlagOption(name: "--help", anotherName: "-H", description: "Show help", keypath: \.help)

        parser.set(positionalInputKeyPath: \.inputs)

        let config = try parser.parse(arguments: CommandLine.arguments.dropFirst())

        if config.help || config.inputs.isEmpty {
            parser.showHelp(to: StdioOutputStream.stderr)
            exit(0)
        }

        return config
    }
}
