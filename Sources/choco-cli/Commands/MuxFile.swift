import ArgumentParser
import libChoco
import Foundation

struct MuxFile: ParsableCommand {

  @Flag(help: "Recursive into directories.")
  var recursive: Bool = false

  @Flag(help: "Copy normal files.")
  var copyNormalFiles: Bool = false

  @Flag(help: "Overwrite when copy normal files.")
  var copyOverwrite: Bool = false

  @Flag(help: "Delete the source files after remuxing.")
  var removeSourceFiles: Bool = false

  @OptionGroup
  var common: CommonOptionsGroup

  @Argument(help: "path")
  var inputs: [String]

  func run() throws {
    try common.withMuxerSetup { muxer in
      let fileRemuxOptions = FileRemuxOptions(recursive: recursive, copyNormalFiles: copyNormalFiles, copyOverwrite: copyOverwrite, removeSourceFiles: removeSourceFiles, fileTypes: FileRemuxOptions.defaultFileTypes)

      let results = inputs.map { input in
        muxer.mux(file: URL(fileURLWithPath: input), options: fileRemuxOptions)
      }

      for (input, result) in zip(inputs, results) {
        print("Input: \(input)")
        print("Result: \(result)")
      }
    }

  }

}
