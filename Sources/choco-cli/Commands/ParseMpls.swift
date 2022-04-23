import MplsParser
import Foundation
import ArgumentParser
import MediaTools

struct ParseMpls: ParsableCommand {

  @Flag
  var generate: Bool = false

  @Flag
  var absolute: Bool = false

  @Flag
  var dumpInfo: Bool = false

  @Option
  var startTime: UInt64?

  @Argument(help: ArgumentHelp("Mpls paths", discussion: "", valueName: "path"))
  var inputs: [String]

  func run() throws {
    try inputs.forEach { path in
      print("parsing \(path)")
      let inputFileURL = URL(fileURLWithPath: path)
      let mpls = try MplsPlaylist.parse(mplsURL: inputFileURL)
      if dumpInfo {
        dump(mpls)
        print("\n\n")
      }

      if let startTime = startTime {
        let startTimestamp = Timestamp(ns: startTime)
        mpls.playItems.forEach { playItem in
          print(playItem.clipId)
          print("start", playItem.inTime - startTimestamp)
          print("end", playItem.outTime - startTimestamp)
          print()
          
        }
      }

      if generate {
        if mpls.chapters.isEmpty {
          print("no chapter for \(path)")
          return
        }
        let outputFileURL = inputFileURL.replacingPathExtension(with: "xml")
        var atoms = [MatroskaChapter.EditionEntry.ChapterAtom]()
        if absolute {
          mpls.chapters.forEach { chap in
            atoms.append(.init(startTime: chap.absoluteTimestamp))
          }
        } else {
          mpls.chapters.forEach { chap in
            atoms.append(.init(startTime: chap.relativeTimestamp))
          }

          if mpls.duration > mpls.chapters.last!.relativeTimestamp {
            atoms.append(.init(startTime: mpls.duration))
          }
        }

        var chapter = MatroskaChapter(entries: [.init(chapters: atoms)])
        chapter.fillUIDs()

        try chapter.exportXML().write(to: outputFileURL, options: .atomic)
      }
    }
  }
}
