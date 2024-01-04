import ArgumentParser
import Command
import SystemPackage
import SystemUp

@main
struct VideoEncoder: ParsableCommand {

  @Flag
  var overwrite: Bool = false

  @Flag
  var removeInput: Bool = false

  @Option(name: .shortAndLong)
  var encoder: String

  @Option(name: .shortAndLong)
  var input: String = "-"

  @Option(name: .shortAndLong)
  var output: String

  @Option(help: "useful for wsl fuse paths")
  var cwd: String?

  @Argument(parsing: .allUnrecognized)
  var params: [String]

  func run() throws {
    var status = FileStatus()

    if overwrite {
      _ = FileSyscalls.unlink(.absolute(.init(output)))
    } else {
      switch FileSyscalls.fileStatus(.absolute(.init(output)), into: &status) {
      case .success: throw Errno.fileExists
      case .failure: break
      }
    }

    print("encoder", encoder)
    print("input", input)
    print("output", output)

    let executable: String = switch encoder {
    case "qsv": "qsvencc"
    default: encoder
    }

    var params = params
    params.append("--input")
    params.append("-")
    params.append("--output")
    params.append(output)
    print("params", params.joined(separator: " "))

    var command = Command(executable: executable, arguments: params)
    switch input {
    case "-": break // stdin passthrough
    default:
      let path = try FileSyscalls.realPath(.init(input))
      command.stdin = .path(path, mode: .readOnly, options: [])
    }
    command.cwd = cwd
    let statusCode = try command.output().status.exitStatus
    if statusCode != 0 {
      throw ExitCode(statusCode)
    }
    switch FileSyscalls.fileStatus(.absolute(.init(output)), into: &status) {
    case .success:
      if removeInput {
        print("encode succeess, remove input")
        _ = FileSyscalls.unlink(.absolute(.init(input)))
      }
    case .failure:
      print("encoder exit 0 but output not existed!")
    }
  }

}
