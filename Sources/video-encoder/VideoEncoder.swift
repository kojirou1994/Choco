import ArgumentParser
import Command
import SystemPackage
import SystemUp

enum CheckDurationMode: String, ExpressibleByArgument {
  case all
  case `first` // compare first video and audio duration (if exists)
//  case guess
}

struct DurationResult: CustomStringConvertible {
  let type: DurationTrack
  let duration: Double

  internal init(_ string: Substring) {
    assert(!string.isEmpty)
    type = switch string[string.startIndex] {
    case "V": .video
    case "A": .audio
    default: fatalError("invalid mediainfo output!")
    }
    guard let duration = Double(string.dropFirst()) else {
      fatalError("invalid mediainfo output: \(string)")
    }
    self.duration = duration
  }

  enum DurationTrack: String, CustomStringConvertible {
    case video
    case audio

    var description: String { rawValue }
  }

  var description: String {
    "\(type),\(duration)"
  }
}

func readDurations(path: String) throws -> [DurationResult] {
  print("read durations from file \(path)")
  var command = Command(executable: "mediainfo", arguments: ["--Output=Video;V%Duration%\\n\nAudio;A%Duration%\\n", path])
  command.stdout = .makePipe
  let output = try command.output()
  let statusCode = output.status.exitStatus
  if statusCode != 0 {
    throw ExitCode(statusCode)
  }
  let results = output.outputUTF8String
    .split(separator: "\n")
    .map(DurationResult.init)


  results.forEach { print($0) }
  return results
}

enum CompareFailure: Error {
  case typeMismatch
  case durationChanged
}

func compareDuration(_ l: DurationResult, _ r: DurationResult, percent: Double = 0.03) throws {
  if l.type != r.type {
    throw CompareFailure.typeMismatch
  }
  let diffPer = abs(r.duration - l.duration) / l.duration
//  print(diffPer)
  let ok = diffPer <= percent

  print(ok ? "[OK]" : "[CHANGED]", l, "vs", r, diffPer)
  if !ok {
    throw CompareFailure.durationChanged
  }
}

@main
struct VideoEncoder: ParsableCommand {

  @Flag
  var overwrite: Bool = false

  @Flag
  var removeInput: Bool = false

  @Flag
  var removeUnfinished: Bool = false

  @Option(name: .shortAndLong)
  var encoder: String

  @Option(name: .shortAndLong)
  var input: Input?

  enum Input: ExpressibleByArgument {
    init(argument: String) {
      switch argument {
      case "-": self = .fd(.standardInput)
      default: self = .path(.init(argument))
      }
    }

    /// encoder's stdin stream fd, close after encoder started
    case fd(FileDescriptor)
    case path(FilePath)
  }

  @Option(name: .shortAndLong)
  var output: String?

  @Option(help: "useful for wsl fuse paths")
  var cwd: String?

//  @Option(name: .shortAndLong, help: "tmp dir for unfinished file")
//  var tmp: String?

  @Option(help: "alter input path for checking duration")
  var checkFile: String?

  @Option(help: "check output's duration is identical to input")
  var checkOutput: CheckDurationMode?

  @Argument(parsing: .postTerminator)
  var arguments: [String] = []

