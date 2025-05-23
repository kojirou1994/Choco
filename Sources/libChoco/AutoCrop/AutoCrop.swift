import MediaUtility
import PosixExecutableLauncher
import MediaTools
import Logging
import SystemPackage
import SystemUp
import SystemFileManager

public enum CropTool: String, CaseIterable, CustomStringConvertible {
  case ffmpeg
  case handbrake
  public var description: String { rawValue }
}

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

public func ffmpegCrop(file: String, baseFilter: String, limit: Double?, round: UInt8, skip: UInt, frames: UInt?, hw: String? = nil, logger: Logger?) -> Result<CropInfo, ChocoError> {
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

  logger?.info("running ffmpeg: \(ffmpeg.arguments)")
  do {
    let result = try ffmpeg.launch(use: .posix(stdout: .makePipe, stderr: .makePipe))
    for line in result.errorUTF8String.components(separatedBy: .newlines).reversed() {
      if line.hasPrefix("[Parsed_cropdetect") {
        let cropRange = try line.range(of: "crop=").unwrap()
        return try .success(.init(ffmpegOutput: line[cropRange.upperBound...]))
      }
    }
  } catch {
    return .failure(.subTask(error))
  }
  return .failure(.noCropInfo)
}

#warning("handbrake does not support selecting video track")
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
