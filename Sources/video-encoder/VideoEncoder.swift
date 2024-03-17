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
    duration = Double(string.dropFirst())!
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
  var input: String = "-"

  @Option(name: .shortAndLong)
  var output: String

  @Option(help: "useful for wsl fuse paths")
  var cwd: String?

//  @Option(name: .shortAndLong, help: "tmp dir for unfinished file")
//  var tmp: String?

  @Option(help: "check output's duration is identical to input")
  var checkOutput: CheckDurationMode?

  @Argument(parsing: .postTerminator)
  var arguments: [String] = []

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

    let setStdIn: Bool
    #if canImport(Darwin)
    setStdIn = false
    #else
    setStdIn = true
    #endif

    print("encoder", encoder)
    print("input", input)
    print("output", output)

    let inputDurations = try checkOutput.map { _ in try readDurations(path: input) }

    let executable: String = switch encoder {
    case "qsv": "qsvencc"
    default: encoder
    }

    var params: [String]
    switch executable {
    case "ffmpeg":
      // TODO: support use / to separate in/out options
      params = [String]()
      params.append("-i")
      params.append(setStdIn ? "pipe:" : input)
      params.append(contentsOf: arguments)
      params.append(output)
    default:
      params = arguments
      params.append("--input")
      params.append(setStdIn ? "-" : input)
      params.append("--output")
      params.append(output)
    }

    print("params", params.joined(separator: " "))

    var command = Command(executable: executable, arguments: params)
    switch input {
    case "-": break // stdin passthrough
    default:
      if setStdIn {
        let path = try FileSyscalls.realPath(.init(input))
        command.stdin = .path(path, mode: .readOnly, options: [])
      }
    }
    command.cwd = cwd
    let statusCode = try command.output().status.exitStatus

    func removeUnfinishedOutput() {
      if removeUnfinished {
        _ = FileSyscalls.unlink(.absolute(.init(output)))
      }
    }

    if statusCode != 0 {
      print("encoder non-zero exit code: \(statusCode)")
      removeUnfinishedOutput()
      throw ExitCode(statusCode)
    }

    if let inputDurations {
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

    switch FileSyscalls.fileStatus(.absolute(.init(output)), into: &status) {
    case .success:
      print("encode succeess, output file existed!")
      if removeInput {
        print("remove input", FileSyscalls.unlink(.absolute(.init(input))))
      }
    case .failure:
      print("encoder exit 0 but output not existed!")
      throw Errno.noSuchFileOrDirectory
    }
  }

}
