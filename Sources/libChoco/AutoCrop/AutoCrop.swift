import MediaUtility
import ExecutableLauncher
import URLFileManager
import Foundation

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

#warning("handbrake does not support selecting video track")
public func calculateAutoCrop(at path: String, previews: Int,
                              tempFile: URL) throws -> CropInfo {
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
      return try CropInfo(str: line.dropFirst(prefix.count))
    }
  }
  
  throw ChocoError.noHBCropInfo
}
