import MediaUtility
import Foundation
import Executable
import ArgumentParser

struct ChapterRename: ParsableCommand {

    static var configuration: CommandConfiguration {
        .init(commandName: "ChapterRename", abstract: "")
    }

    @Argument(help: ArgumentHelp("Mkv file path", discussion: "", valueName: "file-path"))
    var filePath: String

    @Argument(help: ArgumentHelp("Chapter file path", discussion: "", valueName: "chapter-path"))
    var chapterPath: String

    func run() throws {
        let exportChapterPath = "\(filePath).txt"

        let titles = try String(contentsOfFile: chapterPath).components(separatedBy: .newlines)

        _ = try AnyExecutable(executableName: "mkvextract", arguments: [filePath, "chapters", "-s", exportChapterPath]).runTSC()

        var chapter = try Chapter(ogmFileURL: URL(fileURLWithPath: exportChapterPath))

        guard chapter.nodes.count == titles.count else {
            throw ValidationError("Chapter count mismatch")
        }

        for index in 0..<chapter.nodes.count {
            chapter.nodes[index].title = titles[index]
        }

        let newChapterPath = "\(filePath).new.txt"

        try chapter.exportOgm().write(toFile: newChapterPath, atomically: true, encoding: .utf8)

        _ = try AnyExecutable(executableName: "mkvpropedit", arguments: [filePath, "--chapters", newChapterPath]).runTSC()

    }
}

ChapterRename.main()
