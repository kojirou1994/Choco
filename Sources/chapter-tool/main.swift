import MediaUtility
import Foundation
import Executable
import ArgumentParser
import MediaTools
import URLFileManager

let fm = URLFileManager.default

func write(chapter: MatroskaChapters, to fileURL: URL) throws {
  func write(chap: String, file: URL) throws {
    _ = try AnyExecutable(executableName: "mkvpropedit", arguments: [file.path, "-c", chap])
      .launch(use: SwiftToolsSupportExecutableLauncher())
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
  _ = try Mkvextract(filepath: fileURL.path, extractions: [.chapter(.init(simple: false, outputFilename: chapterBackupURL.path))])
    .launch(use: SwiftToolsSupportExecutableLauncher())
  return chapterBackupURL
}

struct ChapterTool: ParsableCommand {

  static var configuration: CommandConfiguration {
    .init(subcommands: [
      Rename.self,
      Clean.self
    ])
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
      precondition(chapterAtoms.count == titles.count, "Chapter count mismatch")

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
    var filePath: [String]

    @Flag()
    var removeTitle: Bool = false

    static let minChapterInterval = Timestamp.second * 3

    func run() throws {
      filePath.forEach { path in
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
