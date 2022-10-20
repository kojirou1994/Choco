import Foundation
import ArgumentParser
import TSCExecutableLauncher
import MediaTools
#if canImport(CryptoKit)
import CryptoKit
#elseif canImport(Crypto)
import Crypto
#else
#error("Unsupported platform, no crypto library!!")
#endif
import BufferUtility
import MediaUtility
import URLFileManager
import PrettyBytes

extension MediaTrackType: EnumerableFlag {
  public static var allCases: [MediaTrackType] {
    [.video, .audio, .subtitles]
  }

  public static func name(for value: MediaTrackType) -> NameSpecification {
    .customLong("disable-\(value.rawValue)")
  }
}

struct TrackHash: ParsableCommand {

  @Option(help: "Temp dir to extract tracks.")
  var tmp: String = "./tmp"

  @Flag
  var disabledTrackTypes: [MediaTrackType] = []

  @Argument()
  var inputs: [String]

  func run() throws {
    let fm = URLFileManager.default
    if !disabledTrackTypes.isEmpty {
      print("Disabled track types: \(disabledTrackTypes)")
    }
    let formatter = BytesStringFormatter(uppercase: true)
    let tmpDir = URL(fileURLWithPath: tmp)
    inputs.forEach { file in
      do {
        print("")
        print("Reading file: \(file)")
        let info = try MkvMergeIdentification(filePath: file)

        let tracks = try info.tracks.unwrap("no tracks!").notEmpty("no tracks!")
        
        let extractedTrackIDAndURLs: [(id: Int, url: URL)] = tracks
          .filter { track in
            if disabledTrackTypes.contains(track.trackType) {
              return false
            }
            return true
          }
          .map { ($0.id, tmpDir.appendingPathComponent(UUID().uuidString)) }

        if extractedTrackIDAndURLs.isEmpty {
          print("No tracks need to be extracted.")
          return
        }

        let extractor = MkvExtract(
          filepath: file,
          extractions: [.tracks(outputs: extractedTrackIDAndURLs.map { .init(trackID: $0.id, filename: $0.url.path) })])
        try extractor.launch(use: TSCExecutableLauncher(outputRedirection: .collect))
        let hashes = try extractedTrackIDAndURLs.map(\.url).map { trackFileURL -> String in
          var hash = SHA256()
          try BufferEnumerator(options: .init(bufferSizeLimit: 4*1024))
            .enumerateBuffer(file: trackFileURL) { (buffer, _, _) in
            hash.update(bufferPointer: buffer)
          }
          return formatter.bytesToHexString(hash.finalize())
        }

        for (trackID, hash) in zip(extractedTrackIDAndURLs.map(\.id), hashes) {
          print(tracks[trackID].remuxerInfo)
          print("Hash:", hash)
        }

        extractedTrackIDAndURLs.map(\.url).forEach { trackFileURL in
          do {
            try fm.removeItem(at: trackFileURL)
          } catch {

          }
        }
        print("")
      } catch {
        print("Failed, error: \(error)")
      }
    }
  }
}
