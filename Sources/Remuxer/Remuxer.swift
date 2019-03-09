//
//  Remuxer.swift
//  Remuxer
//
//  Created by Kojirou on 2018/9/17.
//

import Foundation
import Common
import MplsReader
import SPMUtility

public class Remuxer: Cli {

    struct RemuxerArgument {
        
        var outputDir: String
        
        var tempDir: String
        
        enum RemuxMode: String, CaseIterable {
            
            // auto detect
//            case auto
            // direct mux all mpls
            case movie
            // split all mpls
            case episodes
            // print mpls list
            case dump
            // input is *.mkv or something else
            case file
            // input is *.mpls
//            case splitMpls
            
            static var allSelection: String {
                return allCases.map{$0.rawValue}.joined(separator: "|")
            }
        }
        
        var mode: RemuxMode
        
        /// use in splitMpls mode
        var splits: [Int]?
        
        var inputs: [String]
        
        var languages: Set<String>
        
        static let defaultLanguages: Set<String> = ["und", "chi", "eng", "jpn"]
        
        var deleteAfterRemux: Bool
        
        var useLibbluray: Bool
    }
    
    typealias CliConfig = RemuxerArgument
    
    var config: RemuxerArgument
    
    let flacQueue = ParallelProcessQueue.init()
    
    init() {
        config = RemuxerArgument.init(outputDir: ".", tempDir: ".", mode: .movie, splits: nil, inputs: [], languages: RemuxerArgument.defaultLanguages, deleteAfterRemux: false, useLibbluray: false)
        av_log_set_level(AV_LOG_QUIET)
        flacQueue.maxConcurrentCount = 4
    }
    
    func parse(arguments: [String] = Array(CommandLine.arguments.dropLast())) throws {
        let parser = ArgumentParser.init(commandName: "Remuxer",
                                         usage: "--mode \(RemuxerArgument.RemuxMode.allSelection) [OPTIONS] [INPUT]",
            overview: "Automatic remux BDMV or media files.",
            seeAlso: nil)
        let binder = ArgumentBinder<RemuxerArgument>.init()
        
        binder.bind(option: parser.add(option: "--output", shortName: "-o", kind: String.self, usage: "output dir")) { (config, output) in
            config.outputDir = output
        }
        binder.bind(option: parser.add(option: "--temp", shortName: "-t", kind: String.self, usage: "temp dir")) { (config, temp) in
            config.tempDir = temp
        }
        binder.bind(option: parser.add(option: "--mode", kind: String.self, usage: "remux mode")) { (config, mode) in
            guard let modeV = RemuxerArgument.RemuxMode.init(rawValue: mode) else {
                fatalError("Unknown mode: \(mode)")
            }
            config.mode = modeV
        }
        binder.bind(option: parser.add(option: "--language", kind: String.self, usage: "valid languages")) { (config, v) in
            config.languages = Set(v.components(separatedBy: ",") + ["und"])
        }
        binder.bind(option: parser.add(option: "--splits", kind: String.self, usage: "split info")) { (config, splits) in
            let v = splits.split(separator: ",").map({ (str) -> Int in
                if let int = Int(str) {
                    return int
                } else {
                    fatalError("Invalid splits: \(splits)")
                }
            })
            config.splits = v
        }
        binder.bind(option: parser.add(option: "--delete-after-remux", kind: Bool.self, usage: "delete the src after remux")) { (config, d) in
            config.deleteAfterRemux = d
        }
        binder.bind(option: parser.add(option: "--use-libbluray", kind: Bool.self, usage: "delete the src after remux")) { (config, v) in
            config.useLibbluray = v
        }
        binder.bindArray(positional: parser.add(positional: "inputs", kind: [String].self, usage: "input's path")) { (config, inputs) in
            config.inputs = inputs
        }
        
        let result: ArgumentParser.Result
        do {
            result = try parser.parse(Array(CommandLine.arguments.dropFirst()))
        } catch {
            print(error)
            exit(1)
        }
        
        try binder.fill(parseResult: result, into: &config)
        config.tempDir = config.tempDir.appendingPathComponent("tmp")
        Swift.dump(config)
    }
    
