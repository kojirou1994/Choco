//
//  extensions.swift
//  Remuxer
//
//  Created by Kojirou on 2019/4/11.
//

import Foundation
//import SwiftFFmpeg
import MplsReader

extension Array where Element: Equatable {
    
    //    func countValue(_ v: Element) -> Int {
    //        return self.reduce(0, { (result, current) -> Int in
    //            if current == v {
    //                return result + 1
    //            } else {
    //                return result
    //            }
    //        })
    //    }
    
    func indexes(of v: Element) -> [Index] {
        var r = [Index]()
        for (index, current) in enumerated() {
            if current == v {
                r.append(index)
            }
        }
        return r
    }
    
}

extension Sequence {
    func count(where predicate: (Element) throws -> Bool) rethrows -> Int {
        var count = 0
        for element in self {
            if try predicate(element) {
                count += 1
            }
        }
        return count
    }
}

extension MplsClip {
    
    public var baseFilename: String {
        if let index = self.index {
            return "\(index)-\(m2tsPath.filenameWithoutExtension)"
        } else {
            return m2tsPath.filenameWithoutExtension
        }
    }
    
}

public enum MplsRemuxMode {
    case direct
    case split
}

extension Mpls {
    
    public var useFFmpeg: Bool {
        //        MplsClip.
        return trackLangs.count == 0
    }
    
    public var primaryLanguage: String {
        return trackLangs.first(where: {$0 != "und"}) ?? "und"
    }
    
    public var isSingle: Bool {
        return files.count == 1
    }
    
    /*
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
        let fileContexts = files.map { (file) -> FFmpegInputFormatContext in
            let c = try! FFmpegInputFormatContext.init(url: file)
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
    
    private func formatMatch(l: FFmpegInputFormatContext, r: FFmpegInputFormatContext) -> Bool {
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
    */
    public func split(chapterPath: String) -> [MplsClip] {
        
        do {
            try generateChapterFile(chapterPath: chapterPath)
        } catch {
            print("Generate Chapter File for \(fileName) failed: \(error)")
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
            precondition(files.count <= chapters.count)
        }
        for (file, chap) in zip(files, chapters) {
            let output = chapterPath.appendingPathComponent("\(fileName.filenameWithoutExtension)_\(file.filenameWithoutExtension)M2TS_chapter.txt")
            if chap.nodes.count > 0 {
                try chap.exportOgm().write(toFile: output, atomically: true, encoding: .utf8)
            }
        }
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


