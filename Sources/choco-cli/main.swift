import Foundation
import ArgumentParser
import KwiftUtility
import Foundation
import KwiftUtility
import libChoco
import MediaUtility
import Logging

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

  private var simpleTimeString: String {
    Timestamp(hour: 0, minute: 0, second: UInt64(usedSeconds), milesecond: 0, nanosecond: 0)
      .description
  }

  var usedTimeString: String {
    #if canImport(Darwin)
    return Self.timeFormat.string(from: startDate, to: endDate) ?? simpleTimeString
    #else
    return simpleTimeString
    #endif
  }
}

extension LanguageSet: ExpressibleByArgument {}

extension ChocoWorkMode: ExpressibleByArgument {}
extension ChocoConfiguration.KeepTempMethod: ExpressibleByArgument {}
extension ChocoConfiguration.AudioPreference.AudioCodec: ExpressibleByArgument {}
extension ChocoConfiguration.VideoPreference.Codec: ExpressibleByArgument {}
extension ChocoConfiguration.VideoPreference.CodecPreset: ExpressibleByArgument {}
extension ChocoConfiguration.VideoPreference.ColorPreset: ExpressibleByArgument {}
extension ChocoConfiguration.AudioPreference.DownmixMethod: ExpressibleByArgument {}
extension ChocoConfiguration.VideoPreference.VideoProcess: ExpressibleByArgument {}
extension ChocoConfiguration.VideoPreference.VideoQuality: ExpressibleByArgument {}
extension Logger.Level: ExpressibleByArgument {}
extension ChocoSplit: ExpressibleByArgument {}
extension ChocoConfiguration.MetaPreference.Metadata: EnumerableFlag {

