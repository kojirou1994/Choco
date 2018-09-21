//
//  Mpls.swift
//  Remuxer
//
//  Created by Kojirou on 2018/9/16.
//

import Foundation
import Kwift

struct Mpls {
    let chapterCount: Int
    let duration: Int
    let files: [String]
    let size: Int
    let fileName: String
    let trackLangs: [String]
    let updated: Bool
    
    init(filePath: String) throws {
        let mkvid = try MkvmergeIdentification.init(filePath: filePath)
        self.init(mkvid)
    }
    
    init(_ info: MkvmergeIdentification) {
        guard let size = info.container.properties?.playlistSize,
            let files = info.container.properties?.playlistFile,
            let durationValue = info.container.properties?.playlistDuration else {
                fatalError("Invalid MPLS: \(info)")
        }
        let duration = durationValue / 1_000_000_000
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

extension Mpls: Comparable, Equatable, CustomStringConvertible {
    
    #if os(macOS)
    static let durationFormatter: DateComponentsFormatter = {
        let f = DateComponentsFormatter.init()
        f.unitsStyle = .full
        f.allowedUnits = [.hour, .minute, .second]
        return f
    }()
    #else
    class SimpleDurationFormatter {
        
        func string(from ti: TimeInterval) -> String? {
            let v = Int(ti)
            let hour = v / 3600
            let minute = (v % 3600) / 60
            let second = v % 60
            return "\(hour):\(minute):\(second)"
        }
        
    }
    static let durationFormatter = SimpleDurationFormatter.init()
    #endif

    var description: String {
        return """
        fileName: \(fileName)
        files:
        \(files.map {" - " + $0}.joined(separator: "\n"))
        chapterCount: \(chapterCount)
        size: \(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
        duration: \(Mpls.durationFormatter.string(from: TimeInterval(duration)) ?? "Unknown")
        trackLangs: \(trackLangs)
        updated: \(updated)
        """
    }
    
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
    
    func split() -> [MplsClip]? {
        guard files.count > 0, !useFFmpeg else {
            return nil
        }
        
        do {
            try generateChapterFile()
        } catch {
            print("Generate Chapter File for \(fileName) failed")
            return nil
        }
        
        return files.map({ (filepath) -> MplsClip in
            let chapterName = fileName.filenameWithoutExtension + "_" + filepath.filenameWithoutExtension + "M2TS_chapter.txt"
            let chapterPath = fileName.deletingLastPathComponent.appendingPathComponent(chapterName)
            return MplsClip.init(fileName: fileName, trackLangs: trackLangs, m2tsPath: filepath, chapterPath: FileManager.default.fileExists(atPath: chapterPath) ? chapterPath : nil)
        })
    }
    
    private func generateChapterFile() throws {
        let script = #file.deletingLastPathComponent.appendingPathComponent("../../BD_Chapters_MOD.py")
        let p = try Process.init(executableName: "python", arguments: [script, fileName])
        p.launchUntilExit()
        try p.checkTerminationStatus()
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

struct MplsClip {
    let fileName: String
    let trackLangs: [String]
    let m2tsPath: String
    let chapterPath: String?
}
