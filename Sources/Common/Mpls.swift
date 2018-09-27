//
//  Mpls.swift
//  Common
//
//  Created by Kojirou on 2018/9/22.
//

import Foundation
import SwiftFFmpeg

public struct Mpls {
    
    public let chapterCount: Int
    
    public let duration: Int
    
    public let files: [String]
    
    public let size: Int
    
    public let fileName: String
    
    public let trackLangs: [String]
    
    public let compressed: Bool
    
    public init(filePath: String) throws {
        let mkvid = try MkvmergeIdentification.init(filePath: filePath)
        self.init(mkvid)
    }
    
    public init(_ info: MkvmergeIdentification) {
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
            compressed = true
            self.size = size / files.count
            self.files = fileSet.sorted()
            self.duration = duration / files.count
        } else {
            compressed = false
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
    
    public var description: String {
        return """
        fileName: \(fileName.filename)
        files:
        \(files.map {" - " + $0.filename}.joined(separator: "\n"))
        chapterCount: \(chapterCount)
        size: \(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
        duration: \(Mpls.durationFormatter.string(from: TimeInterval(duration)) ?? "Unknown")
        trackLangs: \(trackLangs)
        compressed: \(compressed)
        """
    }
    
    public static func < (lhs: Mpls, rhs: Mpls) -> Bool {
        return lhs.fileName < rhs.fileName
    }
    
    public static func == (lhs: Mpls, rhs: Mpls) -> Bool {
        return (lhs.duration, lhs.size, lhs.files, lhs.trackLangs) == (rhs.duration, rhs.size, rhs.files, rhs.trackLangs)
    }
}

public enum MplsRemuxMode {
    case direct
    case split
}

extension Mpls {
    
    public var useFFmpeg: Bool {
        return trackLangs.count == 0
    }
    
    public var primaryLanguage: String {
        return trackLangs.first(where: {$0 != "und"}) ?? "und"
    }
    
    public var isSingle: Bool {
        return files.count == 1
    }
    
    public var remuxMode: MplsRemuxMode {
        if isSingle {
            return .direct
        } else if files.count == chapterCount {
            return .split
        } else if !filesFormatMatches {
            return .split
        } else {
            return .direct
        }
    }
    
    private var filesFormatMatches: Bool {
        if isSingle {
            return true
        }
        // open every file and check
        let fileContexts = files.map { (file) -> AVFormatContextWrapper in
            let c = try! AVFormatContextWrapper.init(url: file)
            try! c.findStreamInfo()
            return c
        }
        for index in 0..<(fileContexts.count-1) {
            if !formatMatch(l: fileContexts[index], r: fileContexts[index+1]) {
                return false
            }
        }
        return true
    }
    
    private func formatMatch(l: AVFormatContextWrapper, r: AVFormatContextWrapper) -> Bool {
        guard l.streamCount == r.streamCount else {
            return false
        }
        let lStreams = l.streams
        let rStreams = r.streams
        for index in 0..<Int(l.streamCount) {
            let lStream = lStreams[index]
            let rStream = rStreams[index]
            if lStream.mediaType != rStream.mediaType {
                return false
            }
            switch lStream.mediaType {
            case AVMEDIA_TYPE_AUDIO:
                if !audioFormatMatch(l: lStream.codecpar, r: rStream.codecpar) {
                    return false
                }
            default:
                print("Only verify audio now")
            }
        }
        return true
    }
    
    private func audioFormatMatch(l: AVCodecParametersWrapper, r: AVCodecParametersWrapper) -> Bool {
        return (l.channelCount, l.sampleRate, l.sampleFmt) == (r.channelCount, r.sampleRate, r.sampleFmt)
    }
    
    public func split() -> [MplsClip] {
        
        do {
            try generateChapterFile()
        } catch {
            print("Generate Chapter File for \(fileName) failed")
        }
        if files.count == 1 {
            let filepath = files[0]
            let chapterName = fileName.filenameWithoutExtension + "_" + filepath.filenameWithoutExtension + "M2TS_chapter.txt"
            let chapterPath = fileName.deletingLastPathComponent.appendingPathComponent(chapterName)
            return [MplsClip.init(fileName: fileName, trackLangs: trackLangs, m2tsPath: filepath, chapterPath: FileManager.default.fileExists(atPath: chapterPath) ? chapterPath : nil, index: nil)]
        } else {
            var index = 0
            return files.map({ (filepath) -> MplsClip in
                defer { index += 1 }
                let chapterName = fileName.filenameWithoutExtension + "_" + filepath.filenameWithoutExtension + "M2TS_chapter.txt"
                let chapterPath = fileName.deletingLastPathComponent.appendingPathComponent(chapterName)
                return MplsClip.init(fileName: fileName, trackLangs: trackLangs, m2tsPath: filepath, chapterPath: FileManager.default.fileExists(atPath: chapterPath) ? chapterPath : nil, index: index)
            })
        }
    }
    
    private func generateChapterFile() throws {
        let script = "./BD_Chapters_MOD.py"
//            #file.deletingLastPathComponent.appendingPathComponent("../../BD_Chapters_MOD.py")
        let p = try Process.init(executableName: "python", arguments: [script, fileName])
        p.launchUntilExit()
        try p.checkTerminationStatus()
    }
    
}

extension Array where Element == Mpls {
    
    public var duplicateMplsRemoved: [Mpls] {
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


