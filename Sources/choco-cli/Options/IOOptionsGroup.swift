import ArgumentParser
import libChoco
import Foundation

extension ChocoCommonOptions.IOOptions.KeepTempMethod: ExpressibleByArgument {}
extension ChocoSplit: ExpressibleByArgument {}

struct IOOptionsGroup: ParsableArguments {
  @Option(name: .shortAndLong, help: "Root output directory")
  var output: String = "./"

  @Option(name: .shortAndLong, help: "Root temp directory")
  var temp: String = "./"

  @Option(help: "Split info")
  var split: ChocoSplit?

  @Option(help: "Keep temp dir method, \(ChocoCommonOptions.IOOptions.KeepTempMethod.availableValues)")
  var keepTemp: ChocoCommonOptions.IOOptions.KeepTempMethod = .never

  @Flag(help: "Ignore mkvmerge warning")
  var ignoreWarning: Bool = false

  var options: ChocoCommonOptions.IOOptions {
    .init(outputRootDirectory: URL(fileURLWithPath: output), temperoraryDirectory: URL(fileURLWithPath: temp), split: split, ignoreWarning: ignoreWarning, keepTempMethod: keepTemp)
  }
}