  var argumentName: String {
    switch self {
    case .trackName: return "track-name"
    case .tags: return "global-tags"
    case .videoLanguage: return "video-language"
    case .title, .attachments: return rawValue
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

extension ChocoConfiguration.AudioPreference.LosslessAudioCodec: EnumerableFlag {
  public static func name(for value: Self) -> NameSpecification {
    .customLong("keep-\(value.rawValue)")
  }
}

extension ChocoConfiguration.AudioPreference.GrossLossyAudioCodec: EnumerableFlag {
  public static func name(for value: Self) -> NameSpecification {
    .customLong("fix-\(value.rawValue)")
  }
}

extension CaseIterable where Self: RawRepresentable, RawValue == String {
  static var availableValues: String {
    "available: " + allCases.map(\.rawValue).joined(separator: ", ")
  }
}

struct ChocoCli: ParsableCommand {

  static let configuration: CommandConfiguration =
    .init(abstract: "Automatic remux blu-ray disc or media files.",
          subcommands: [
            TrackInfo.self,
            TrackHash.self,
            DumpBDMV.self,
            Crop.self,
            Mux.self,
            MkvToMp4.self,
            ParseMpls.self,
            TestFilter.self,
          ]
    )
}

extension ChocoCli {
  struct DumpBDMV: ParsableCommand {

    @Option(help: "Main title only in bluray.")
    var mainOnly: Bool = false

    @Argument(help: "path")
    var inputs: [String]

    func run() throws {
      let logger = Logger(label: "choco-cli")
      inputs.forEach { input in
        let inputURL = URL(fileURLWithPath: input)
        let task = BDMVMetadata(rootPath: inputURL, mode: .direct,
                                mainOnly: mainOnly, split: nil, logger: logger)
        do {
          try task.dumpInfo()
        } catch {
          logger.error("Failed to read BDMV at \(input)")
        }
      }
    }
  }

  struct Mux: ParsableCommand {

    @Option(name: .shortAndLong, help: "Root output directory")
    var output: String = "./"

    @Option(name: .shortAndLong, help: "Root temp directory")
    var temp: String = "./"

    @Option(name: .shortAndLong, help: "Work mode, \(ChocoWorkMode.availableValues)")
    var mode: ChocoWorkMode

    @Flag(help: "Split BDMV's playlist's segments")
    var splitBDMV: Bool = false

    @Option(help: "Split info")
    var split: ChocoSplit?

    @Option(help: "Valid languages")
    var preferedLanguages: LanguageSet = .default

    @Option(help: "Exclude languages")
    var excludeLanguages: LanguageSet?

    @Flag(help: "Ignore input file's primary language")
    var ignoreInputPrimaryLang: Bool = false

    @Flag(help: "Delete the src after remux")
    var deleteAfterRemux: Bool = false

    @Option(help: "Keep temp dir method, \(ChocoConfiguration.KeepTempMethod.availableValues)")
    var keepTemp: ChocoConfiguration.KeepTempMethod = .never

    @Flag(help: "Copy normal files in directory mode.")
    var copyDirectoryFile: Bool = false

    @Flag
    var keepMetadatas: [ChocoConfiguration.MetaPreference.Metadata] = []

    @Flag(help: "Sort track order by track type, priority: video > audio > subtitle.")
    var sortTrackType: Bool = false

    @Flag
    var protectedCodecs: [ChocoConfiguration.AudioPreference.LosslessAudioCodec] = []

    @Flag
    var fixCodecs: [ChocoConfiguration.AudioPreference.GrossLossyAudioCodec] = []

    @Flag(help: "Ignore mkvmerge warning")
    var ignoreWarning: Bool = false

    @Flag(help: "Remove dts when another same spec truehd exists")
    var removeExtraDTS: Bool = false

    @Flag(help: "Organize the output files to sub folders, not work for file mode")
    var organize: Bool = false

    @Flag(help: "Main file only in bluray.")
    var mainOnly: Bool = false

    @Flag(help: "Only encode progressive video track.")
    var progOnly: Bool = false

    @Option(name: [.customShort("v"), .long], help: "Video processing method, \(ChocoConfiguration.VideoPreference.VideoProcess.availableValues).")
    var videoProcess: ChocoConfiguration.VideoPreference.VideoProcess = .copy

    @Option(help: "FFmpeg video filter argument.")
    var videoFilter: String?

    @Option(help: "Codec for video track, \(ChocoConfiguration.VideoPreference.Codec.availableValues)")
    var videoCodec: ChocoConfiguration.VideoPreference.Codec = .x265

    @Option(help: "Color preset for video track, \(ChocoConfiguration.VideoPreference.ColorPreset.availableValues)")
    var videoColor: ChocoConfiguration.VideoPreference.ColorPreset?

    @Option(help: "VS script template path.")
    var encodeScript: String?

    @Option(help: "Codec preset for video track, \(ChocoConfiguration.VideoPreference.CodecPreset.availableValues)")
    var videoPreset: ChocoConfiguration.VideoPreference.CodecPreset = .medium

    @Option(help: "Codec crf for video track, eg. crf:19 or bitrate:5000k")
    var videoQuality: ChocoConfiguration.VideoPreference.VideoQuality = .crf(18)

    @Option(help: "Tune for video encoder, std or choco-provided, x265-\(ChocoConfiguration.VideoPreference.ChocoX265Tune.availableValues)")
    var videoTune: String?

    @Option(help: "Profile for video encoder")
    var videoProfile: String?

    @Flag(help: "Auto crop video track")
    var autoCrop: Bool = false

    @Flag(name: .customLong("keep-pix-fmt"), help: "Always keep input video's pixel format.")
    var keepPixelFormat: Bool = false

    @Flag(help: "Use ffmpeg integrated Vapoursynth")
    var useIntergratedVapoursynth: Bool = false

    @Flag(inversion: FlagInversion.prefixedNo, help: "Encode audio.")
    var encodeAudio: Bool = true

    @Option(help: "Codec for lossless audio track, \(ChocoConfiguration.AudioPreference.AudioCodec.availableValues)")
    var audioCodec: ChocoConfiguration.AudioPreference.AudioCodec = .flac

    @Option(help: "Codec for fixing lossy audio track, \(ChocoConfiguration.AudioPreference.AudioCodec.availableValues)")
    var audioLossyCodec: ChocoConfiguration.AudioPreference.AudioCodec = .opus

    @Option(help: "Audio kbps per channel")
    var audioBitrate: Int = 128

    @Option(help: "Downmix method, \(ChocoConfiguration.AudioPreference.DownmixMethod.availableValues)")
    var downmix: ChocoConfiguration.AudioPreference.DownmixMethod = .disable

    @Option(help: "Log level, \(Logger.Level.availableValues)")
    var logLevel: Logger.Level = .info

    @Argument(help: "path")
    var inputs: [String]

    static var muxer: ChocoMuxer!

    func scriptTemplate() throws -> String? {
      // replace error
      try encodeScript
        .map { try String(contentsOfFile: $0) }
    }

    func run() throws {
      let configuration = try ChocoConfiguration(
        outputRootDirectory: URL(fileURLWithPath: output),
        temperoraryDirectory: URL(fileURLWithPath: temp),
        mode: mode, splitBDMV: splitBDMV,
        metaPreference: .init(keepMetadatas: .init(keepMetadatas), sortTrackType: sortTrackType),
        videoPreference: .init(process: videoProcess, progressiveOnly: progOnly, filter: videoFilter, encodeScript: scriptTemplate(), codec: videoCodec, preset: videoPreset, colorPreset: videoColor, tune: videoTune, profile: videoProfile, quality: videoQuality, autoCrop: autoCrop, keepPixelFormat: keepPixelFormat, useIntergratedVapoursynth: useIntergratedVapoursynth),
        audioPreference: .init(encodeAudio: encodeAudio, codec: audioCodec, codecForLossyAudio: audioLossyCodec, lossyAudioChannelBitrate: audioBitrate, downmixMethod: downmix, preferedTool: .official, protectedCodecs: .init(protectedCodecs), fixCodecs: .init(fixCodecs)),
        split: split, preferedLanguages: preferedLanguages, excludeLanguages: excludeLanguages, ignoreInputPrimaryLang: ignoreInputPrimaryLang, copyDirectoryFile: copyDirectoryFile,
        deleteAfterRemux: deleteAfterRemux,
        removeExtraDTS: removeExtraDTS,
        ignoreWarning: ignoreWarning, organize: organize, mainTitleOnly: mainOnly, keepTempMethod: .never)

      var logger = Logger(label: "choco")
      logger.logLevel = logLevel
      let muxer = try ChocoMuxer(config: configuration, logger: logger)
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
    
  }
}

#if Xcode
import ExecutableLauncher
ExecutablePath.add("/opt/local/bin")
ExecutablePath.add("/Users/kojirou/Executable/Universal")
#endif

ChocoCli.main()
