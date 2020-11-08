import Foundation
import TrackExtension
import ArgumentParser

struct TrackInfo: ParsableCommand {
  static var configuration: CommandConfiguration {
    .init(commandName: "TrackInfo", abstract: "", discussion: "")
  }

  @Argument()
  var inputs: [String]

  func run() throws {
    inputs.forEach { file in
      do {
        let info = try MkvmergeIdentification(filePath: file)
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

  func validate() throws {
    if inputs.isEmpty {
      throw ValidationError("No inputs!")
    }
  }
}

TrackInfo.main()
