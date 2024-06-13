import ArgumentParser
import MediaUtility
import MediaTools
import SystemFileManager
import SystemPackage
import SystemUp
import Precondition
import PosixExecutableLauncher
import ISOCodes

/// regular file contents of directory
func fileContentsLevel1(ofDir path: FilePath) throws -> [FilePath] {
  try Directory.open(path)
    .get()
    .closeAfter { directory in
      var result = [FilePath]()
      try directory.forEachEntries { entry, stop in
        if entry.isHidden {
          return
        }
        let filePath = path.appending(entry.name)
        result.append(filePath)
      }
      return result
    }
}

struct SubtitleInfo {
  let path: FilePath
  let index: Int
  let lang: String
  let isoLang: Language

  init(path: FilePath) throws {
    let name = path.stem!
    let i = name.firstIndex(of: "_")!
    self.index = Int(name[..<i])!
    let lang = name[i...].dropFirst().lowercased()
    self.isoLang = try Language.allCases.first(where: { $0.alpha3BibliographicCode == lang || $0.name.lowercased() == lang }).unwrap("Unknown language: \(lang)")
    self.path = path
    self.lang = lang
  }

}

@main
struct FixRarbg: ParsableCommand {

  @Option(name: .shortAndLong, help: "Output root directory.")
  var output: String = "./"

  @Flag(help: "Delete used mp4 and subtitle files")
  var delete: Bool = false

  @Flag(help: "Delete unused subtitle files")
  var deleteUnused: Bool = false

  @Argument(help: .init("RARBG folder path.", valueName: "input"))
  var inputs: [String]

  func run() throws {

    let validLangs: Set<String> = ["Chinese".lowercased(), "Japanese".lowercased()]

    let outputRootPath = FilePath(output)
    inputs.forEach { input in
      do {
        print("OPENING DIRECTORY: \(input)")
        let inputPath: FilePath = try SystemCall.realPath(input).get()
        let subtitleDirPath = inputPath.appending("Subs")
        print("will read subtitles from \(subtitleDirPath)")
        let outputRARBGPath = try outputRootPath.appending(inputPath.lastComponent.unwrap("input has no directory name!"))
        print("output root: \(outputRARBGPath)")
        try Directory.open(inputPath)
          .get()
          .closeAfter { directory in
            try directory.forEachEntries { entry, _ in
              guard !entry.isHidden && entry.fileType == .regular && entry.name.hasSuffix(".mp4") else {
                return
              }
              do {
                let filePath = inputPath.appending(entry.name)
                print("fix file: \(filePath)")
                let mainFilename = filePath.stem!
                let fileSubDirPath = subtitleDirPath.appending(String(mainFilename))
                let subs = ((try? fileContentsLevel1(ofDir: fileSubDirPath)) ?? [])
                guard subs.allSatisfy({ $0.extension == "srt" }) else {
                  print("sub has unsupported formats")
                  return
                }
                var subInfos = subs.compactMap { path in
                  do {
                    let info = try SubtitleInfo(path: path)
                    return info
                  } catch {
                    print("ignore unknown lang's subtitle: \(path.lastComponent!)")
                    return nil
                  }
                }
                subInfos.sort(by: { $0.index < $1.index })
                var usedLangs = validLangs
                if let primaryLang = subInfos.first?.lang {
                  usedLangs.insert(primaryLang)
                }
                print("valid langs: \(usedLangs.sorted())")
                let usedSubInfos = subInfos.filter { sub in
                  let ok = usedLangs.contains(sub.lang)
                  print(sub.path.lastComponent!, "  ->  ",
                        sub.index, sub.lang, sub.isoLang.alpha3BibliographicCode, ok ? "👌" : "❌")
                  return ok
                }
                let outputFilePath = outputRARBGPath.appending("\(mainFilename).mkv")
                print("->\(outputFilePath)")
                try preconditionOrThrow(!SystemFileManager.fileExists(atPath: outputFilePath), "output file already existed!")

                var mergeInputs = [MkvMerge.Input(file: filePath.string)]
                usedSubInfos.forEach { sub in
                  mergeInputs.append(.init(file: sub.path.string, options: [.language(tid: 0, language: sub.isoLang.alpha3BibliographicCode)]))
                }
                let merge = MkvMerge(global: .init(quiet: false, flushOnClose: true), output: outputFilePath.string,
                                     inputs: mergeInputs)
                print("MUXING")
                try SystemFileManager.createDirectoryIntermediately(outputRARBGPath)
                try merge.launch(use: .posix)
                if delete {
                  print("Delete INPUT Files...")
                  if deleteUnused {
                    subs.forEach { sub in
                      _ = SystemFileManager.remove(sub)
                    }
                  } else {
                    usedSubInfos.forEach { sub in
                      _ = SystemFileManager.remove(sub.path)
                    }
                  }
                  try SystemFileManager.remove(filePath).get()
                }
              } catch {
                print("ERROR: \(error)")
              }
              print("\n")
            }
          }
      } catch {
        print("ERROR: \(error)")
      }
    }
  }
}
