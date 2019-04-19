import Common
import MplsReader
import Foundation
import SwiftFFmpeg
import Signals
import ArgumentParser

var runningProcess: Process?

Signals.trap(signals: [.quit, .int, .kill, .term, .abrt]) { (_) in
    print("bye-bye")
    runningProcess?.terminate()
    exit(0)
}

enum Mp4Error: Error {
    case unsupportedFps(UInt64)
    case unsupportedCodec(String)
    case processError(String)
    case unsupportedPixelFormat(FFmpegPixelFormat)
}

enum MkvTrack {
    case video(Video)
    case audio(Audio)
    case subtitle(Subtitle)
    struct Video {
        let fps: VideoRate
        let path: String
    }
    
    struct Audio {
        let lang: String
        let path: String
        let encodedPath: String
        let needReencode: Bool
        
        init(lang: String, path: String, needReencode: Bool) {
            self.lang = lang
            self.path = path
            self.needReencode = needReencode
            if needReencode {
                self.encodedPath = path.deletingPathExtension.appendingPathExtension("m4a")
            } else {
                self.encodedPath = path
            }
        }
    }
    
    struct Subtitle {
        let lang: String
        let path: String
        let type: SubtitleType
        enum SubtitleType {
            case ass
            case srt
            case pgs
        }
    }
}

func beforRun(p: Process) {
    p.standardOutput = FileHandle.nullDevice
    runningProcess = p
}

func afterRun(p: Process) {
    runningProcess = nil
}

func remove(files: [String]) {
    files.forEach { (p) in
        try? FileManager.default.removeItem(atPath: p)
    }
}

//func mkvextractAllTracks() throws -> [MkvTrack] {
//    
//}

let invalidPixelFormats: [FFmpegPixelFormat] = [.yuv420p10le, .yuv420p10be]

func toMp4(file: String, extractOnly: Bool) throws {
    guard file.hasSuffix(".mkv") else {
        return
    }
    
    if file.lastPathComponent.lowercased().contains("vfr") {
        print("Skipping \(file), probably vfr.")
        return
    }
    
    do {
        let context = try FFmpegInputFormatContext.init(url: file)
        try context.findStreamInfo()
        //    context.dumpFormat(isOutput: false)
        for stream in context.streams {
            let codecParameters = stream.codecParameters
            print(codecParameters.codecId)
            if stream.mediaType == .video,
                codecParameters.codecId == .h264,
                invalidPixelFormats.contains(codecParameters.pixelFormat) {
                throw Mp4Error.unsupportedPixelFormat(stream.codecParameters.pixelFormat)
            }
            if stream.mediaType == .video {
                print(codecParameters.pixelFormat)
            }
        }
    }
    
    let mkvinfo = try MkvmergeIdentification.init(filePath: file)
    
    // multi audio tracks mkv is not supported
//    guard mkvinfo.tracks.filter({$0.type == "audio"}).count < 2 else {
//        return
//    }
    
    let mp4path = file.deletingPathExtension.appendingPathExtension("mp4")
    remove(files: [mp4path])
    let tempfile = UUID.init().uuidString.appendingPathExtension("mp4")
    let chapterpPath = file.deletingPathExtension.appendingPathExtension("chap.txt")
    var arguments = [file, "tracks"]
    arguments.reserveCapacity(mkvinfo.tracks.count + 3)
    var tracks = [MkvTrack]()
    tracks.reserveCapacity(mkvinfo.tracks.count)
    try mkvinfo.tracks.forEach { (track) in
        print("\(track.id) \(track.codec) \(track.type)")
        
        let trackExtension: String
        var needReencode = false
        switch track.codec {
        case "MPEG-H/HEVC/h.265":
            trackExtension = "265"
        case "FLAC":
            trackExtension = "flac"
            needReencode = true
        case "AAC":
            trackExtension = "aac"
        case "AC-3", "E-AC-3":
            trackExtension = "ac3"
        case "MPEG-4p10/AVC/h.264":
            trackExtension = "264"
        case "HDMV PGS":
            trackExtension = "sup"
        case "PCM":
            trackExtension = "wav"
            needReencode = true
        case "SubStationAlpha":
            trackExtension = "ass"
        case "SubRip/SRT":
            trackExtension = "srt"
        case "TrueHD Atmos":
            trackExtension = "truehd"
            needReencode = true
        case "DTS-HD Master Audio":
            trackExtension = "dts"
            needReencode = true
        default:
            throw Mp4Error.unsupportedCodec(track.codec)
        }
        let outputTrackName = "\(file.deletingPathExtension).\(track.id).\(track.properties.language ?? "und").\(trackExtension)"
        
        switch track.type {
        case "video":
            let fpsValue = 1_000_000_000_000/UInt64(track.properties.defaultDuration!)
            let fps: VideoRate
            switch fpsValue {
            case 23976:
                fps = .k23_976
            case 25000:
                fps = .k25
            case 29970:
                fps = .k29_97
            case 24000:
                fps = .k24
            case 50000:
                fps = .k50
            case 59940:
                fps = .k59_94
            default:
                throw Mp4Error.unsupportedFps(fpsValue)
            }
//            print(fps)
            tracks.append(.video(.init(fps: fps, path: outputTrackName)))
        case "audio":
            tracks.append(.audio(.init(lang: track.properties.language ?? "und", path: outputTrackName, needReencode: needReencode)))
        case "subtitles":
            let type: MkvTrack.Subtitle.SubtitleType
            switch track.codec {
            case "HDMV PGS":
                type = .pgs
            case "SubStationAlpha":
                type = .ass
            case "SubRip/SRT":
                type = .srt
            default:
                print("Invalid subtitle codec: \(track.codec)")
                throw Mp4Error.unsupportedCodec(track.codec)
            }
            let extractedTrack = MkvTrack.subtitle(.init(lang: track.properties.language ?? "und", path: outputTrackName, type: type))
        default:
            fatalError(track.type)
        }
        
        arguments.append("\(track.id):\(outputTrackName)")
    }
//    print(arguments.joined(separator: " "))
//    dump(tracks)
    
    arguments.append(contentsOf: ["chapters", "-s", chapterpPath])
    
    // MARK: - mkvextract
    print("Extracting tracks...")
    try MKVextract(arguments: arguments).runAndWait(checkNonZeroExitCode: true, beforeRun: beforRun(p:), afterRun: afterRun(p:))
    if extractOnly {
        return
    }
    defer {
        remove(files: tracks.flatMap({ (track) -> [String] in
            switch track {
            case .audio(let a): return [a.path, a.encodedPath]
            case .video(let v): return [v.path]
            default: return []
            }
        }))
        remove(files: [tempfile, chapterpPath])
    }
    try tracks.forEach { (track) in
        if case let MkvTrack.audio(a) = track, a.needReencode {
            try FFmpeg(arguments: ["-v", "quiet", "-nostdin",
                                   "-y", "-i", a.path, "-c:a", "alac", a.encodedPath]).runAndWait(checkNonZeroExitCode: true, beforeRun: beforRun(p:), afterRun: afterRun(p:))
        }
    }
    var boxArg = ["-tmp", "."]
    tracks.forEach { (track) in
        switch track {
        case .audio(let a):
            if a.lang != "und" {
                boxArg.append(contentsOf: ["-add", "\(a.encodedPath):lang=\(a.lang)"])
            } else {
                boxArg.append(contentsOf: ["-add", a.encodedPath])
            }
        case .video(let v):
            boxArg.append(contentsOf: ["-add", v.path, "-fps", v.fps.description])
        default:
            break
        }
    }
    
    boxArg.append(tempfile)
    try MP4Box(arguments: boxArg).runAndWait(checkNonZeroExitCode: true, beforeRun: beforRun(p:), afterRun: afterRun(p:))
    var remuxerArg: [String]
    if FileManager.default.fileExists(atPath: chapterpPath) {
        remuxerArg = ["--chapter", chapterpPath]
    } else {
        remuxerArg = []
    }
    remuxerArg.append(contentsOf: ["-i", "\(tempfile)?1:handler=", "-o", mp4path])
    try LsmashRemuxer(arguments: remuxerArg).runAndWait(checkNonZeroExitCode: true, beforeRun: beforRun(p:), afterRun: afterRun(p:))
}

