//
//  Mpls.swift
//  Remuxer
//
//  Created by Kojirou on 2018/9/16.
//

import Foundation

struct Mpls {
    let chapterCount: Int
    let duration: Int
    let files: [String]
    let size: Int
    let fileName: String
    let trackLangs: [String]
    let updated: Bool
    
    init(_ info: MkvmergeIdentification) {
        guard let size = info.container.properties?.playlistSize,
            let files = info.container.properties?.playlistFile,
            let duration = info.container.properties?.playlistDuration else {
                fatalError("Invalid MPLS: \(info)")
        }
        if files.count == 0 {
            print("No files?")
            print("MPLS: \(info)")
            fatalError()
        } else if case let fileSet = Set(files), fileSet.count < files.count {
            // contains repeated files
            updated = true
            self.size = size / files.count
            self.files = fileSet.sorted()
            self.duration = duration / files.count
        } else {
            updated = false
            self.size = size
            self.files = files
            self.duration = duration
        }
        trackLangs = info.tracks.map({ return $0.properties.language ?? "und" })
        fileName = info.fileName
        chapterCount = info.container.properties?.playlistChapters ?? 0
    }
}

extension Mpls: Comparable, Equatable {
    static func < (lhs: Mpls, rhs: Mpls) -> Bool {
        return lhs.fileName < rhs.fileName
    }
    
    static func == (lhs: Mpls, rhs: Mpls) -> Bool {
        return (lhs.duration, lhs.size, lhs.files, lhs.trackLangs) == (rhs.duration, rhs.size, rhs.files, rhs.trackLangs)
    }
}

extension Mpls {
    
    var useFFmpeg: Bool {
        return trackLangs.count == 0
    }
    
    var primaryLanguage: String {
        return trackLangs.first(where: {$0 != "und"}) ?? "und"
    }
}

extension Array where Element == Mpls {
    
    var filetedByMe: [Mpls] {
        var result = [Mpls]()
        for current in self {
            if let existIndex = result.firstIndex(of: current) {
                let (oldCount, newCount) = (result[existIndex].chapterCount, current.chapterCount)
                if oldCount != newCount {
                    if oldCount <= 1 {
                        result[existIndex] = current
                    } else {
                        // do nothing
                    }
                }
            } else {
                result.append(current)
            }
        }
        return result
    }
    
}
