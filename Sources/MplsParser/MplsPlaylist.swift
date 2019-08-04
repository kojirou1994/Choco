import Foundation

public struct MplsPlaylist: CustomStringConvertible {
    
    public let fileName: String

    let playlistStartIndex: UInt32
    let chapterStartIndex: UInt32
    let extensionDataStartIndex: UInt32
    let playItemCount: UInt16
    let subPathCount: UInt16
    let chapterCount: UInt16
    public let playItems: [MplsPlayItem]
    let subPaths: [MplsSubPath]
    public let chapters: [MplsChapter]
    
    public let duration: Timestamp
    
    public var description: String {
        return "duration: \(duration.description)"
    }
}

extension MplsPlaylist {
    
    public func convert() -> Chapter {
        return .init(timestamps: chapters.map {$0.relativeTimestamp})
    }
    
    public func split() -> [Chapter] {
        if playItems.count == 0 {
            // invalid playlist
            return []
        } else if playItems.count == 1 {
            // only 1 not split
            return [Chapter.init(mplsChapters: chapters)]
        } else {
            var result = [Chapter]()
            result.reserveCapacity(playItems.count)
            var currentPlayItemIndex: UInt16 = 0
            var lastPlayItemIndex: UInt16 = 0
            var startIndex = 0
            var endIndex = 0
            
            func addChapter() {
                if currentPlayItemIndex != lastPlayItemIndex {
                    (lastPlayItemIndex..<currentPlayItemIndex).forEach { (_) in
                        result.append(Chapter.init(nodes: []))
                    }
                    lastPlayItemIndex = currentPlayItemIndex
                }
                var tempChapters = Array(chapters[startIndex...endIndex])
                let start = tempChapters[0].relativeTimestamp
                for i in 0..<tempChapters.count {
                    var temp = tempChapters[i]
                    temp.relativeTimestamp -= start
                    tempChapters[i] = temp
                }
                result.append(.init(mplsChapters: tempChapters))
            }
            for (index, value) in chapters.enumerated() {
                if value.playItemIndex == currentPlayItemIndex {
                    // still current play item
                    endIndex = index
                } else {
                    addChapter()
                    currentPlayItemIndex = value.playItemIndex
                    lastPlayItemIndex += 1
                    startIndex = index
                    endIndex = index
                }
            }
            addChapter()
            if currentPlayItemIndex < playItems.count-1 {
                (Int(currentPlayItemIndex+1)..<playItems.count).forEach { (_) in
                    result.append(Chapter.init(nodes: []))
                }
            }
            return result
        }
    }
    
}

extension MplsPlaylist {
    public var m2tsList: [[String]] {
        let angleCount = playItems.max(by: {$0.multiAngle.angleCount < $1.multiAngle.angleCount})!.multiAngle.angleCount + 1
        var result = [[String]]()
        result.reserveCapacity(angleCount)
        for index in 0..<angleCount {
            result.append(playItems.map {$0.clipId(for: index)})
        }
        return result
    }
}