    func run() throws {
        var failedTasks: [String] = []
        
        switch config.mode {
        case .dump:
            try config.inputs.forEach(dump(blurayPath: ))
        case /*.auto, */.episodes, .movie/*, .splitMpls*/:
            config.inputs.forEach({ (input) in
                try? FileManager.default.createDirectory(atPath: config.tempDir, withIntermediateDirectories: true, attributes: nil)
                do {
                    try remux(blurayPath: input, useMode: config.mode)
                    if config.deleteAfterRemux {
                        try? FileManager.default.removeItem(atPath: input)
                    }
                } catch {
                    print(error)
                    failedTasks.append(input)
                }
                clear()
            })
        case .file:
            var failed: [String] = []
            try? FileManager.default.createDirectory(atPath: config.tempDir, withIntermediateDirectories: true, attributes: nil)
            try config.inputs.forEach({ (file) in
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: file, isDirectory: &isDir) {
                    if isDir.boolValue {
                        // input is a directory, remux all contents
                        let outputDir = config.outputDir.appendingPathComponent(file.filename)
                        try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true, attributes: nil)
                        let contents = try FileManager.default.contentsOfDirectory(atPath: file)
                        contents.forEach({ (fileInDir) in
                            do {
                                try remux(file: fileInDir, remuxOutputDir: outputDir, deleteAfterRemux: false)
                            } catch {
                                failed.append(fileInDir)
                            }
                        })
                    } else {
                        do {
                            try remux(file: file, remuxOutputDir: config.outputDir, deleteAfterRemux: false)
                        } catch {
                            failed.append(file)
                        }
                    }
                } else {
                    print("\(file) doesn't exist!")
                }
            })
            if failed.count > 0 {
                print("Muxing files failed:\n\(failed.joined(separator: "\n"))")
            }
        }
        if failedTasks.count > 0 {
            print("failed tasks:")
            print(failedTasks.joined(separator: "\n"))
        }
    }
    
    var runningProcess: Process?
    
    func clear() {
        runningProcess?.terminate()
        runningProcess = nil
        flacQueue.terminateAllProcesses()
        try! FileManager.default.removeItem(atPath: config.tempDir)
    }
    
}

extension Remuxer {
    
    private func dump(blurayPath: String) throws {
        try remux(blurayPath: blurayPath, useMode: .dump)
    }

    private func remux(blurayPath: String, useMode: RemuxerArgument.RemuxMode) throws {
        
        let bdFolderName = getBlurayTitle(path: blurayPath, useLibbluray: config.useLibbluray).safeFilename().trimmingCharacters(in: .whitespacesAndNewlines)

        let finalOutputDir = config.outputDir.appendingPathComponent(bdFolderName)
        
        if useMode != .dump, FileManager.default.fileExists(atPath: finalOutputDir) {
            throw RemuxerError.outputExist
        }
        
        print("BD title: \(bdFolderName)")
        
        let mplsList = try scan(blurayPath: blurayPath, removeDuplicate: true)
        
        if mplsList.count > 0 {
            print("MPLS List:\n")
            mplsList.forEach {print($0);print()}
        } else {
            print("No mpls found!")
            return
        }
        
        if useMode == .dump {
            return
        }
        
        // TODO: check conflict
        
        var tempFiles = [String]()
        
        if useMode == .episodes {
            var allFiles = Set(mplsList.flatMap {$0.files})
            try mplsList.forEach { (mpls) in
                tempFiles.append(contentsOf: try split(mpls: mpls, restFiles: allFiles))
                mpls.files.forEach({ (usedFile) in
                    allFiles.remove(usedFile)
                })
            }
        } else if useMode == .movie {
            try mplsList.forEach { (mpls) in
                if mpls.useFFmpeg || mpls.compressed/* || mpls.remuxMode == .split*/ {
                    tempFiles.append(contentsOf: try split(mpls: mpls))
                } else {
                    let preferedLanguages = generatePrimaryLanguages(with: [mpls.primaryLanguage])
                    let outputFilename = generateFilename(mpls: mpls)
                    let output = config.tempDir.appendingPathComponent(outputFilename + ".mkv")
                    
                    if config.splits != nil {
                        let m = MkvmergeMuxer.init(input: mpls.fileName, output: output, audioLanguages: preferedLanguages, subtitleLanguages: preferedLanguages, extraArguments: generateSplitArguments(mpls: mpls))
                        try launchProcessAndWaitAndCheck(process: m.convert())
                        let outputs = try FileManager.default.contentsOfDirectory(atPath: config.tempDir).filter({$0.hasPrefix(outputFilename)}).map({config.tempDir.appendingPathComponent($0)})
                        tempFiles.append(contentsOf: outputs)
                    } else {
                        do {
                            let m = MkvmergeMuxer.init(input: mpls.fileName, output: output, audioLanguages: preferedLanguages, subtitleLanguages: preferedLanguages)
                            try launchProcessAndWaitAndCheck(process: m.convert())
                            tempFiles.append(output)
                        } catch {
                            tempFiles.append(contentsOf: try split(mpls: mpls))
                        }
                        
                    }
                }
            }
        }
        
        try tempFiles.forEach { (tempFile) in
            try remux(file: tempFile, remuxOutputDir: finalOutputDir, deleteAfterRemux: true)
        }
    }
    
