import Foundation
import ArgumentParser
import ExecutableLauncher
import MediaTools
#if canImport(CryptoKit)
import CryptoKit
#elseif canImport(Crypto)
import Crypto
#else
#error("Unsupported platform, no crypto library!!")
#endif
import BufferUtility

struct TrackHash: ParsableCommand {
  @Argument()
  var inputs: [String]

  @Option(help: "Temp dir to extract tracks.")
  var tmp: String = "./tmp"

  func run() throws {
    let tmpDir = URL(fileURLWithPath: tmp)
    inputs.forEach { file in
      do {
        print("Reading file: \(file)")
        let info = try MkvMergeIdentification(filePath: file)
        
        let tracks = info.tracks.map { _ in tmpDir.appendingPathComponent(UUID().uuidString) }
        let extractor = MkvExtract(
          filepath: file,
          extractions: [.tracks(outputs: tracks.enumerated().map { .init(trackID: $0.offset, filename: $0.element.path) })])
        try extractor.launch(use: TSCExecutableLauncher(outputRedirection: .collect))
        let hashes = try tracks.map { trackFileURL -> String in
          var hash = SHA256()
          try BufferEnumerator(options: .init(bufferSizeLimit: 4*1024))
            .enumerateBuffer(file: trackFileURL) { (buffer, _, _) in
            hash.update(bufferPointer: buffer)
          }
          return hash.finalize().hexString(uppercase: true, prefix: "")
        }

        for (track, hash) in zip(info.tracks, hashes) {
          print(track.remuxerInfo)
          print("Hash:", hash)
        }

        tracks.forEach { trackFileURL in
          do {
            try fm.removeItem(at: trackFileURL)
          } catch {

          }
        }
        print("\n")
      } catch {
        print("Failed, error: \(error)")
      }
    }
  }
}
