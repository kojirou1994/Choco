import ArgumentParser
import libChoco
import Foundation

struct MuxFile: ParsableCommand {

  @Flag(help: "Endless loop muxing if any success file")
  var endless: Bool = false

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

      var endlessLoopCount = 0

      while true {

        let results = inputs.map { input in
          muxer.mux(file: URL(fileURLWithPath: input), options: fileRemuxOptions)
        }

        print("\n\nSummary:\n")
        print("================")

        var hasSuccessFileTask = false

        for (input, result) in zip(inputs, results) {
          defer {
            print("================\n")
          }
          print("Input: \(input)")
          switch result {
          case .success(let summary):
            print("Read input OK.")
            print()
            print("Handled media files:\n")
            if summary.files.isEmpty {
              print("None")
            } else {
              summary.files.forEach { fileTask in
                print("\(fileTask.input.path.path) \(ByteCountFormatter.string(fromByteCount: numericCast(fileTask.input.size), countStyle: .file))")
                switch fileTask.output {
                case .success(let output):
                  hasSuccessFileTask = true
                  print("success ==>")
                  print("\(output.path.path) \(ByteCountFormatter.string(fromByteCount: numericCast(output.size), countStyle: .file))")
                case .failure(let error):
                  print("failure: \(error)")
                }
                print()
              }
            }
          case .failure(let error):
            print("Read input failed: \(error)")
          }
        }

        if endless, hasSuccessFileTask {
          endlessLoopCount += 1
          print("starting endless loop \(endlessLoopCount)")
        } else {
          break
        }

      } // loop end
    }

  }

}
