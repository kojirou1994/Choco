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
import SystemUp

extension MediaTrackType: EnumerableFlag {
  public static var allCases: [MediaTrackType] {
    [.video, .audio, .subtitles]
  }

  public static func name(for value: MediaTrackType) -> NameSpecification {
    [.customLong("disable-\(value.rawValue)"), .customLong("no-\(value.mark.lowercased())")]
  }
}

extension MkvPropEdit.EditSelector.TrackSelector {
  static func trackID(_ n: Int) -> Self {
    .trackNumber(n+1)
  }
}

struct AudioTrackHashSpec: Hashable {
  let channels: UInt
  let samplerate: UInt
  let bits: UInt
}

extension MkvMergeIdentification.Track {
  var spec: AudioTrackHashSpec {
    .init(channels: properties?.audioChannels ?? 0, samplerate: properties?.audioSamplingFrequency ?? 0, bits: properties?.audioBitsPerSample ?? 0)
  }
}

struct TrackHash: ParsableCommand {

  enum Tool: String, ExpressibleByArgument, CaseIterable {
    case ffmpeg
    case mkvextract
  }

  @Option(help: "Temp dir to extract tracks.")
  var tmp: String?

  @Option(help: "Tool selection: \(Tool.allCases.map(\.rawValue)).")
  var tool: Tool = .ffmpeg

  @Flag(help: "Decode every video frames.")
  var slowVideo: Bool = false

  @Flag(help: "Deduplicate same spec tracks with mkvpropedit, input must be mkv.")
  var dedup: Bool = false

  @Flag
  var disabledTrackTypes: [MediaTrackType] = []

  @Argument()
  var inputs: [String]

  func run() throws {
    let fm = URLFileManager.default
    if !disabledTrackTypes.isEmpty {
      print("Disabled track types: \(disabledTrackTypes)")
    }
    if dedup {
      print("De-duplicate enabled")
    }

    let formatter = BytesStringFormatter(uppercase: true)
    let tmpDir = (PosixEnvironment.get(key: "TMPDIR") ?? tmp).map(URL.init(fileURLWithPath:)) ?? FileManager.default.temporaryDirectory

    inputs.forEach { file in
      do {
        print("")
        print("Reading file: \(file)")
        let info = try MkvMergeIdentification(filePath: file)

        let tracks = try info.tracks.unwrap("no tracks!").notEmpty("no tracks!")

        let extractedTracks: [MkvMergeIdentification.Track] = tracks
          .filter { track in
            if disabledTrackTypes.contains(track.trackType) {
              return false
            }
            return true
          }

        if extractedTracks.isEmpty {
          print("No tracks need to be hashed.")
          return
        }

        let hashes: [String]
        var tempFilePaths = [URL]()

        defer {
          tempFilePaths.forEach { path in
            do {
              try fm.removeItem(at: path)
            } catch {
            }
          }
        }

        switch tool {
        case .ffmpeg:
          var outputOptions: [FFmpeg.InputOutputOption] = []
          extractedTracks.forEach { track in
            outputOptions.append(.map(inputFileID: 0, streamSpecifier: .streamIndex(track.id), isOptional: false, isNegativeMapping: false))
          }
          if !slowVideo {
            outputOptions.append(.codec("copy", streamSpecifier: .streamType(.video)))
          }
          outputOptions.append(.codec("copy", streamSpecifier: .streamType(.subtitle)))
          outputOptions.append(.format("streamhash"))

          let ffmpeg = FFmpeg(
            global: .init(logLevel: .init(level: .error), hideBanner: true),
            ios: [
              .input(url: file),
              .output(url: "-", options: outputOptions),
            ])
          print(ffmpeg.arguments.joined(separator: " "))
          let output = try ffmpeg.launch(use: TSCExecutableLauncher(outputRedirection: .collect))
          print(try output.utf8stderrOutput())
          hashes = try output.utf8Output().split(separator: "\n").map { String($0.split(separator: "=")[1]) }
        case .mkvextract:
          let extractedFilePaths = extractedTracks
            .map { _ in tmpDir.appendingPathComponent(UUID().uuidString) }

          let outputs = zip(extractedTracks, extractedFilePaths)
            .map { track, path in
              MkvExtractionMode.TrackOutput(trackID: track.id, filename: path.path)
            }
          let extractor = MkvExtract(
            filepath: file,
            extractions: [.tracks(outputs: outputs)])
          try extractor.launch(use: TSCExecutableLauncher(outputRedirection: .collect))
          hashes = try extractedFilePaths.map { trackFileURL -> String in
            var hash = SHA256()
            try BufferEnumerator(options: .init(bufferSizeLimit: 4*1024))
              .enumerateBuffer(file: trackFileURL) { (buffer, _, _) in
                hash.update(bufferPointer: buffer)
              }
            return formatter.bytesToHexString(hash.finalize())
          }
          tempFilePaths = extractedFilePaths
        }

        for (track, hash) in zip(extractedTracks, hashes) {
          print(track.remuxerInfo)
          print("Hash:", hash)
        }

        if dedup {
          print("Dedup enabled, start checking.")
          var disabledTrackIDs = [Int]()
          var checkedAudios = [(spec: AudioTrackHashSpec, trackID: Int, hash: String)]()
          var subtitleHashes = [(trackID: Int, hash: String)]()
          zip(extractedTracks, hashes).forEach { track, hash in
            switch track.trackType {
            case .video: break
            case .audio:
              let spec = track.spec
              if let existed = checkedAudios.first(where: { $0.hash == hash && $0.spec == spec }) {
                print("dup audio track \(track.id) detected, dst trackID: \(existed.trackID)")
                disabledTrackIDs.append(track.id)
              } else {
                checkedAudios.append((spec, track.id, hash))
              }
            case .subtitles:
              if let existed = subtitleHashes.first(where: { $0.hash == hash }) {
                print("dup subtitle track \(track.id) detected, dst trackID: \(existed.trackID)")
                disabledTrackIDs.append(track.id)
              } else {
                subtitleHashes.append((track.id, hash))
              }
            }
          }
          if disabledTrackIDs.isEmpty {
            print("no dup tracks")
          } else {
            print("disable tracks: \(disabledTrackIDs)")

            var editor = MkvPropEdit(filepath: file)
            disabledTrackIDs.forEach { trackID in
              editor.actions.append(.init(selector: .track(.trackID(trackID)), modifications: [.set(name: "flag-enabled", value: "0")]))
            }
            print(editor.arguments)
            try editor.launch(use: .tsc(outputRedirection: .none))
          }
        }

        print("")
      } catch {
        print("Failed, error: \(error)")
      }
    }
  }
}
