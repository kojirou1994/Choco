import MediaUtility
import Foundation
import PosixExecutableLauncher
import Logging
import MediaTools
import URLFileManager

let fm = URLFileManager.default
let utility = ChapterUtility()

enum ChapterToolError: Error {
  case noChapter
}

struct ChapterUtility {
  let logger: Logger

  init() {
    logger = .init(label: "ChapterUtility")
  }

  func extractAndReadChapter(from fileURL: URL, keepChapterFile: Bool) throws -> MatroskaChapter {
    let chapterBackupURL = fm.makeUniqueFileURL(fileURL.appendingPathExtension("chapter.xml"))
    _ = try MkvExtract(filepath: fileURL.path, extractions: [.chapter(filename: chapterBackupURL.path)])
      .launch(use: .posix)
    guard fm.fileExistance(at: chapterBackupURL).exists else {
      throw ChapterToolError.noChapter
    }
    defer {
      if !keepChapterFile {
        do {
          try fm.removeItem(at: chapterBackupURL)
        } catch {
          logger.error("Failed to remove chapter file: \(error.localizedDescription)")
        }
      }
    }
    return try MatroskaChapter(data: .init(contentsOf: chapterBackupURL))
  }

  func write(chapter: MatroskaChapter, to fileURL: URL, keepChapterFile: Bool) throws {
    func write(chap: String, file: URL) throws {
      let path = fileURL.path
      if chap.isEmpty {
        logger.info("Removing chapter for file: \(path)")
      } else {
        logger.info("Replacing chapter for file: \(path)")
      }
      _ = try MkvPropEdit(parseMode: nil, file: path, actions: [.chapter(filename: chap)])
        .launch(use: .posix)
    }
    if chapter.entries.allSatisfy({ $0.isEmpty }) {
      // no valid chapters
      try write(chap: "", file: fileURL)
    } else {
      let newChapterURL = fm.makeUniqueFileURL(fileURL.appendingPathExtension("new_chapter.xml"))
      try chapter.exportXML().write(to: newChapterURL)

      try write(chap: newChapterURL.path, file: fileURL)

      if !keepChapterFile {
        do {
          try fm.removeItem(at: newChapterURL)
        } catch {
          logger.error("Failed to remove chapter: \(error)")
        }
      }
    }
  }
}
