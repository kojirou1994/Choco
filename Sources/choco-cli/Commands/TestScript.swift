import ArgumentParser
import TSCExecutableLauncher
import Foundation
import libChoco

struct TestScript: ParsableCommand {

  @Argument
  var template: String

  @Argument
  var input: String

  func run() throws {

    let inputURL = URL(fileURLWithPath: input)

    let script = try generateScript(
      encodeScript: template, filePath: input,
      trackIndex: 0,
      cropInfo: nil,
      encoderDepth: 10)
    let scriptFileURL = inputURL
      .deletingLastPathComponent()
      .appendingPathComponent("\(inputURL.deletingPathExtension().lastPathComponent)-gen_script.py")
    try! script.write(to: scriptFileURL, atomically: false, encoding: .utf8)

    try AnyExecutable(executableName: "vspipe", arguments: ["--info", scriptFileURL.path])
      .launch(use: TSCExecutableLauncher(outputRedirection: .none), options: .init(checkNonZeroExitCode: false))

  }
}
