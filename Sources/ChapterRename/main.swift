import MplsParser
import Foundation
import Executable

do {
    guard CommandLine.argc >= 3 else {
        print("ChapterRename mkv.mkv title.txt")
        exit(1)
    }
    
    let mkvFilename = CommandLine.arguments[1]
    let exportChapterPath = "\(mkvFilename).txt"
    
    let titles = try String.init(contentsOfFile: CommandLine.arguments[2]).components(separatedBy: .newlines)
    
    try AnyExecutable(executableName: "mkvextract", arguments: [mkvFilename, "chapters", "-s", exportChapterPath]).runAndWait(checkNonZeroExitCode: true)
    
    var chapter = try Chapter.init(ogmFile: exportChapterPath)
    
    guard chapter.nodes.count == titles.count else {
        print("Chapter count mismatch")
        exit(1)
    }
    
    for index in 0..<chapter.nodes.count {
        chapter.nodes[index].title = titles[index]
    }
    
    let newChapterPath = "\(mkvFilename).new.txt"
    
    try chapter.exportOgm().write(toFile: newChapterPath, atomically: true, encoding: .utf8)
    
    try AnyExecutable(executableName: "mkvpropedit", arguments: [mkvFilename, "--chapters", newChapterPath]).runAndWait(checkNonZeroExitCode: true)

} catch {
    print("Error: \(error)")
}
