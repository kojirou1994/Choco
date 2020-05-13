import Foundation
import MediaTools
import MplsParser

extension MplsClip {
    
    public var baseFilename: String {
        if let index = self.index {
            return "\(index)-\(m2tsPath.lastPathComponentWithoutExtension)"
        } else {
            return m2tsPath.lastPathComponentWithoutExtension
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
    public func split(chapterPath: URL) throws -> [MplsClip] {
        
        let chapters = try generateChapterFile(chapterPath: chapterPath)
        
        func getDuration(file: String) -> Timestamp {
            return .init(ns: UInt64((try? MkvmergeIdentification.init(filePath: file).container.properties?.duration) ?? 0))
        }
        
        if files.count == 1 {
            let filepath = files[0]
            return [MplsClip.init(fileName: fileName, duration: getDuration(file: filepath.path), trackLangs: trackLangs, m2tsPath: filepath, chapterPath: chapters[0], index: nil)]
        } else {
            var index = 0
            return files.map({ (filepath) -> MplsClip in
                defer { index += 1 }
                return MplsClip.init(fileName: fileName, duration: getDuration(file: filepath.path), trackLangs: trackLangs, m2tsPath: filepath, chapterPath: chapters[index], index: index)
            })
        }
    }
    
    private func generateChapterFile(chapterPath: URL) throws -> [URL?] {
        let mpls = try MplsPlaylist.parse(mplsURL: fileName)
        let chapters = mpls.split()
        if !compressed {
            precondition(files.count <= chapters.count)
        }
        return try zip(files, chapters).map({ (file, chap) -> URL? in
            let output = chapterPath.appendingPathComponent("\(fileName.lastPathComponentWithoutExtension)_\(file.lastPathComponentWithoutExtension)_chapter.txt")
            if chap.nodes.count > 0 {
                try chap.exportOgm().write(to: output, atomically: true, encoding: .utf8)
                return output
            } else {
                return nil
            }
        })
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


