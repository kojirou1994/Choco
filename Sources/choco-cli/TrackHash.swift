import Foundation
import ArgumentParser
import ExecutableLauncher
import MediaTools

struct TrackHash: ParsableCommand {
  @Argument()
  var inputs: [String]

  @Option()
  var hasher: String = "sha256sum"

  func run() throws {
    fatalError("Unimplemented!")
    let tmpDir = URL(fileURLWithPath: "tmp")
    inputs.forEach { file in
      do {
        let info = try MkvMergeIdentification(filePath: file)
        let tracks = info.tracks.map { _ in UUID().uuidString }
        let extract = AnyExecutable(
          executableName: "mkvextract",
          arguments: [file, "tracks"] + tracks.enumerated().map {"\($0.offset):tmp/\($0.element)"})
        try extract.launch(use: TSCExecutableLauncher())
      } catch {
        print("Failed to read \(file), error: \(error)")
      }
    }
  }
}
