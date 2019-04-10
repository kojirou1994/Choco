import Common
import MplsReader
import Foundation

import Signals

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
    }
    
//    var path: String {
//        switch self {
//        case .audio(let v):
//            return v.path
//        case .video(let v):
//            return v.path
//        }
//    }
}

extension Process {
    func runAndCheck() throws {
        self.standardOutput = FileHandle.nullDevice
        launch()
        runningProcess = self
        waitUntilExit()
        runningProcess = nil
        if terminationStatus != 0 {
            throw Mp4Error.processError(launchPath!)
        }
    }
}

func remove(files: [String]) {
    files.forEach { (p) in
        try? FileManager.default.removeItem(atPath: p)
    }
}

//func mkvextractAllTracks() throws -> [MkvTrack] {
//    
//}

func toMp4(file: String) throws {
    guard file.hasSuffix(".mkv") else {
        return
    }
    let mkvinfo = try MkvmergeIdentification.init(filePath: file)
    
    // multi audio tracks mkv is not supported
    guard mkvinfo.tracks.filter({$0.type == "audio"}).count < 2 else {
        return
    }
    
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
            print(fps)
            tracks.append(.video(.init(fps: fps, path: outputTrackName)))
        case "audio":
            tracks.append(.audio(.init(lang: track.properties.language ?? "und", path: outputTrackName, needReencode: needReencode)))
        case "subtitles":
            let extractedTrack = MkvTrack.subtitle(.init(lang: track.properties.language ?? "und"))
        default:
            fatalError(track.type)
        }
        
        
        
        arguments.append("\(track.id):\(outputTrackName)")
    }
//    print(arguments.joined(separator: " "))
//    dump(tracks)
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
    arguments.append(contentsOf: ["chapters", "-s", chapterpPath])
    
    // MARK: - mkvextract
    try Process.init(executableName: "mkvextract", arguments: arguments).runAndCheck()
    try tracks.forEach { (track) in
        if case let MkvTrack.audio(a) = track, a.needReencode {
            try Process.init(executableName: "ffmpeg",
                             arguments: ["-v", "quiet", "-nostdin",
                                       "-y", "-i", a.path, "-c:a", "alac", a.encodedPath]).runAndCheck()
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
    try Process.init(executableName: "MP4Box",
                     arguments: boxArg).runAndCheck()
    var remuxerArg: [String]
    if FileManager.default.fileExists(atPath: chapterpPath) {
        remuxerArg = ["--chapter", chapterpPath]
    } else {
        remuxerArg = []
    }
    remuxerArg.append(contentsOf: ["-i", "\(tempfile)?1:handler=", "-o", mp4path])
    try Process.init(executableName: "remuxer",
                     arguments: remuxerArg).runAndCheck()
}

func addTask(file: String) {
    do {
        try toMp4(file: file)
    } catch {
        print("Failed file: \(file)")
        print("Error info: \(error)")
    }
}

CommandLine.arguments[1...].forEach { (input) in
    var isDirectory: ObjCBool = false
    if FileManager.default.fileExists(atPath: input, isDirectory: &isDirectory) {
        if isDirectory.boolValue {
            if let enumerator = FileManager.default.enumerator(atPath: input) {
                for case let path as String in enumerator {
                    addTask(file: input.appendingPathComponent(path))
                }
            } else {
                print("Can't open folder: \(input)")
            }
        } else {
            addTask(file: input)
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
