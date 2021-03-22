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
      ChangeLang.self
    ])
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

            precondition(chapter.entries.count == 1)

            let titles = try String(contentsOf: chapterFileURL).components(separatedBy: .newlines)

            var chapterAtoms = chapter.entries[0].chapterAtoms
            if chapterAtoms.count > titles.count {
              if removeExtraChapter {
                chapterAtoms.removeLast(chapterAtoms.count - titles.count)
              } else {
                throw ValidationError("Chapter count mismatch")
              }
            }
            if chapterAtoms.count < titles.count {
              throw ValidationError("Chapter count mismatch, titles over flow")
            }

            for index in titles.indices {
              let chapterString = titles[index]
              if var chapterDisplays = chapterAtoms[index].chapterDisplays {
                if let displayIndex = chapterDisplays.firstIndex(where: {$0.chapterLanguage == language}) {
                  chapterDisplays[displayIndex].chapterString = chapterString
                } else {
                  chapterDisplays.append(.init(chapterString: chapterString, chapterLanguage: language))
                }
                chapterAtoms[index].chapterDisplays = chapterDisplays
              } else {
                chapterAtoms[index].chapterDisplays = [.init(chapterString: chapterString, chapterLanguage: language)]
              }
            }

            chapter.entries[0].chapterAtoms = chapterAtoms

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

      var chapterAtoms = chapter.entries[0].chapterAtoms
      guard chapterAtoms.count == titles.count else {
        throw ValidationError("Chapter count mismatch")
      }

      for index in chapterAtoms.indices {
        let chapterString = titles[index]
        if var chapterDisplays = chapterAtoms[index].chapterDisplays {
          if let displayIndex = chapterDisplays.firstIndex(where: {$0.chapterLanguage == language}) {
            chapterDisplays[displayIndex].chapterString = chapterString
          } else {
            chapterDisplays.append(.init(chapterString: chapterString, chapterLanguage: language))
          }
          chapterAtoms[index].chapterDisplays = chapterDisplays
        } else {
          chapterAtoms[index].chapterDisplays = [.init(chapterString: chapterString, chapterLanguage: language)]
        }
      }

      chapter.entries[0].chapterAtoms = chapterAtoms

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

        try preconditionOrThrow(chapter.entries.count == 1, "Unsupported chapter entry count: \(chapter.entries.count)")

        var cleanChapterAtoms: [MatroskaChapters.EditionEntry.ChapterAtom] = []

        func append(node: MatroskaChapters.EditionEntry.ChapterAtom) {
          var copy = node
          if removeTitle {
            copy.chapterDisplays = nil
          }
          cleanChapterAtoms.append(copy)
        }
        for node in chapter.entries[0].chapterAtoms {
          precondition(node.timestamp != nil, "Invalid timestamp \(node.chapterTimeStart)")
          precondition(node.timestamp!.toString(displayNanoSecond: true) == node.chapterTimeStart, "Invalid timestamp \(node.chapterTimeStart) decoded: \(Timestamp(string: node.chapterTimeStart)!)")
          if let last = cleanChapterAtoms.last {
            let interval = node.timestamp! - last.timestamp!
            if interval >= Self.minChapterInterval {
              append(node: node)
            }
          } else {
            append(node: node)
          }
        }

        chapter.entries[0].chapterAtoms = cleanChapterAtoms
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

        for entryIndex in chapter.entries.indices {
          var entry = chapter.entries[entryIndex]
          for atomIndex in entry.chapterAtoms.indices {
            var atom = entry.chapterAtoms[atomIndex]
            guard var chapterDisplays = atom.chapterDisplays,
                  !chapterDisplays.isEmpty else {
              continue
            }
            if let fromDisplayIndex = chapterDisplays.firstIndex(where: { $0.chapterLanguage == from }) {
              let fromDisplay = chapterDisplays[fromDisplayIndex]
              chapterDisplays.remove(at: fromDisplayIndex)
              if let toDisplayIndex = chapterDisplays.firstIndex(where: { $0.chapterLanguage == to }) {
                if overwrite {
                  chapterDisplays[toDisplayIndex].chapterLanguage = to
                } else {
                  print("\(to) existed skip this display")
                  continue
                }
              } else {
                chapterDisplays.append(.init(chapterString: fromDisplay.chapterString, chapterLanguage: to))
              }
            }
            atom.chapterDisplays = chapterDisplays
            entry.chapterAtoms[atomIndex] = atom
          }
          chapter.entries[entryIndex] = entry
        }

        try utility.write(chapter: chapter, to: fileURL, keepChapterFile: true)

      } catch {
        print("Error \(error)")
      }
    }
  }

}

ChapterTool.main()