    func remux(file: String, remuxOutputDir: String, deleteAfterRemux: Bool, parseOnly: Bool = false) throws {
        let outputFilename = remuxOutputDir.appendingPathComponent(file.filenameWithoutExtension + ".mkv")
        guard outputFilename != file else {
            print("\(outputFilename) already exists!")
            return
        }
        var arguments = ["-q", "--output", outputFilename]
        var trackOrder = [String]()
        var audioRemoveTracks = [Int]()
        var subtitleRemoveTracks = [Int]()
        var externalTracks = [(file: String, lang: String)]()
        
        let mkvinfo = try MkvmergeIdentification.init(filePath: file)
        let modifications = try makeTrackModification(mkvinfo: mkvinfo)
        
        for modify in modifications.enumerated() {
            switch modify.element {
            case .copy(_):
                trackOrder.append("0:\(modify.offset)")
            case .remove(let type):
                switch type {
                case AVMEDIA_TYPE_AUDIO:
                    audioRemoveTracks.append(modify.offset)
                case AVMEDIA_TYPE_SUBTITLE:
                    subtitleRemoveTracks.append(modify.offset)
                default:
                    break
                }
            case .replace(let type, let file, let lang):
                switch type {
                case AVMEDIA_TYPE_AUDIO:
                    audioRemoveTracks.append(modify.offset)
                case AVMEDIA_TYPE_SUBTITLE:
                    subtitleRemoveTracks.append(modify.offset)
                default:
                    break
                }
                externalTracks.append((file: file, lang: lang))
                trackOrder.append("\(externalTracks.count):0")
            }
        }

        if audioRemoveTracks.count > 0 {
            arguments.append(contentsOf: ["-a", "!\(audioRemoveTracks.map({$0.description}).joined(separator: ","))"])
        }
        
        if subtitleRemoveTracks.count > 0 {
            arguments.append(contentsOf: ["-s", "!\(subtitleRemoveTracks.map({$0.description}).joined(separator: ","))"])
        }
        
        arguments.append(file)
        externalTracks.forEach { (track) in
            arguments.append(contentsOf: ["--language", "0:\(track.lang)", track.file])
        }
        arguments.append(contentsOf: ["--track-order", trackOrder.joined(separator: ",")])
        print("Mkvmerge arguments:\n\(arguments.joined(separator: " "))")
        let mkvmerge = try Process.init(executableName: "mkvmerge", arguments: arguments)
        print("\nMkvmerge:\n\(file)\n->\n\(outputFilename)")
        try launchProcessAndWaitAndCheck(process: mkvmerge)
        
        externalTracks.forEach { (t) in
            do {
                try FileManager.default.removeItem(atPath: t.file)
            } catch {
                print("Can not delete file: \(t.file)")
            }
        }
        if deleteAfterRemux {
            do {
                try FileManager.default.removeItem(atPath: file)
            } catch {
                print("Can not delete file: \(file)")
            }
        }
        
    }
    
}

