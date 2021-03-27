import MediaUtility
import Foundation
import ExecutableLauncher
import ArgumentParser
import MediaTools
import URLFileManager
import Precondition

let fm = URLFileManager.default
let utility = ChapterUtility()

struct ChapterTool: ParsableCommand {

  static var configuration: CommandConfiguration {
    .init(subcommands: [
      Rename.self,
      Clean.self,
      AutoRename.self,
      ChangeLang.self,
      ConvertLosslessCut.self,
    ])
  }

  struct ConvertLosslessCut: ParsableCommand {

    @Argument
    var input: String


    func convert(_ v: Double) -> String {
      let timestamp = Timestamp(ns: UInt64(v * 1_000_000_000))
      return timestamp.toString(displayNanoSecond: true)
    }

    func run() throws {
      let lines = try String(contentsOfFile: input)
        .split(separator: "\n")

      let uidStorage: [UInt]
      do {
        var uids = Set<UInt>()
        let uidCount = lines.count + 1
        uids.reserveCapacity(uidCount)
        while uids.count != uidCount {
          uids.insert(.random(in: UInt.min...UInt.max))
        }
        uidStorage = Array(uids)
      }

      let segments = try zip(lines, uidStorage).map { line, uid -> MatroskaChapters.EditionEntry.ChapterAtom in
        let parts = line.split(separator: ",")
        try preconditionOrThrow(parts.count > 0, "Invalid line: \(line)")
        let start = convert(try Double(parts[0]).unwrap())
        let end = parts.count == 1 ? nil : convert(try Double(parts[1]).unwrap())
        return MatroskaChapters.EditionEntry.ChapterAtom(uid: uid, startTime: start, endTime: end, isHidden: true, displays: nil)
      }

      let chapter = MatroskaChapters(entries: [.init(uid: uidStorage.last!, isHidden: true, isManaged: nil, isOrdered: true, isDefault: true, chapters: segments)])
      let outputURL = fm.makeUniqueFileURL(URL(fileURLWithPath: input).appendingPathExtension("xml"))
      try chapter.exportXML().write(to: outputURL)
    }
  }

  struct AutoRename: ParsableCommand {

    @Option(name: .shortAndLong)
    var language: String

    @Option()
    var chapterFormat: String = "txt"

    @Option(help: "Specific chapter file path")
    var chapter: String?

    @Flag(inversion: FlagInversion.prefixedNo, help: "Remove the chapter file if success")
    var removeChapFile: Bool = false

    @Flag(inversion: FlagInversion.prefixedNo, help: "Remove extra chapters if chapter count mismatch")
    var removeExtraChapter: Bool = false

    @Argument(help: ArgumentHelp("Input paths", discussion: "", valueName: "path"))
    var inputs: [String]

    func run() throws {
      inputs.forEach { input in
        let succ = fm.forEachContent(in: URL(fileURLWithPath: input), handleFile: true, handleDirectory: false, skipHiddenFiles: true) { fileURL in
          do {
            let chapterFileURL = chapter.map { URL(fileURLWithPath: $0) }
            ?? fileURL.deletingPathExtension().appendingPathExtension(chapterFormat)
            
            guard fileURL.pathExtension.lowercased() == "mkv",
                  fm.fileExistance(at: chapterFileURL).exists else {
              return
            }

            var chapter = try utility.extractAndReadChapter(from: fileURL, keepChapterFile: true)

            try preconditionOrThrow(chapter.entries.count == 1, "File must have only 1 chapter edition entry")

            let titles = try String(contentsOf: chapterFileURL).components(separatedBy: .newlines)

            var chapterAtoms = chapter.entries[0].chapters
            if chapterAtoms.count > titles.count {
              if removeExtraChapter {
                chapterAtoms.removeLast(chapterAtoms.count - titles.count)
              } else {
                throw ValidationError("Chapter count mismatch")
              }
            } else if chapterAtoms.count < titles.count {
              throw ValidationError("Chapter count mismatch, titles over flow")
            }

            for index in titles.indices {
              let chapterString = titles[index]
              if var chapterDisplays = chapterAtoms[index].displays {
                if let displayIndex = chapterDisplays.firstIndex(where: {$0.language == language}) {
                  chapterDisplays[displayIndex].string = chapterString
                } else {
                  chapterDisplays.append(.init(string: chapterString, language: language))
                }
                chapterAtoms[index].displays = chapterDisplays
              } else {
                chapterAtoms[index].displays = [.init(string: chapterString, language: language)]
              }
            }

            chapter.entries[0].chapters = chapterAtoms

            try utility.write(chapter: chapter, to: fileURL, keepChapterFile: true)
          } catch {
            print("Error: ", error, fileURL)
          }
        }
        if !succ {
          print("Cannot read input: \(input)")
        }
      }
    }
  }

  struct Rename: ParsableCommand {
    @Argument(help: ArgumentHelp("Mkv file path", discussion: "", valueName: "file-path"))
    var filePath: String

    @Argument(help: ArgumentHelp("Chapter-name file path", discussion: "", valueName: "chapter-path"))
    var chapterPath: String

    @Argument(help: ArgumentHelp("Chapter language", discussion: "", valueName: "language"))
    var language: String

