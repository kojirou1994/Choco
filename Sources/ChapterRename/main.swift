import MplsReader
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
    
    try Process.run(["mkvextract", mkvFilename, "chapters", "-s", exportChapterPath], wait: true)
    
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
    
    try Process.run(["mkvpropedit", mkvFilename, "--chapters", newChapterPath], wait: true)

} catch {
    print("Error: \(error)")
}
