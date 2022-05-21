import Foundation
import MediaTools
import ArgumentParser
import ExecutableLauncher

struct TrackInfo: ParsableCommand {
  @Argument()
  var inputs: [String]

  func run() throws {
    inputs.forEach { file in
      do {
        let info = try MkvMergeIdentification(filePath: file)
        print(file)
        info.tracks?.forEach { track in
          print(track.remuxerInfo)
        }
        print("\n")
      } catch {
        print("Failed to read \(file), error: \(error)")
      }
    }
  }
}