    func run() throws {
      let fileURL = URL(fileURLWithPath: filePath)

      var chapter = try utility.extractAndReadChapter(from: fileURL, keepChapterFile: true)

      precondition(chapter.entries.count == 1)

      let titles = try String(contentsOfFile: chapterPath).components(separatedBy: .newlines)

      var chapterAtoms = chapter.entries[0].chapters
      guard chapterAtoms.count == titles.count else {
        throw ValidationError("Chapter count mismatch")
      }

      for index in chapterAtoms.indices {
        let chapterString = titles[index]
        if var chapterDisplays = chapterAtoms[index].displays {
          if let displayIndex = chapterDisplays.firstIndex(where: {$0.language == language}) {
            chapterDisplays[displayIndex].string = chapterString
          } else {
            chapterDisplays.append(.init(string: chapterString, language: language))
          }
          chapterAtoms[index].displays = chapterDisplays
        } else {
          chapterAtoms[index].displays = [.init(string: chapterString, language: language)]
        }
      }

      chapter.entries[0].chapters = chapterAtoms

      try utility.write(chapter: chapter, to: fileURL, keepChapterFile: true)

    }
  }

  struct Clean: ParsableCommand {
    @Argument(help: ArgumentHelp("Mkv file path", discussion: "", valueName: "file-path"))
    var inputs: [String]

    @Flag()
    var removeTitle: Bool = false

    @Flag(name: .shortAndLong)
    var recursive: Bool = false

    static let minChapterInterval = Timestamp.second * 3

    func run() throws {
      inputs.forEach { path in
        let fileURL = URL(fileURLWithPath: path)
        switch fm.fileExistance(at: fileURL) {
        case .directory:
          if recursive {
            _ = fm.forEachContent(in: fileURL, handleFile: true, handleDirectory: false, skipHiddenFiles: true, body: { url in
              clean(fileURL: url)
            })
          } else {
            print("\(path) is directory! add -r option")
          }
        case .file:
          clean(fileURL: fileURL)
        case .none:
          print("\(path) does not exist!")
        }
      }
    }

    func clean(fileURL: URL) {
      do {
        guard fileURL.pathExtension.lowercased() == "mkv" else {
          return
        }
        print("Cleaning \(fileURL.path)")

        var chapter = try utility.extractAndReadChapter(from: fileURL, keepChapterFile: true)

        chapter.entries.mutateEach { entry in
          entry.chapters.mutateEach { chapter in
            precondition(chapter.timestamp != nil, "Invalid timestamp \(chapter.startTime)")
            precondition(chapter.timestamp!.toString(displayNanoSecond: true) == chapter.startTime, "Invalid timestamp \(chapter.startTime) decoded: \(Timestamp(string: chapter.startTime)!)")

            if removeTitle {
              chapter.displays = nil
            }
          }
        }

        try utility.write(chapter: chapter, to: fileURL, keepChapterFile: true)
      } catch {
        print("Error \(error)")
      }
    }
  }

  struct ChangeLang: ParsableCommand {

    @Option()
    var from: String

    @Option()
    var to: String

    @Flag(name: .shortAndLong)
    var recursive: Bool = false

    @Flag(name: .shortAndLong)
    var overwrite: Bool = false

    @Argument
    var inputs: [String]

    func validate() throws {
      try preconditionOrThrow(from != to, ValidationError("from and to must be different"))
    }

    func run() throws {
      inputs.forEach { path in
        let fileURL = URL(fileURLWithPath: path)
        switch fm.fileExistance(at: fileURL) {
        case .directory:
          if recursive {
            _ = fm.forEachContent(in: fileURL, handleFile: true, handleDirectory: false, skipHiddenFiles: true, body: { url in
              handle(fileURL: url)
            })
          } else {
            print("\(path) is directory! add -r option")
          }
        case .file:
          handle(fileURL: fileURL)
        case .none:
          print("\(path) does not exist!")
        }
      }
    }

    func handle(fileURL: URL) {
      do {
        guard fileURL.pathExtension.lowercased() == "mkv" else {
          return
        }
        print("Handling \(fileURL.path)")

        var chapter = try utility.extractAndReadChapter(from: fileURL, keepChapterFile: true)

        chapter.entries.mutateEach { entry in
          entry.chapters.mutateEach { atom in
            guard var chapterDisplays = atom.displays,
                  !chapterDisplays.isEmpty else {
              return
            }
            if let fromDisplayIndex = chapterDisplays.firstIndex(where: { $0.language == from }) {
              let fromDisplay = chapterDisplays[fromDisplayIndex]
              chapterDisplays.remove(at: fromDisplayIndex)
              if let toDisplayIndex = chapterDisplays.firstIndex(where: { $0.language == to }) {
                if overwrite {
                  chapterDisplays[toDisplayIndex].language = to
                } else {
                  print("\(to) existed skip this display")
                  return
                }
              } else {
                chapterDisplays.append(.init(string: fromDisplay.string, language: to))
              }
            }
            atom.displays = chapterDisplays
          }
        }

        try utility.write(chapter: chapter, to: fileURL, keepChapterFile: true)

      } catch {
        print("Error \(error)")
      }
    }
  }

}

ChapterTool.main()
