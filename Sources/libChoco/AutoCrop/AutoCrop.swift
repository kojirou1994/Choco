import MediaUtility
import ExecutableLauncher
import URLFileManager
import Foundation
import MediaTools

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

public func ffmpegCrop(file: String, limit: UInt8 = 24) throws -> CropInfo {
  var filters = [String]()
  filters.append("cropdetect=limit=\(limit):round=2")

  let ffmpeg = FFmpeg(
    global: .init(hideBanner: true, enableStdin: false),
    ios: [
      .input(url: file),
      .output(url: "-", options: [
        .map(inputFileID: 0, streamSpecifier: .streamType(.video, additional: .streamIndex(0)), isOptional: false, isNegativeMapping: false),
        .filter(filtergraph: filters.joined(separator: ","), streamSpecifier: nil),
        .format("null"),
      ])
    ])

  print("running ffmpeg: \(ffmpeg.arguments)")
  let result = try ffmpeg.launch(use: TSCExecutableLauncher())
  for line in try result.utf8stderrOutput().components(separatedBy: .newlines).reversed() {
    if line.hasPrefix("[Parsed_cropdetect") {
      let cropRange = try line.range(of: "crop=").unwrap()
      return try .init(ffmpegOutput: line[cropRange.upperBound...])
    }
  }
  throw ChocoError.noCropInfo
}

#warning("handbrake does not support selecting video track")
public func handbrakeCrop(at path: String, previews: Int, tempFile: URL) throws -> CropInfo {
  let fm = URLFileManager.default
  if fm.fileExistance(at: tempFile).exists {
    try fm.removeItem(at: tempFile)
  }

  let handBrake = HandBrakePreview(input: path, output: tempFile.path, previews: previews)

  let result = try handBrake.launch(use: TSCExecutableLauncher(outputRedirection: .collect))
  
  let stderr = try result.stderrOutput.get()
  try? fm.removeItem(at: tempFile)

  let prefix = "  + autocrop: "
  for lineBuffer in stderr.lazySplit(separator: UInt8(ascii: "\n")) {
    let line = lineBuffer.utf8String
    if line.hasPrefix(prefix) {
      return try CropInfo(chocoOutput: line.dropFirst(prefix.count))
    }
  }
  
  throw ChocoError.noCropInfo
}
