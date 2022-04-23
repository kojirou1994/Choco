import ArgumentParser

struct Explain: ParsableCommand {

  static var configuration: CommandConfiguration {
    .init(subcommands: [
      Bitrate.self,
    ])
  }
}