// MARK: - MPLS related
extension Remuxer {
    
    func split(mplsPath: String) throws -> [String] {
        let mpls = try Mpls.init(filePath: mplsPath)
        return try split(mpls: mpls)
    }
    
    func split(mpls: Mpls) throws -> [String] {
        return try split(mpls: mpls, restFiles: Set(mpls.files))
    }
    
    func split(mpls: Mpls, restFiles: Set<String>) throws -> [String] {
        
        print("Splitting MPLS: \(mpls.fileName)")
        
        if restFiles.count == 0 {
            return []
        }
        
        let clips = mpls.split(chapterPath: config.tempDir)
        let preferedLanguages = generatePrimaryLanguages(with: [mpls.primaryLanguage])
        
        return try clips.compactMap { (clip) -> String? in
            if restFiles.contains(clip.m2tsPath) {
                let output: String
                let outputBasename = "\(mpls.fileName.filenameWithoutExtension)-\(clip.baseFilename)"
                if mpls.useFFmpeg {
                    let outputFilename = "\(outputBasename)-ffmpeg.mkv"
                    output = config.tempDir.appendingPathComponent(outputFilename)
                    do {
                        let ff = FFmpegMuxer.init(input: clip.m2tsPath, output: output, mode: .videoOnly)
                        try launchProcessAndWaitAndCheck(process: ff.convert())
                    } catch {
                        let ff = FFmpegMuxer.init(input: clip.m2tsPath, output: output, mode: .audioOnly)
                        try launchProcessAndWaitAndCheck(process: ff.convert())
                    }
                } else {
                    let outputFilename = "\(outputBasename).mkv"
                    output = config.tempDir.appendingPathComponent(outputFilename)
                    let m = MkvmergeMuxer.init(input: clip.m2tsPath, output: output, audioLanguages: preferedLanguages, subtitleLanguages: preferedLanguages, chapterPath: clip.chapterPath)
                    try launchProcessAndWaitAndCheck(process: m.convert())
                }
                return output
            } else {
                print("Skipping clip: \(clip)")
                return nil
            }
            
        }
    }
    
}

// MARK: - Utilities
extension Remuxer {
    
    private func scan(blurayPath: String, removeDuplicate: Bool) throws -> [Mpls] {
        print("Start scanning BD folder: \(blurayPath)")
        let fm = FileManager.default
        let playlistPath = blurayPath.appendingPathComponent("BDMV/PLAYLIST")
        //        let streamPath = rootpath.appendingPathComponent("BDMV/STREAM")
        if fm.fileExists(atPath: playlistPath) {
            let mplsPaths = try fm.contentsOfDirectory(atPath: playlistPath)
                .filter {$0.hasSuffix(".mpls")}
            let allMpls = mplsPaths.compactMap { (mplsPath) -> Mpls? in
                do {
                    return try .init(filePath: playlistPath.appendingPathComponent(mplsPath))
                } catch {
                    print("Invalid file: \(mplsPath)")
                    return nil
                }
            }
            if removeDuplicate {
                let multipleFileMpls = allMpls.filter{ !$0.isSingle }.duplicateRemoved
                let singleFileMpls = allMpls.filter{ $0.isSingle }.duplicateRemoved
                var cleanMultipleFileMpls = [Mpls]()
            
                for multipleMpls in multipleFileMpls {
                    if multipleMpls.files.filter({ (file) -> Bool in
                        return !singleFileMpls.contains(where: { (mpls) -> Bool in
                            return mpls.files[0] == file
                        })
                    }).count > 0 {
                        cleanMultipleFileMpls.append(multipleMpls)
                    }
                }
                return (cleanMultipleFileMpls + singleFileMpls).sorted()
            } else {
                return allMpls
            }
        } else {
            print("No PLAYLIST Folder!")
            return []
        }
    }
    
