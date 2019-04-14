//
//  Mpls.swift
//  Common
//
//  Created by Kojirou on 2018/9/22.
//

import Foundation
import SwiftFFmpeg
import MplsReader

extension MplsPlayItem {
    var langs: [String] {
//        return [stn.video + stn.audio + stn.pg].joined().map{ $0.attribute.lang }
        var result = [String]()
        result.append(contentsOf: stn.video.map {$0.attribute.lang})
        for audio in stn.audio {
            result.append(audio.attribute.lang)
            if audio.codec == .trueHD {
                result.append(audio.attribute.lang)
            }
        }
        result.append(contentsOf: stn.pg.map {$0.attribute.lang})
        return result
    }
}

public struct Mpls {
    
    public let chapterCount: Int
    
    public let duration: Timestamp
    
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

        if files.count == 0 {
            print("No files?")
            print("MPLS: \(info)")
            fatalError()
        } else if case let fileSet = Set(files), fileSet.count < files.count {
            // contains repeated files
            compressed = true
            self.size = size / files.count
            self.files = fileSet.sorted()
            self.duration = .init(ns: 0)
//                .init(ns: durationValue / UInt64(files.count))
        } else {
            compressed = false
            self.size = size
            self.files = files
            self.duration = .init(ns: durationValue)
        }
        trackLangs = info.tracks.map({ return $0.properties.language ?? "und" })
        fileName = info.fileName
        chapterCount = info.container.properties?.playlistChapters ?? 0
//        rawValue = .mkvtoolnix(info)
    }
    
}

extension Mpls: Comparable, Equatable, CustomStringConvertible {
    
    public var description: String {
        return """
        fileName: \(fileName.filename)
        files:
        \(files.map {" - " + $0.filename}.joined(separator: "\n"))
        chapterCount: \(chapterCount)
        size: \(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
        duration: \(duration.description)
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
        let fileContexts = files.map { (file) -> FFmpegFormatContext in
            let c = try! FFmpegFormatContext.init(url: file)
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
    
    private func formatMatch(l: FFmpegFormatContext, r: FFmpegFormatContext) -> Bool {
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
            case .audio:
                if !audioFormatMatch(l: lStream.codecParameters, r: rStream.codecParameters) {
                    return false
                }
            default:
                print("Only verify audio now")
            }
        }
        return true
    }
    
    private func audioFormatMatch(l: FFmpegCodecParameters, r: FFmpegCodecParameters) -> Bool {
        return (l.channelCount, l.sampleRate, l.sampleFormat) == (r.channelCount, r.sampleRate, r.sampleFormat)
    }
    
    public func split(chapterPath: String) -> [MplsClip] {
        
        do {
            try generateChapterFile(chapterPath: chapterPath)
        } catch {
            print("Generate Chapter File for \(fileName) failed")
        }
        
        func getDuration(file: String) -> Timestamp {
            return .init(ns: UInt64((try? MkvmergeIdentification.init(filePath: file).container.properties?.duration) ?? 0)) 
        }
        
        if files.count == 1 {
            let filepath = files[0]
            let chapterName = fileName.filenameWithoutExtension + "_" + filepath.filenameWithoutExtension + "M2TS_chapter.txt"
            let chapter = chapterPath.appendingPathComponent(chapterName)
            return [MplsClip.init(fileName: fileName, duration: getDuration(file: filepath), trackLangs: trackLangs, m2tsPath: filepath, chapterPath: FileManager.default.fileExists(atPath: chapter) ? chapter : nil, index: nil)]
        } else {
            var index = 0
            return files.map({ (filepath) -> MplsClip in
                defer { index += 1 }
                let chapterName = fileName.filenameWithoutExtension + "_" + filepath.filenameWithoutExtension + "M2TS_chapter.txt"
                let chapter = chapterPath.appendingPathComponent(chapterName)
                return MplsClip.init(fileName: fileName, duration: getDuration(file: filepath), trackLangs: trackLangs, m2tsPath: filepath, chapterPath: FileManager.default.fileExists(atPath: chapter) ? chapter : nil, index: index)
            })
        }
    }
    
    private func generateChapterFile(chapterPath: String) throws {
        let mpls = try mplsParse(path: fileName)
        let chapters = mpls.split()
        if !compressed {
            precondition(files.count == chapters.count)
        }
        for (file, chap) in zip(files, chapters) {
            let output = chapterPath.appendingPathComponent("\(fileName.filenameWithoutExtension)_\(file.filenameWithoutExtension)M2TS_chapter.txt")
            if chap.nodes.count > 0 {
                try chap.exportOgm().write(toFile: output, atomically: true, encoding: .utf8)
            }
        }
        /*
        let script = #file.deletingLastPathComponent.appendingPathComponent("../../BD_Chapters_MOD.py")
        let p = try Process.init(executableName: "python", arguments: [script, fileName, "-o", chapterPath])
        p.launchUntilExit()
        try p.checkTerminationStatus()
        */
    }
    
}

extension Array where Element == Mpls {
    
    public var duplicateRemoved: [Mpls] {
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


