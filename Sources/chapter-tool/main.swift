import MediaUtility
import Foundation
import ExecutableLauncher
import ArgumentParser
import MediaTools
import URLFileManager

let fm = URLFileManager.default

func write(chapter: MatroskaChapters, to fileURL: URL) throws {
  func write(chap: String, file: URL) throws {
    _ = try AnyExecutable(executableName: "mkvpropedit", arguments: [file.path, "-c", chap])
      .launch(use: TSCExecutableLauncher())
  }
  if chapter.entries[0].chapterAtoms.isEmpty || (chapter.entries[0].chapterAtoms.count == 1 && chapter.entries[0].chapterAtoms[0].timestamp!.value == 0) {
    try write(chap: "", file: fileURL)
  } else {
    let newChapterURL = fm.makeUniqueFileURL(fileURL.appendingPathExtension("new_chapter.xml"))
    try chapter.exportXML().write(to: newChapterURL)

    try write(chap: newChapterURL.path, file: fileURL)
  }
}

func extractChapter(from fileURL: URL) throws -> URL {
  let chapterBackupURL = fm.makeUniqueFileURL(fileURL.appendingPathExtension("backup.xml"))
  _ = try MkvExtract(filepath: fileURL.path, extractions: [.chapter(filename: chapterBackupURL.path)])
    .launch(use: TSCExecutableLauncher())
  return chapterBackupURL
}

struct ChapterTool: ParsableCommand {

  static var configuration: CommandConfiguration {
    .init(subcommands: [
      Rename.self,
      Clean.self,
      AutoRename.self
    ])
  }

  struct AutoRename: ParsableCommand {

    @Option()
    var language: String

    @Option()
    var chapterFormat: String = "txt"

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
            let chapterFileURL = fileURL.deletingPathExtension().appendingPathExtension(chapterFormat)
            
            guard fileURL.pathExtension.lowercased() == "mkv",
                  fm.fileExistance(at: chapterFileURL).exists else {
              return
            }
            let chapterBackupURL = try extractChapter(from: fileURL)

            var chapter = try MatroskaChapters(data: .init(contentsOf: chapterBackupURL))

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

            try write(chapter: chapter, to: fileURL)
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
      let chapterBackupURL = try extractChapter(from: fileURL)

      var chapter = try MatroskaChapters(data: .init(contentsOf: chapterBackupURL))

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

      try write(chapter: chapter, to: fileURL)

    }
  }

  struct Clean: ParsableCommand {
    @Argument(help: ArgumentHelp("Mkv file path", discussion: "", valueName: "file-path"))
    var inputs: [String]

    @Flag()
    var removeTitle: Bool = false

    static let minChapterInterval = Timestamp.second * 3

    func run() throws {
      inputs.forEach { path in
        do {
          print("Cleaning \(path)")
          let fileURL = URL(fileURLWithPath: path)
          let chapterBackupURL = try extractChapter(from: fileURL)

          var chapter = try MatroskaChapters(data: .init(contentsOf: chapterBackupURL))

          precondition(chapter.entries.count == 1)

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
          try write(chapter: chapter, to: fileURL)

        } catch {
          print("Error \(error)")
        }
      }
    }
  }

}

ChapterTool.main()
