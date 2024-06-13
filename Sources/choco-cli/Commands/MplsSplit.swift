import MplsParser
import Foundation
import ArgumentParser
import MediaTools
import IOStreams
import PosixExecutableLauncher

struct MplsCommand: ParsableCommand {
  static var configuration: CommandConfiguration {
    .init(
      commandName: "mpls",
      subcommands:[
        MplsParse.self,
        Split.self,
      ]
    )
  }

  static func read(path: String) throws -> MplsPlaylist {
    var stream = try FDStream(fd: .open(path, .readOnly))
    defer {
      try? stream.fd.close()
    }
    return try MplsPlaylist.parse(&stream)
  }
}

extension MplsCommand {
  struct Split: ParsableCommand {
    struct PlayItemInfo {
      let clipID: String
      let inTime: Timestamp
      let outTime: Timestamp
      var chapters: [Timestamp]
    }

    @Option(transform: { string in
      try string.split(separator: ",")
        .map { try Int($0).unwrap() }
    })
    var parts: [Int]

    @Option
    var joinOutput: String?

    @Flag
    var skipJoinSingle: Bool = false

    @Flag
    var dropRest = false

    @Argument(help: ArgumentHelp("Mpls paths", discussion: "", valueName: "path"))
    var inputs: [String]

    func validate() throws {
      if parts.isEmpty {
        throw ValidationError("parts is empty")
      }
      if let invalid = parts.first(where: { $0 <= 0 }) {
        throw ValidationError("non-positive split number: \(invalid)")
      }
    }

    func run() throws {
      try inputs.forEach { path in
        print("parsing \(path)")
        let inputFileURL = URL(fileURLWithPath: path).standardizedFileURL
        let mpls = try MplsCommand.read(path: path)

        var items = mpls.playItems.map { PlayItemInfo(clipID: $0.clipId, inTime: $0.relativeInTime, outTime: $0.relativeInTime + $0.outTime - $0.inTime, chapters: [])}
        mpls.chapters.forEach { chapter in
          items[Int(chapter.playItemIndex)].chapters.append(chapter.relativeTimestamp)
        }
        
        print("total chapters: \(items.count)")

        var restItems = items[items.startIndex...]

        var joinSegments = [(clips: [String], filename: String, chapterFileURL: URL?)]()

        func writeChapter(usingItems: ArraySlice<PlayItemInfo>, offset: Int) throws {
          precondition(!usingItems.isEmpty)

          let inTime = usingItems[usingItems.startIndex].inTime

          let filename = inputFileURL.deletingPathExtension().lastPathComponent + "-\(offset)-" + usingItems.map(\.clipID).joined(separator: "+")
          let chapterOutputFileURL = inputFileURL
            .deletingLastPathComponent()
            .appendingPathComponent(filename)
            .appendingPathExtension("xml")

          var atoms = usingItems.map(\.chapters).joined().map { MatroskaChapter.EditionEntry.ChapterAtom(startTime: $0 - inTime) }

          if atoms.isEmpty {
            print("no chapters for \(filename)")
          } else {
            if atoms[0].startTimestamp.value != 0 {
              atoms.insert(.init(startTime: .init(ns: 0)), at: 0)
            }
            var chapter = MatroskaChapter(entries: [.init(chapters: atoms)])
            chapter.fillUIDs()

            try chapter.exportXML().write(to: chapterOutputFileURL)
            print("chapter wrote to \(chapterOutputFileURL.path)")
          }

          if usingItems.count == 1, skipJoinSingle {
            return
          }
          joinSegments.append((usingItems.map(\.clipID), filename, atoms.isEmpty ? nil : chapterOutputFileURL))
        }

        try parts.enumerated().forEach { (offset, segmentsCount) in
          guard restItems.count >= segmentsCount else {
            throw ValidationError("rest parts is not enought for part at \(offset): \(segmentsCount)")
          }

          let usingItems = restItems.prefix(segmentsCount)
          restItems = restItems.dropFirst(segmentsCount)
          try writeChapter(usingItems: usingItems, offset: offset)
        }

        if !restItems.isEmpty, !dropRest {
          try writeChapter(usingItems: restItems, offset: parts.count)
        }

        if let joinOutput = joinOutput {
          let outputDirectoryURL = URL(fileURLWithPath: joinOutput)
          print("joining segments: \(joinSegments)")
          let streamDirectoryURL = inputFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("STREAM")
          try joinSegments.forEach { (clips, filename, chapterFileURL) in
            let outputFileURL = outputDirectoryURL.appendingPathComponent(filename)
              .appendingPathExtension("mkv")
            var inputs = [MkvMerge.Input(file: streamDirectoryURL.appendingPathComponent("\(clips[0]).m2ts").path)]
            inputs.append(contentsOf: clips.dropFirst().map { .init(file: streamDirectoryURL.appendingPathComponent("\($0).m2ts").path, append: true) })
            let mkv = MkvMerge(global: .init(quiet: false, chapterFile: chapterFileURL?.path),
                               output: outputFileURL.path,
                               inputs: inputs)
            print(mkv.arguments)
            try mkv.launch(use: .posix)
          }

        }
      }
    }
  }
}
