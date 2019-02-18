//
//  main.swift
//  BD_Chapters_MOD
//
//  Created by Kojirou on 2017/2/5.
//
//

import Foundation
import MplsReader

extension Array where Element == MplsChapter {
    func export() -> Chapter {
        return .init(timestamps: map {$0.relativeTimestamp})
    }
}

//let result = try mplsParse(path: "/Users/kojirou/Projects/Remuxer/PLAYLIST2/00001.mpls")
//print(result)
//result.chapters.forEach {print($0)}
//var chapters = result.chapters.filter {$0.playItemIndex == 1}
//let start = chapters[0].relativeTimestamp
//for i in 0..<chapters.count {
//    var temp = chapters[i]
//    temp.relativeTimestamp -= start
//    chapters[i] = temp
//}
//result.playItems.forEach {print($0)}
////dump(result.chapters)
//let t = result.chapters.first!.relativeTimestamp
//let t2 = Timestamp.init(string: t.timestamp)!
//precondition(t == t2)
////print(result.chapters.export().exportOgm())
////print(chapters.export().exportOgg())
//print("\n\n\n")
//result.split().forEach({print($0.exportOgm());print("\n\n\n")})

let folder = "/Users/kojirou/Projects/Remuxer/Complex/PLAYLIST"
try FileManager.default.contentsOfDirectory(atPath: folder).forEach({ (filename) in
    let path = folder.appendingPathComponent(filename)
    let result = try! mplsParse(path: path)
//    result.split().forEach({print($0.exportOgm());print("\n\n\n")})
})