    private func generatePrimaryLanguages(with otherLanguages: [String]) -> Set<String> {
        var preferedLanguages = config.languages
        otherLanguages.forEach { (l) in
            preferedLanguages.insert(l)
        }
        return preferedLanguages
    }
    
    private func generateFilename(mpls: Mpls) -> String {
        return "\(mpls.fileName.filenameWithoutExtension)-\(mpls.files.map{$0.filenameWithoutExtension}.joined(separator: "+").prefix(50))"
    }
    
    private func generateFilename(clip: MplsClip) -> String {
        return "\(clip.fileName.filenameWithoutExtension)-\(clip.m2tsPath.filenameWithoutExtension)"
    }
    
    private func generateSplitArguments(mpls: Mpls) -> [String] {
        guard let splits = config.splits, splits.count > 0 else {
            return []
        }
        let totalChaps = splits.reduce(0, +)
        if totalChaps == mpls.chapterCount {
            var chapIndex = [Int]()
            var chapCount = 0
            splits.forEach { (chap) in
                chapIndex.append(chap+1+chapCount)
                chapCount += chap
            }
            return ["--split", "chapters:\(chapIndex.dropLast().map{$0.description}.joined(separator: ","))"]
        } else {
            return []
        }
    }
    
    private func display(modiifcations: [TrackModification]) {
        print("Track modifications: ")
        for m in modiifcations.enumerated() {
            print("\(m.offset): \(m.element)")
        }
    }
    
    private func launchProcessAndWaitAndCheck(process: Process) throws {
        runningProcess = process
        process.launchUntilExit()
        try process.checkTerminationStatus()
        runningProcess = nil
    }
    
