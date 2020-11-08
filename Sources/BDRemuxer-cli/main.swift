import Foundation
import ArgumentParser
import KwiftUtility
import Foundation
import KwiftUtility
import BDRemuxer

extension Summary {
  #if canImport(Darwin)
  static let timeFormat: DateComponentsFormatter = {
    let f = DateComponentsFormatter()
    f.allowedUnits = [.minute, .second]
    f.unitsStyle = .short
    return f
  }()
  #endif

  var usedSeconds: Double {
    endDate.timeIntervalSince(startDate)
  }

  var usedTimeString: String {
    #if canImport(Darwin)
    return Self.timeFormat.string(from: startDate, to: endDate) ?? "\(usedSeconds)"
    #else
    return "\(usedSeconds)"
    #endif
  }
}

//
//remuxer.start()

extension LanguageSet: ExpressibleByArgument {
  public init?(argument: String) {
    self.init(languages: Set(argument.components(separatedBy: ",")))
  }
}

extension BDRemuxerMode: ExpressibleByArgument {}
extension BDRemuxerConfiguration.AudioPreference.AudioCodec: ExpressibleByArgument {}

struct BDRemuxerCli: ParsableCommand {

  static let configuration: CommandConfiguration =
    .init(commandName: "BDRemuxer-cli",
          abstract: "Automatic remux blu-ray disc or media files.",
          subcommands: [DumpBDMV.self, Mux.self]
    )
}

extension BDRemuxerCli {
  struct DumpBDMV: ParsableCommand {
    static var configuration: CommandConfiguration {
      .init(commandName: "dumpBDMV", abstract: "", discussion: "")
    }

    @Option(help: "Main title only in bluray.")
    var mainOnly: Bool = false

    @Argument(help: "path")
    var inputs: [String]

    static var muxer: BDRemuxer!

    func run() throws {
      inputs.forEach { input in
        let inputURL = URL(fileURLWithPath: input)
        let task = BDMVMetadata(rootPath: inputURL, mode: .direct,
                                mainOnly: mainOnly, splits: nil)
        do {
          try task.dumpInfo()
        } catch {
          print("Failed to read BDMV at \(input)")
        }
      }
    }

    func validate() throws {
      if inputs.isEmpty {
        throw ValidationError("No inputs!")
      }
    }
  }

  struct Mux: ParsableCommand {
    static var configuration: CommandConfiguration {
      .init(commandName: "mux", abstract: "", discussion: "")
    }

    @Option(name: .shortAndLong, help: "Root output directory")
    var output: String = "./"

    @Option(name: .shortAndLong, help: "Root temp directory")
    var temp: String = "./"

    @Option(help: "Remux mode")
    var mode: BDRemuxerMode = .movie

    @Option(help: "Split info, number joined by ,",
            transform: {argument in
              try argument.split(separator: ",").map {try Int($0).unwrap() }
            })
    var splits: [Int]?

    @Option(help: "Valid languages")
    var preferedLanguages: LanguageSet = .default//"und"

    @Option(help: "Exclude languages")
    var excludeLanguages: LanguageSet = .init(languages: [])//"und"

    @Flag(help: "Delete the src after remux")
    var deleteAfterRemux: Bool = false

    @Flag(help: "Keep original track name")
    var keepTrackName: Bool = false

    @Flag(help: "Keep TrueHD track")
    var keepTrueHD: Bool = false

    @Flag(help: "Keep DTS-HD track")
    var keepDTSHD: Bool = false

    @Flag(help: "Ignore mkvmerge warning")
    var ignoreWarning: Bool = false

    @Flag(help: "Remove dts when another same spec truehd exists")
    var removeExtraDTS: Bool = false

    @Flag(help: "Fix garbage DTS.")
    var fixDTS: Bool = false

    @Flag(help: "Organize the output files to sub folders, not work for file mode")
    var organize: Bool = false

    @Flag(help: "Main file only in bluray.")
    var mainOnly: Bool = false

    @Flag(help: "Prevent flac track from being re-encoded.")
    var keepFlac: Bool = false

    @Option(help: "Codec for lossless audio track, available: \(BDRemuxerConfiguration.AudioPreference.AudioCodec.allCases.map{$0.rawValue}.joined(separator: ", "))")
    var audioCodec: BDRemuxerConfiguration.AudioPreference.AudioCodec = .flac

    @Argument(help: "path")
    var inputs: [String]

    static var muxer: BDRemuxer!

    func run() throws {
      let configuration = BDRemuxerConfiguration(outputRootDirectory: URL(fileURLWithPath: output),
                                                 temperoraryDirectory: URL(fileURLWithPath: temp),
                                                 mode: mode,
                                                 audioPreference: .init(codec: audioCodec, channelBitrate: 128, generateStereo: false),
                                                 splits: splits, preferedLanguages: preferedLanguages, excludeLanguages: excludeLanguages,
                                                 deleteAfterRemux: deleteAfterRemux, keepTrackName: keepTrackName, keepVideoLanguage: false,
                                                 keepTrueHD: keepTrueHD, keepDTSHD: keepDTSHD, fixDTS: fixDTS, removeExtraDTS: removeExtraDTS,
                                                 ignoreWarning: ignoreWarning, organize: organize, mainTitleOnly: mainOnly, keepFlac: keepFlac)
      dump(configuration)
      let muxer = try BDRemuxer(config: configuration)
      Self.muxer = muxer
      Signals.trap(signals: [.quit, .int, .kill, .term, .abrt]) { (_) in
        Self.muxer.terminate()
      }
      let results = inputs.map { input -> TaskResult in
        let inputURL = URL(fileURLWithPath: input)
        return TaskResult(input: input, result: .init(catching: { try muxer.run(input: inputURL) }))
      }

      printSummary(workItems: results)
    }

    struct TaskResult {
      let input: String
      let result: Result<Summary, Error>
    }

    @usableFromInline
    func sizeString(_ v: UInt64) -> String {
      ByteCountFormatter.string(fromByteCount: Int64(v), countStyle: .file)
    }

    func printSummary(workItems: [TaskResult]) {
      print("Summary:")
      for workItem in workItems {
        print("Input: \(workItem.input)")
        switch workItem.result {
        case .success(let summary):
          print("Successed!")
          print("""
                    Start date: \(summary.startDate)
                    Totally used: \(summary.usedTimeString)
                    Old size: \(sizeString(summary.sizeBefore))
                    New size: \(sizeString(summary.sizeAfter))
                    """)
        case .failure(let error):
          print("Failed!")
          print("Error info: \(error)")
        }
      }
    }

    func validate() throws {
      if inputs.isEmpty {
        throw ValidationError("No inputs!")
      }
    }
  }
}

#if Xcode
import Executable
ExecutablePath.add("/usr/local/bin")
#endif

BDRemuxerCli.main()
