import MediaUtility
import Executable
import URLFileManager
import Foundation

private struct HandBrake: Executable {
  static let executableName: String = "HandBrakeCLI"

  let input: String
  let output: String
  let previews: Int

  var arguments: [String] {
    [
      "-i", input,
      "-o", output,
      "--json",
      "--previews", "\(previews):0"
    ]
  }
}

// TODO: select correct video track number
public func calculateAutoCrop(at path: String, previews: Int,
                              tempFile: URL) throws -> CropInfo {
  let fm = URLFileManager.default
  if fm.fileExistance(at: tempFile).exists {
    try fm.removeItem(at: tempFile)
  }

  let process = try HandBrake(input: path, output: tempFile.path, previews: previews)
    .generateProcess(use: SwiftToolsSupportExecutableLauncher(outputRedirection: .collect, startNewProcessGroup: false))

  try process.launch()

  while !fm.fileExistance(at: tempFile).exists {
    Thread.sleep(forTimeInterval: 0.1)
  }

  Thread {
    Thread.sleep(forTimeInterval: 0.3)
    process.signal(SIGINT)
  }.start()
  try process.waitUntilExit()
  try fm.removeItem(at: tempFile)

  let stderr = try process.result.unwrap("No result").stderrOutput.get()
  let prefix = "  + autocrop: "
  for lineBuffer in stderr.lazySplit(separator: UInt8(ascii: "\n")) {
    let line = lineBuffer.utf8String
    if line.hasPrefix(prefix) {
      return try CropInfo(str: line.dropFirst(prefix.count))
    }
  }
  
  fatalError()
}