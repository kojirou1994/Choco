import ArgumentParser
import libChoco
import Foundation

struct MuxBDMV: ParsableCommand {

  @Flag(help: "Split mpls playlist into segments")
  var splitPlaylist: Bool = false
  
  @Flag(help: "Organize the output files to sub folders, depending on duration")
  var organize: Bool = false
  
  @Flag(help: "Only handle bdmv's main title")
  var mainTitle: Bool = false

  @Flag(help: "Direct mode")
  var direct: Bool = false
  
  @OptionGroup
  var common: CommonOptionsGroup

  @Argument(help: "path")
  var inputs: [String]
  
  func run() throws {
    try common.withMuxerSetup { muxer in
      let bdmvRemuxOptions = BDMVRemuxOptions(splitPlaylist: splitPlaylist, organizeOutput: organize, mainTitleOnly: mainTitle, directMode: direct)

      let results = inputs.map { input in
        muxer.mux(bdmv: URL(fileURLWithPath: input), options: bdmvRemuxOptions)
      }

      print("\n\nSummary:\n")
      print("================")
      for (input, result) in zip(inputs, results) {
        defer {
          print("================\n")
        }
        print("Input: \(input)")
        switch result {
        case .success(let summary):
          print("Read input OK.")
          print()
          print("success ==>")
          print("\(summary.outputDirectory.path)")
          print("Time used: \(summary.timeSummary.usedTimeString)")
        case .failure(let error):
          print("BDMV remux failed: \(error)")
        }
      }
    }

  }
}