  func prepareEncoder() throws -> [Command.ChildProcess] {
    var processes = [Command.ChildProcess]() // sub processes

    var encoderInput = input
    switch input {
    case .path(let filePath):
      if let ext = filePath.extension,
         (ext == "vpy" || ext == "py") {
        print("use vspipe as decoder")
        var vspipe = Command(executable: "vspipe", arguments: ["-c", "y4m", filePath.string, "-"])
        vspipe.stdout = .makePipe
        var process = try vspipe.spawn()
        encoderInput = .fd(process.pipes.takeStdOut()!.local)
        processes.append(process)
      }
    default: break
    }

    let redirectInputToEncoderStdIn: Bool
    #if canImport(Darwin)
    redirectInputToEncoderStdIn = false
    #else
    redirectInputToEncoderStdIn = true
    #endif

    let executable: String = switch encoder {
    case "qsv": "qsvencc"
    case "svt-av1", "av1": "SvtAv1EncApp"
    default: encoder
    }

    var params: [String]
    switch executable {
    case "ffmpeg":
      // TODO: support use / to separate in/out options
      params = [String]()
      switch encoderInput {
      case .fd:
        params.append("-i")
        params.append("pipe:")
      case .path(let path):
        params.append("-i")
        params.append(redirectInputToEncoderStdIn ? "pipe:" : path.string)
      case .none: break
      }

      params.append(contentsOf: arguments)
      if let output {
        params.append(output)
      }
    default:
      params = arguments
      switch encoderInput {
      case .fd:
        params.append("--input")
        params.append("-")
      case .path(let path):
        params.append("--input")
        params.append(redirectInputToEncoderStdIn ? "-" : path.string)
      case .none: break
      }
      if let output {
        params.append("--output")
        params.append(output)
      }
    }

    print("params:", params.joined(separator: " "))

    var encoderCommand = Command(executable: executable, arguments: params)
    switch encoderInput {
    case .fd(let fd):
      encoderCommand.stdin = .fd(fd)
    case .path(let path):
      if redirectInputToEncoderStdIn {
        let path = try FileSyscalls.realPath(path)
        encoderCommand.stdin = .path(path, mode: .readOnly, options: [])
      }
    case .none: encoderCommand.stdin = .null
    }
    encoderCommand.cwd = cwd

    try processes.append(encoderCommand.spawn())

    // close input fd
    switch encoderInput {
    case .fd(let fd):
      try fd.close()
    default: break
    }

    return processes
  }

  func run() throws {
    var status = FileStatus()

    // MARK: check output overwrite
    if let output {
      if overwrite {
        _ = FileSyscalls.unlink(.absolute(.init(output)))
      } else {
        switch FileSyscalls.fileStatus(.absolute(.init(output)), into: &status) {
        case .success: throw Errno.fileExists
        case .failure: break
        }
      }
    }

    print("encoder", encoder)
    print("input", input ?? "none")
    print("output", output ?? "none")
    print("overwrite", overwrite, "removeInput", removeInput, "removeUnfinished", removeUnfinished)

    var inputDurations: [DurationResult]?
    if checkOutput != nil {
      var inputPathForChecking: String?
      if let checkFile {
        inputPathForChecking = checkFile
      } else {
        switch input {
        case .path(let path):
          inputPathForChecking = path.string
        default: break
        }
      }
      inputDurations = try inputPathForChecking.map { try readDurations(path: $0) }
    }

    var processes = try prepareEncoder()

    let statuses = try processes.indices.map { try processes[$0].waitOutput().status }

    func removeUnfinishedOutput() {
      if let output, removeUnfinished {
        _ = FileSyscalls.unlink(.absolute(.init(output)))
      }
    }

    if !statuses.allSatisfy({ $0.exited && $0.exitStatus == 0 })  {
      print("encoder processe have non-zero exit code: \(statuses)")
      removeUnfinishedOutput()
      throw ExitCode(1)
    }

    // MARK: compare input output durations
    if let inputDurations, let output {
      do {
        let outputDurations = try readDurations(path: output)
        switch checkOutput {
        case .all:
          if inputDurations.count != outputDurations.count {
            fatalError("track number changes!")
          }
          print("comparing each track's duration")
          for (inputDuration, outputDuration) in zip(inputDurations, outputDurations) {
            try compareDuration(inputDuration, outputDuration)
          }
        case .first:
          print("comparing first track's duration")
          let types = [DurationResult.DurationTrack.video, .audio]
          for type in types {
            if let inputDuration = inputDurations.first(where: { $0.type == type }),
               let outputDuration = outputDurations.first(where: { $0.type == type }) {
              try compareDuration(inputDuration, outputDuration)
            }
          }
        case nil:
          assertionFailure("impossible!")
          break
        }
      } catch {
        // check failed
        removeUnfinishedOutput()
        throw error
      }

      print("output file's duration validated, good!")
    }

    // MARK: check output exist, remove input optionally
    if let output {
      switch FileSyscalls.fileStatus(.absolute(.init(output)), into: &status) {
      case .success:
        print("encode succeess, output file existed!")
        if removeInput {
          switch input {
          case .path(let path):
            print("remove input", FileSyscalls.unlink(.absolute(path)))
          default: break
          }
        }
      case .failure:
        print("encoder exit 0 but output not existed!")
        throw Errno.noSuchFileOrDirectory
      }
    }
  }

}
