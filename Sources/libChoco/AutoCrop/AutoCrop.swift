import MediaUtility
import PosixExecutableLauncher
import MediaTools
import Logging
import SystemPackage
import SystemUp
import SystemFileManager
import Command
import SystemUp

private struct HandBrakePreview: Executable {
  static let executableName: String = "HandBrakeCLI"

  let input: String
  let output: String
  let previews: Int

  var arguments: [String] {
    [
      "-i", input,
      "-o", output,
      "--json",
      "--previews", "\(previews):0",
      "-a", "none", "-s", "none",
      "--stop-at", "seconds:10"
    ]
  }
}

public func ffmpegCrop(file: String, resolution: (Int32, Int32)? = nil, baseFilter: String, limit: Double?, round: UInt8, skip: UInt, frames: UInt?, hw: String? = nil, logger: Logger?) -> Result<CropInfo, ChocoError> {
  // parse resolution optionally
  let width: Int32
  let height: Int32
  if let resolution {
    width = resolution.0
    height = resolution.1
  } else {
    do {
      logger?.info("get resolution using ffprobe")
      let probeOutput = try Command(executable: "ffprobe", arguments: [
        "-hide_banner",
        "-v", "error", "-select_streams", "v:0",
        "-show_entries", "stream=width,height", "-of", "csv=s=x:p=0",
        file
      ], stdout: .makePipe, stderr: .inherit)
        .output()
      let resolutionString = probeOutput.outputUTF8String.split(separator: "\n")[0]
      logger?.info("ffprobe resolution: \(resolutionString)")
      let parts = resolutionString.split(separator: "x")
      width = Int32(parts[0])!
      height = Int32(parts[1])!
      logger?.info("parsed resolution: width:\(width) height:\(height)")
    } catch {
      return .failure(.subTask(error))
    }
  }

  var filters = [String]()
  if !baseFilter.isEmpty {
    filters.append(baseFilter)
  }
  do {
    var args = [String]()
    if let limit {
      args.append("limit=\(limit)")
    }
    args.append("round=\(round)")
    args.append("skip=\(skip)")
    filters.append("cropdetect=\(args.joined(separator: ":"))")
  }
  

  var inputOptions = [FFmpeg.InputOption]()
  if let hw = hw {
    inputOptions.append(.hardwareAcceleration(hw, streamSpecifier: nil))
  }
  var ffmpeg = FFmpeg(
    global: .init(hideBanner: true, enableStdin: false),
    inputs: [
      .init(url: file, options: inputOptions),
      ],
    outputs: [
      .init(url: "-", options: [
        .map(inputFileID: 0, streamSpecifier: .streamType(.video, additional: .streamIndex(0)), isOptional: false, isNegativeMapping: false),
        .filter(filtergraph: filters.joined(separator: ","), streamSpecifier: nil),
        .format("null"),
      ])
    ])

  if let frames {
    ffmpeg.outputs[0].options.append(.frameCount(Int(frames), streamSpecifier: nil))
  }

  logger?.info("running ffmpeg: \(ffmpeg)")
  do {
    var ffProc = try PosixExecutableLauncher(stdin: .null, stdout: .null, stderr: .makePipe)
      .generateProcess(for: ffmpeg)
      .spawn()
    let nonCropInfo = CropInfo.Absolute(width: width, height: height, x: 0, y: 0)
    var cropInfo = nonCropInfo
    var sameCount = 0
    let maxSameCount = 10

    try FileStream.open(ffProc.pipes.takeStdErr()!.local, mode: .read())
      .closeAfter { stream in
        var finished = false
        var reader = FileStreamLineReader(delimiter: UInt8(ascii: "\n"), keepDelimiter: false)
        while let line = try reader.readline(stream: stream) {
          if line.hasPrefix("[Parsed_cropdetect") {
            let cropRange = line.range(of: "crop=")! // CropError.format
            let infoString = line[cropRange.upperBound...]
            #if DEBUG
            print(infoString)
            #endif
            let newInfo = try CropInfo.Absolute(ffmpegOutput: infoString)
            cropInfo = newInfo
            if newInfo == nonCropInfo {
              sameCount += 1
              finished = (maxSameCount == sameCount)
            } else {
              sameCount = 0
            }

            if finished {
              logger?.info("fast crop finished! kill ffmpeg")
              Signal.kill.send(to: .processID(ffProc.pid))
              break
            }
          }
        }
      }

    _ = try ffProc.wait()
    return .success(.absolute(cropInfo))
  } catch {
    return .failure(.subTask(error))
  }
}

// INFO: handbrake does not support selecting video track
public func handbrakeCrop(at path: String, previews: Int, tempFile: FilePath) throws -> CropInfo {

  try? SystemCall.unlink(tempFile)

  let handBrake = HandBrakePreview(input: path, output: tempFile.string, previews: previews)

  let result = try handBrake.launch(use: .posix(stdout: .makePipe, stderr: .makePipe))

  let stderr = result.error
  try? SystemCall.unlink(tempFile)

  let prefix = "  + autocrop: "
  for lineBuffer in stderr.lazySplit(separator: UInt8(ascii: "\n")) {
    let line = lineBuffer.utf8String
    if line.hasPrefix(prefix) {
      return try CropInfo(chocoOutput: line.dropFirst(prefix.count))
    }
  }
  
  throw ChocoError.noCropInfo
}

public struct FileStreamLineReader: ~Copyable {

  @_alwaysEmitIntoClient
  var lineBuf: UnsafeMutablePointer<CChar>?

  @_alwaysEmitIntoClient
  var lineCapp = 0

  @_alwaysEmitIntoClient
  let delimiter: UInt8

  @_alwaysEmitIntoClient
  let keepDelimiter: Bool

  @_alwaysEmitIntoClient
  public init(delimiter: UInt8, keepDelimiter: Bool) {
    self.delimiter = delimiter
    self.keepDelimiter = keepDelimiter
  }

  @_alwaysEmitIntoClient
  deinit {
    Memory.free(lineBuf)
  }

  @_alwaysEmitIntoClient
  mutating func nextLineLength(stream: borrowing FileStream) throws -> Int? {
    if let length = try stream.getDelimitedLine(line: &lineBuf, linecapp: &lineCapp, delimiter: delimiter) {
      let validLine = lineBuf.unsafelyUnwrapped
      var validLength = length
      if !keepDelimiter {
        if validLine[length-1] == delimiter {
          validLength -= 1
        }
      }
      return validLength
    }
    return nil
  }

  @_alwaysEmitIntoClient
  public mutating func readline(stream: borrowing FileStream) throws -> String? {
    guard let length = try nextLineLength(stream: stream) else {
      return nil
    }
    return String(decoding: UnsafeRawBufferPointer(start: lineBuf.unsafelyUnwrapped, count: length), as: UTF8.self)
  }

}