func addTask(file: String, extractOnly: Bool) {
    do {
        try toMp4(file: file, extractOnly: extractOnly)
    } catch {
        print("Failed file: \(file)")
        print("Error info: \(error)")
    }
}

struct Argument {
    var extractOnly = false
    var help = false
    var inputs = [String]()
}

var argument = Argument()
let help = Option(name: "--help", anotherName: "-H", requireValue: false, description: "show help info") { (_) in
    argument.help = true
}
let extractOnly = Option(name: "--extract-only", requireValue: false, description: "extractOnly") { (_) in
    argument.extractOnly = true
}
let parser = ArgumentParser(usage: "MKV2MP4 [OPTION] inputs", options: [extractOnly, help]) { (v) in
    argument.inputs.append(v)
}
try parser.parse(arguments: CommandLine.arguments.dropFirst())
if argument.help {
    parser.showHelp(to: &stderrOutputStream)
    exit(0)
}

argument.inputs.forEach { (input) in
    var isDirectory: ObjCBool = false
    if FileManager.default.fileExists(atPath: input, isDirectory: &isDirectory) {
        if isDirectory.boolValue {
            if let enumerator = FileManager.default.enumerator(atPath: input) {
                for case let path as String in enumerator {
                    addTask(file: input.appendingPathComponent(path), extractOnly: argument.extractOnly)
                }
            } else {
                print("Can't open folder: \(input)")
            }
        } else {
            addTask(file: input, extractOnly: argument.extractOnly)
        }
    } else {
        print("File doesn't exist: \(input)")
    }
}

func changeFilename(origin: String) -> String {
    let lowercased = origin.lowercased()
    if lowercased.contains("flac") {
        return origin.replacingOccurrences(of: "flac", with: "alac")
                     .replacingOccurrences(of: "Flac", with: "Alac")
                     .replacingOccurrences(of: "FLAC", with: "ALAC")
//                     .replacingOccurrences(of: "flac", with: "alac")
    } else {
        return origin
    }
}
