import Foundation
import ExecutableLauncher

struct FFmpeg: Executable {
  init(arguments: [String]) {
    self.arguments = arguments + CollectionOfOne("-nostdin")
  }

  static var executableName: String { "ffmpeg" }

  let arguments: [String]

}
