import ArgumentParser
import libChoco
import Logging
import Foundation

struct DumpBDMV: ParsableCommand {

  @Option(help: "Main title only in bluray.")
  var mainOnly: Bool = false

  @Argument(help: "path")
  var inputs: [String]

  func run() throws {
    let logger = Logger(label: "dump-bdmv")
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
