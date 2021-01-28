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
        for track in info.tracks {
          print(track.remuxerInfo)
        }
        print("\n")
      } catch {
        print("Failed to read \(file), error: \(error)")
      }
    }
  }
}