    private func makeTrackModification(mkvinfo: MkvmergeIdentification) throws -> [TrackModification] {
        let context = try AVFormatContextWrapper.init(url: mkvinfo.fileName)
        try context.findStreamInfo()
        guard context.streamCount == mkvinfo.tracks.count else {
            print("ffmpeg and mkvmerge track count mismatch!")
            throw RemuxerError.t
        }
        
        let preferedLanguages = generatePrimaryLanguages(with: [mkvinfo.primaryLanguage])
        let streams = context.streams
        var flacConverters = [Flac]()
        var ffmpegArguments = ["-v", "quiet", "-nostdin", "-y", "-i", mkvinfo.fileName, "-vn"]
        var trackModifications = [TrackModification].init(repeating: .copy(type: AVMEDIA_TYPE_UNKNOWN), count: streams.count)
        
        defer {
            display(modiifcations: trackModifications)
        }
        
        // check track one by one
        print("Checking tracks codec")
        var index = 0
        while index < streams.count {
            let stream = streams[index]
            let streamLanguage = mkvinfo.tracks[index].properties.language ?? "und"
            print("\(stream.index): \(stream.codecpar.codecId.name) \(stream.isLosslessAudio ? "lossless" : "lossy") \(streamLanguage) \(stream.codecpar.channelCount)ch")
            if stream.isLosslessAudio, preferedLanguages.contains(streamLanguage) {
                // add to ffmpeg arguments
                let tempFlac = config.tempDir.appendingPathComponent("\(mkvinfo.fileName.filenameWithoutExtension)-\(stream.index)-\(streamLanguage)-ffmpeg.flac")
                let finalFlac = config.tempDir.appendingPathComponent("\(mkvinfo.fileName.filenameWithoutExtension)-\(stream.index)-\(streamLanguage).flac")
                ffmpegArguments.append(contentsOf: ["-map", "0:\(stream.index)", tempFlac])
                flacConverters.append(Flac.init(input: tempFlac, output: finalFlac))
                
                trackModifications[index] = .replace(type: AVMEDIA_TYPE_AUDIO, file: finalFlac, lang: streamLanguage)
            } else if preferedLanguages.contains(streamLanguage) {
                trackModifications[index] = .copy(type: stream.mediaType)
            } else {
                trackModifications[index] = .remove(type: stream.mediaType)
            }
            if stream.isTruehd, index+1<streams.count,
                case let nextStream = streams[index+1],
                nextStream.isAC3 {
                // Remove TRUEHD embed-in AC-3 track
                trackModifications[index+1] = .remove(type: AVMEDIA_TYPE_AUDIO)
                index += 1
            }
            index += 1
        }
        
        guard flacConverters.count > 0 else {
            return trackModifications
        }
        
        print("ffmpeg \(ffmpegArguments.joined(separator: " "))")
        let ffmpeg = try Process.init(executableName: "ffmpeg", arguments: ffmpegArguments)
        try launchProcessAndWaitAndCheck(process: ffmpeg)

        flacConverters.forEach { (flac) in
            let process = try! flac.convert()
            process.terminationHandler = { p in
                if p.terminationStatus != 0 {
                    print("error while converting flac \(flac.input)")
                }
                try! FileManager.default.removeItem(atPath: flac.input)
            }
            flacQueue.add(process)
        }
        flacQueue.waitUntilAllOProcessesAreFinished()
        
        // check duplicate audio track
        let flacPaths = flacConverters.map({$0.output})
        let flacMD5s = try FlacMD5.calculate(inputs: flacPaths)
        guard flacPaths.count == flacMD5s.count else {
            fatalError("Flac MD5 count dont match")
        }
        
        let md5Set = Set(flacMD5s)
        if md5Set.count < flacMD5s.count {
            print("Duplicate tracks")
            // verify duplicate
            var duplicateFiles = [[String]]()
            for md5 in md5Set {
                let currentCount = flacMD5s.count(where: {$0 == md5})
                precondition(currentCount > 0)
                if currentCount == 1 {
                    
                } else {
                    let indexes = flacMD5s.indexes(of: md5)
                    
                    duplicateFiles.append(indexes.map({flacPaths[$0]}))
                }
            }
            
            // remove extra duplicate tracks
            for filesWithSameMD5 in duplicateFiles {
                var allTracks = [(Int, TrackModification)]()
                for m in trackModifications.enumerated() {
                    switch m.element {
                    case .replace(type: _, file: let file, lang: _):
                        if filesWithSameMD5.contains(file) {
                            allTracks.append(m)
                        }
                    default:
                        break
                    }
                }
                precondition(allTracks.count > 1)
                let removeTracks = allTracks[1...]
                removeTracks.forEach({
                    var old = trackModifications[$0.0]
                    old.remove()
                    trackModifications[$0.0] = old
                })
            }
        }
        
        return trackModifications
    }
    
}

enum TrackModification {
    
    case copy(type: AVMediaType)
    case replace(type: AVMediaType, file: String, lang: String)
    case remove(type: AVMediaType)
    
    mutating func remove() {
        switch self {
        case .replace(type: let type, file: let file, lang: _):
            try? FileManager.default.removeItem(atPath: file)
            self = .remove(type: type)
        case .copy(type: let type):
            self = .remove(type: type)
        case .remove(type: _):
            return
        }
        
    }
    
    var type: AVMediaType {
        switch self {
        case .replace(type: let type, file: _, lang: _):
            return type
        case .copy(type: let type):
            return type
        case .remove(type: let type):
            return type
        }
    }
    
}

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

protocol Cli {
    
    associatedtype CliConfig
    
    var config: CliConfig { set get }
    
    func parse(arguments: [String]) throws
    
    func run() throws
    
}

//func run(inputs: [String]) -> [Result<Diag, RemuxerError>] {
//    return inputs.map { _ -> Result<Diag, RemuxerError> in
//        return Result<Diag, RemuxerError>.init(catching: { () -> Diag in
//                return .init()
//        })
//    }
//}

struct Diag {
    
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
