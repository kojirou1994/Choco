import ArgumentParser
import Command
import SystemPackage

@main
struct VideoEncoder: ParsableCommand {

  @Option(name: .shortAndLong)
  var encoder: String

  @Option(name: .shortAndLong)
  var input: String = "-"

  @Option(name: .shortAndLong)
  var output: String

  @Argument(parsing: .allUnrecognized)
  var params: [String]

  func run() throws {
    print("encoder", encoder)
    print("input", input)
    print("output", output)
    print("params", params.joined(separator: " "))

    let executable: String = switch encoder {
    case "qsv": "qsvencc"
    default: encoder
    }

    var params = params
    params.append("--input")
    params.append("-")
    params.append("--output")
    params.append(output)

    var command = Command(executable: executable, arguments: params)
    switch input {
    case "-": break // stdin passthrough
    default:
      command.stdin = .path(.init(input), mode: .readOnly, options: [])
    }
    let output = try command.output()
    throw ExitCode(output.status.exitStatus)
  }

}
