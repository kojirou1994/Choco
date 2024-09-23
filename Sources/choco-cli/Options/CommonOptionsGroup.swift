import ArgumentParser
import libChoco
import Logging
import KwiftUtility

extension Logger.Level: @retroactive ExpressibleByArgument {}

struct CommonOptionsGroup: ParsableArguments {
  @OptionGroup(title : "IO")
  var io: IOOptionsGroup

  @OptionGroup(title : "Metadata")
  var meta: MetaOptionsGroup

  @OptionGroup(title : "Video")
  var video: VideoOptionsGroup

  @OptionGroup(title : "Audio")
  var audio: AudioOptionsGroup

  @OptionGroup(title : "Language")
  var language: LanguageOptionsGroup

  @Option(help: "Log level, \(Logger.Level.availableValues)")
  var logLevel: Logger.Level = .info

  func withMuxerSetup(_ body: (ChocoMuxer) throws -> Void) throws {
    var logger = Logger(label: "choco-cli")
    logger.logLevel = logLevel

    let muxer = try ChocoMuxer(commonOptions: .init(io: io.options, meta: meta.options, video: video.getOptions(), audio: audio.options, language: language.options), logger: logger)

    ChocoCli.muxer = muxer
    Signals.trap(signals: [.quit, .int, .kill, .term, .abrt]) { (_) in
      ChocoCli.muxer?.terminate()
    }

    try body(muxer)
  }
}
