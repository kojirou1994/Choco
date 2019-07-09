//
//  Remuxer.swift
//  Remuxer
//
//  Created by Kojirou on 2018/9/17.
//

import Foundation
@_exported import MediaTools
import MplsReader
import ArgumentParser
import Executable
import Path

public enum RemuxerError: Error {
    case errorReadingFile
    case noPlaylists
    case sameFilename
    case outputExist
    case noOutputFile(Path)
}

struct RemuxerArgument {
    
    var outputPath: Path
    
    var temporaryPath: Path
    
    enum RemuxMode: String, CaseIterable {
        
        // auto detect
        //            case auto
        // direct mux all mpls
        case movie
        // split all mpls
        case episodes
        // print mpls list
        case dumpBDMV
        // input is *.mkv or something else
        case file
        // input is *.mpls
        //            case splitMpls
        
        static var allSelection: String {
            return allCases.map{$0.rawValue}.joined(separator: "|")
        }
    }
    
    var mode: RemuxMode
    
    var splits: [Int]?
    
    var inputs: [Path]
    
    var languages: Set<String>
    
    var excludeLanguages: Set<String>
    
    static let defaultLanguages: Set<String> = ["und", "chi", "eng", "jpn"]
    
    var deleteAfterRemux: Bool
    
    var keepTrackName: Bool
    
    var help: Bool
}

public class Remuxer {
    
    let config: RemuxerArgument
    
    let flacQueue = ParallelProcessQueue.init()
    
    let processManager = SubProcessManager()
    
    init() throws {
        var config = RemuxerArgument.init(outputPath: .cwd, temporaryPath: .cwd, mode: .movie, splits: nil, inputs: [], languages: RemuxerArgument.defaultLanguages, excludeLanguages: [], deleteAfterRemux: false, keepTrackName: false, help: false)
        let output = Option(name: "--output", anotherName: "-o", requireValue: true, description: "output dir") { (v) in
            config.outputPath = Path.init(url: URL.init(fileURLWithPath: v))!
        }
        
        let temp = Option(name: "--temp", anotherName: "-t", requireValue: true, description: "temp dir") { (v) in
            config.temporaryPath = Path.init(url: URL.init(fileURLWithPath: v))!
        }
        
        let mode = Option(name: "--mode", requireValue: true, description: "remux mode") { (v) in
            guard let modeV = RemuxerArgument.RemuxMode.init(rawValue: v) else {
                fatalError("Unknown mode: \(v)")
            }
            config.mode = modeV
        }
        let language = Option(name: "--language", requireValue: true, description: "valid languages") { (v) in
            config.languages = Set(v.components(separatedBy: ",") + ["und"])
        }
        let excludeLanguage = Option(name: "--exclude-language", requireValue: true, description: "exclude languages") { (v) in
            config.excludeLanguages = Set(v.components(separatedBy: ","))
        }
        let splits = Option(name: "--splits", requireValue: true, description: "split info") { (v) in
            let splits = v.split(separator: ",").map({ (str) -> Int in
                if let int = Int(str) {
                    return int
                } else {
                    fatalError("Invalid splits: \(v)")
                }
            })
            config.splits = splits
        }
        let deleteAfterRemux = Option(name: "--delete-after-remux", requireValue: false, description: "delete the src after remux") { (_) in
            config.deleteAfterRemux = true
        }
        let keepTrackName = Option(name: "--keep-track-name", requireValue: false, description: "keep original track name") { (v) in
            config.keepTrackName = true
        }
        
        let help = Option(name: "--help", anotherName: "-H", requireValue: false, description: "show help") { (v) in
            config.help = true
        }
        
        let parser = ArgumentParser(usage: "Remuxer --mode \(RemuxerArgument.RemuxMode.allSelection) [OPTIONS] [INPUT]", options: [output, temp, mode, language, splits, deleteAfterRemux, keepTrackName, help, excludeLanguage]) { (v) in
            config.inputs.append(Path(url: URL(fileURLWithPath: v))!)
        }
        try parser.parse(arguments: CommandLine.arguments.dropFirst())
        config.temporaryPath = config.temporaryPath.join("tmp")
        while config.temporaryPath.exists {
            config.temporaryPath = config.temporaryPath.join("tmp")
        }
//        FFmpegLog.set(level: .quite)
        flacQueue.maxConcurrentCount = 4
        self.config = config
        Swift.dump(config)
        if config.help {
            parser.showHelp(to: &stderrOutputStream)
            exit(0)
        }
    }
    
    func beforeRun(p: Process) {
        p.terminationHandler = {self.processManager.remove(process: $0)}
    }
    
    func afterRun(p: Process) {
        processManager.add(process: p)
    }
    
    func recursiveRun(task: WorkTask) throws -> [Path] {
//        let tempOutput = task.main.output
        do {
            task.main.printTask()
            try task.main.runAndWait(checkNonZeroExitCode: true, beforeRun: beforeRun(p:), afterRun: afterRun(p:))
        } catch {
            if task.canBeIgnored {
                return []
            }
            if let splitWorkers = task.splitWorkers {
                for splitWorker in splitWorkers {
                    try splitWorker.runAndWait(checkNonZeroExitCode: true, beforeRun: beforeRun(p:), afterRun: afterRun(p:))
                }
                do {
                    let p = try task.joinWorker!.runAndWait(checkNonZeroExitCode: false, beforeRun: beforeRun(p:), afterRun: afterRun(p:))
                    if p.terminationStatus == 2 {
                        throw ExecutableError.nonZeroExitCode(2)
                    }
                    return [task.joinWorker!.outputPath]
                } catch {
                    print("Failed to join file, \(error)")
                    return splitWorkers.map {$0.outputPath}
                }
            } else {
                throw error
            }
        }
        
        if task.main.outputPath.exists {
            // output exists
            return [task.main.outputPath]
        } else if task.chapterSplit, let parts = try? task.main.outputPath.parent.ls().filter({$0.path.extension == task.main.outputPath.extension && $0.path.basename().hasPrefix(task.main.outputPath.basename(dropExtension: true))}) {
            return parts.map {$0.path}
        } else {
            print("Can't find output file(s).")
            throw RemuxerError.noOutputFile(task.main.outputPath)
        }
    }
    
    func run() {
        if config.inputs.isEmpty {
            print("No inputs!")
            return
        }
//        var failedTasks: [String] = []
        let fm = FileManager.default
        
        switch config.mode {
        case .dumpBDMV:
            config.inputs.forEach({ (bdmvPath) in
                let task = BDMVTask(rootPath: bdmvPath, mode: .direct, configuration: config)
                do {
                    try task.dumpInfo()
                } catch {
                    print("Error: \(error)")
                }
            })
        case .episodes, .movie:
            let mode: MplsRemuxMode
            if config.mode == .episodes {
                mode = .split
            } else {
                mode = .direct
            }
            config.inputs.forEach({ (bdmvPath) in
                do {
                    let task = BDMVTask(rootPath: bdmvPath, mode: mode, configuration: config)
                    let finalOutputPath = config.outputPath.join(task.getBlurayTitle())
                    if finalOutputPath.exists {
                        throw RemuxerError.outputExist
                    }
                    if config.temporaryPath.exists {
                        try config.temporaryPath.delete()
                    }
                    try config.temporaryPath.mkdir()
                    let converters = try task.parse()
                    var tempFiles = [Path]()
                    try converters.forEach({ (converter) in
                        tempFiles.append(contentsOf: try recursiveRun(task: converter))
                    })
                    
                    try tempFiles.forEach { (tempFile) in
                        let mkvinfo = try MkvmergeIdentification(filePath: tempFile.string)
                        let duration = Timestamp(ns: UInt64(mkvinfo.container.properties?.duration ?? 0))
                        let subFolder: String
                        if duration > Timestamp.hour {
                            // big
                            subFolder = ""
                        } else if duration > Timestamp.minute*10 {
                            // > 10 min
                            subFolder = "medium"
                        } else if duration > Timestamp.minute {
                            // > 1 min
                            subFolder = "small"
                        } else {
                            subFolder = "garbage"
                        }
                        try remux(file: tempFile,
                                  remuxOutputDir: finalOutputPath.join(subFolder),
                                  deleteAfterRemux: true, mkvinfo: mkvinfo)
                    }
                    if config.deleteAfterRemux {
                        try? bdmvPath.delete()
                    }
                    clear()
                } catch {
                    print("Remuxing \(bdmvPath) failed!!!")
                    print("error: \(error)")
                }
            })
        case .file:
            var failed: [Path] = []
            try? config.temporaryPath.mkdir()
            config.inputs.forEach({ (file) in
                var isDir: ObjCBool = false
                if file.exists {
                    if file.isDirectory {
                        // input is a directory, remux all contents
                        let outputDir = config.outputPath.join(file.basename())
                        try? outputDir.mkdir()
                        let contents = try! file.ls()
                        contents.forEach({ (fileInDir) in
                            do {
                                try remux(file: fileInDir.path, remuxOutputDir: outputDir, deleteAfterRemux: false)
                            } catch {
                                print(error)
                                failed.append(fileInDir.path)
                            }
                        })
                    } else {
                        do {
                            try remux(file: file, remuxOutputDir: config.outputPath, deleteAfterRemux: false)
                        } catch {
                            print(error)
                            failed.append(file)
                        }
                    }
                } else {
                    print("\(file) doesn't exist!")
                }
            })
            if failed.count > 0 {
                print("Muxing files failed:\n\(failed.map{$0.string}.joined(separator: "\n"))")
            }
        }
//        if failedTasks.count > 0 {
//            print("failed tasks:")
//            print(failedTasks.joined(separator: "\n"))
//        }
    }
    
    func clear() {
        processManager.terminateAll()
        flacQueue.terminateAllProcesses()
        try! config.temporaryPath.delete()
    }
    
}

extension Remuxer {
    
    func remux(file: Path, remuxOutputDir: Path, deleteAfterRemux: Bool,
               parseOnly: Bool = false, mkvinfo: MkvmergeIdentification? = nil) throws {
        let outputFilename = remuxOutputDir.join("\(file.basename(dropExtension: true)).mkv")
        guard outputFilename != file else {
            print("\(outputFilename) already exists!")
            return
        }
        var arguments = ["-q", "--output", outputFilename.string]
        var trackOrder = [String]()
        var audioRemoveTracks = [Int]()
        var subtitleRemoveTracks = [Int]()
        var externalTracks = [(file: Path, lang: String, trackName: String)]()
        
        let mkvinfo = try mkvinfo ?? MkvmergeIdentification.init(filePath: file.string)
        let modifications = try makeTrackModification(mkvinfo: mkvinfo)
        
        for modify in modifications.enumerated() {
            switch modify.element {
            case .copy(_):
                trackOrder.append("0:\(modify.offset)")
            case .remove(let type):
                switch type {
                case .audio:
                    audioRemoveTracks.append(modify.offset)
                case .subtitles:
                    subtitleRemoveTracks.append(modify.offset)
                default:
                    break
                }
            case .replace(let type, let file, let lang, let trackName):
                switch type {
                case .audio:
                    audioRemoveTracks.append(modify.offset)
                case .subtitles:
                    subtitleRemoveTracks.append(modify.offset)
                default:
                    break
                }
                externalTracks.append((file: file, lang: lang, trackName: trackName))
                trackOrder.append("\(externalTracks.count):0")
            }
            if !config.keepTrackName {
                arguments.append(contentsOf: ["--track-name", "\(modify.offset):"])
            }
        }

        if audioRemoveTracks.count > 0 {
            arguments.append(contentsOf: ["-a", "!\(audioRemoveTracks.map({$0.description}).joined(separator: ","))"])
        }
        
        if subtitleRemoveTracks.count > 0 {
            arguments.append(contentsOf: ["-s", "!\(subtitleRemoveTracks.map({$0.description}).joined(separator: ","))"])
        }
        
        arguments.append("--no-attachments")
        arguments.append(file.string)
        externalTracks.forEach { (track) in
            arguments.append(contentsOf: ["--language", "0:\(track.lang)"])
            if config.keepTrackName {
                arguments.append(contentsOf: ["--track-name", "0:\(track.trackName)"])
            }
            arguments.append(track.file.string)
        }
        arguments.append(contentsOf: ["--title", ""])
        if !trackOrder.isEmpty {
            arguments.append(contentsOf: ["--track-order", trackOrder.joined(separator: ",")])
        }
        
        print("Mkvmerge arguments:\n\(arguments.joined(separator: " "))")
        
        print("\nMkvmerge:\n\(file)\n->\n\(outputFilename)")
        try MediaTools.mkvmerge.executable(arguments: arguments).runAndWait(checkNonZeroExitCode: true, beforeRun: beforeRun(p:), afterRun: afterRun(p:))
        
        externalTracks.forEach { (t) in
            do {
                try t.file.delete()
            } catch {
                print("Can not delete file: \(t.file)")
            }
        }
        if deleteAfterRemux {
            do {
                try file.delete()
            } catch {
                print("Can not delete file: \(file)")
            }
        }
        
    }
    
}

// MARK: - Utilities
extension Remuxer {
    
    private func display(modiifcations: [TrackModification]) {
        print("Track modifications: ")
        for m in modiifcations.enumerated() {
            print("\(m.offset): \(m.element)")
        }
    }
    
    private func makeTrackModification(mkvinfo: MkvmergeIdentification) throws -> [TrackModification] {
//        let context = try FFmpegInputFormatContext.init(url: mkvinfo.fileName)
//        try context.findStreamInfo()
//        guard context.streamCount == mkvinfo.tracks.count else {
//            print("ffmpeg and mkvmerge track count mismatch!")
//            throw RemuxerError.errorReadingFile
//        }
        
        let preferedLanguages = config.generatePrimaryLanguages(with: mkvinfo.primaryLanguages)
//        let streams = context.streams
        let tracks = mkvinfo.tracks
        var flacConverters = [FlacConverter]()
        var ffmpegArguments = ["-v", "quiet", "-nostdin", "-y", "-i", mkvinfo.fileName, "-vn"]
        var trackModifications = [TrackModification].init(repeating: .copy(type: .video), count: tracks.count)
        
        defer {
            display(modiifcations: trackModifications)
        }
        
        // check track one by one
        print("Checking tracks codec")
        var index = 0
        let baseFilename = Path(mkvinfo.fileName)!.basename(dropExtension: true)
        while index < tracks.count {
            let track = tracks[index]
            let trackLanguage = track.properties.language ?? "und"
            print("\(index): \(track.codec) \(track.isLosslessAudio ? "lossless" : "lossy") \(trackLanguage) \(track.properties.audioChannels ?? 0)ch")
            if track.isLosslessAudio, preferedLanguages.contains(trackLanguage) {
                // add to ffmpeg arguments
                let tempFlac = config.temporaryPath.join("\(baseFilename)-\(index)-\(trackLanguage)-ffmpeg.flac")
                let finalFlac = config.temporaryPath.join("\(baseFilename)-\(index)-\(trackLanguage).flac")
                ffmpegArguments.append(contentsOf: ["-map", "0:\(index)", tempFlac.string])
                var flac = FlacConverter(input: tempFlac.string, output: finalFlac.string)
                flac.level = 8
                flac.forceOverwrite = true
                flac.silent = true
                flacConverters.append(flac)
                
                trackModifications[index] = .replace(type: .audio, file: finalFlac, lang: trackLanguage, trackName: track.properties.trackName ?? "")
            } else if preferedLanguages.contains(trackLanguage) {
                trackModifications[index] = .copy(type: track.type)
            } else {
                trackModifications[index] = .remove(type: track.type)
            }
            if track.isTruehd, index+1<tracks.count,
                case let nextTrack = tracks[index+1],
                nextTrack.isAC3 {
                // Remove TRUEHD embed-in AC-3 track
                trackModifications[index+1] = .remove(type: .audio)
                index += 1
            }
            index += 1
        }
        
        guard flacConverters.count > 0 else {
            return trackModifications
        }
        
        print("ffmpeg \(ffmpegArguments.joined(separator: " "))")

        try MediaTools.ffmpeg.executable(arguments: ffmpegArguments).runAndWait(checkNonZeroExitCode: true, beforeRun: beforeRun(p:), afterRun: afterRun(p:))
        
        flacConverters.forEach { (flac) in
            let process = try! flac.convert()
            process.terminationHandler = { p in
                if p.terminationStatus != 0 {
                    print("error while converting flac \(flac.input)")
                }
                try! flac.inputPaths.delete()
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
                    case .replace(type: _, file: let file, lang: _, trackName: _):
                        if filesWithSameMD5.contains(file.string) {
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
    
    case copy(type: TrackType)
    case replace(type: TrackType, file: Path, lang: String, trackName: String)
    case remove(type: TrackType)
    
    mutating func remove() {
        switch self {
        case .replace(type: let type, file: let file, lang: _, trackName: _):
            try? file.delete()
            self = .remove(type: type)
        case .copy(type: let type):
            self = .remove(type: type)
        case .remove(type: _):
            return
        }
        
    }
    
    var type: TrackType {
        switch self {
        case .replace(type: let type, file: _, lang: _, trackName: _):
            return type
        case .copy(type: let type):
            return type
        case .remove(type: let type):
            return type
        }
    }
    
}

struct TaskSummary {
    let sizeBefore: UInt64
    let sizeAfter: UInt64
    let startDate: Date
    let endDate: Date
}

//struct SubTask {
//    var sizeBefore: UInt64
//    var sizeAfter: UInt64
//    var startDate: Date
//    var endDate: Date
//    let converter: Converter
//    let split: Bool
//}

struct BDMVTask {
    let rootPath: Path
    let mode: MplsRemuxMode
    let configuration: RemuxerArgument
    
    func parse() throws -> [WorkTask] {
        
        let mplsList = try scan(removeDuplicate: true)

        // TODO: check conflict
        
        var tasks = [WorkTask]()
        
        if mode == .split {
            var allFiles = Set(mplsList.flatMap {$0.files})
            try mplsList.forEach { (mpls) in
                tasks.append(contentsOf: try split(mpls: mpls, restFiles: allFiles))
                mpls.files.forEach({ (usedFile) in
                    allFiles.remove(usedFile)
                })
            }
        } else if mode == .direct {
            try mplsList.forEach { (mpls) in
                if mpls.useFFmpeg || mpls.compressed/* || mpls.remuxMode == .split*/ {
                    tasks.append(contentsOf: try split(mpls: mpls))
                } else {
                    let preferedLanguages = configuration.generatePrimaryLanguages(with: [mpls.primaryLanguage])
                    let outputFilename = generateFilename(mpls: mpls)
                    let output = configuration.temporaryPath.join(outputFilename + ".mkv")
                    let parsedMpls = try mplsParse(path: mpls.fileName.string)
                    let chapter = parsedMpls.convert()
                    let chapterFile = configuration.temporaryPath.join("\(mpls.fileName.basename(dropExtension: true)).txt")
                    let chapterPath: String?
                    if chapter.isValid {
                        try chapter.exportOgm().write(toFile: chapterFile.string, atomically: true, encoding: .utf8)
                        chapterPath = chapterFile.string
                    } else {
                        chapterPath = nil
                    }
                    
                    if configuration.splits != nil {
                        tasks.append(.init(input: mpls.fileName, main: MkvmergeMuxer.init(input: [mpls.fileName.string], output: output.string, audioLanguages: preferedLanguages, subtitleLanguages: preferedLanguages, chapterPath: chapterPath, extraArguments: generateSplitArguments(mpls: mpls)), chapterSplit: true, canBeIgnored: false))
                    } else {
                        let splitWorkers = try split(mpls: mpls).map {$0.main}
                        tasks.append(
                            .init(input: mpls.fileName,
                                  main: MkvmergeMuxer(input: mpls.files.map{$0.string}, output: output.string, audioLanguages: preferedLanguages, subtitleLanguages: preferedLanguages, chapterPath: chapterPath),
                                  chapterSplit: false, splitWorkers: splitWorkers,
                                  joinWorker: MkvmergeMuxer(input: splitWorkers.map{$0.outputPath.string}, output: output.string, audioLanguages: preferedLanguages, subtitleLanguages: preferedLanguages, chapterPath: chapterPath, cleanInputChapter: true)))
                    }
                }
            }
        }
        
        return tasks
        

    }
    
    func dumpInfo() throws {
        print("Blu-ray title: \(getBlurayTitle())")
        let mplsList = try scan(removeDuplicate: true)
        print("MPLS List:\n")
        mplsList.forEach {print($0);print()}
    }
    
    func getBlurayTitle() -> String {
        var title: String = rootPath.basename()
        title = title.safeFilename().trimmingCharacters(in: .whitespacesAndNewlines)
        return title
    }
    
    func scan(removeDuplicate: Bool) throws -> [Mpls] {
        print("Start scanning BD folder: \(rootPath)")
        let playlistPath = rootPath.join("BDMV/PLAYLIST")

        if playlistPath.exists {
            let mplsPaths = try playlistPath.ls().map{$0.path}.filter {$0.extension.lowercased() == "mpls"}
            if mplsPaths.isEmpty {
                throw RemuxerError.noPlaylists
            }
            let allMpls = mplsPaths.compactMap { (mplsPath) -> Mpls? in
                do {
                    return try .init(filePath: mplsPath.string)
                } catch {
                    print("Invalid file: \(mplsPath), error: \(error)")
                    return nil
                }
            }
            if removeDuplicate {
                let multipleFileMpls = allMpls.filter{ !$0.isSingle }.duplicateRemoved
                let singleFileMpls = allMpls.filter{ $0.isSingle }.duplicateRemoved
//                var cleanMultipleFileMpls = [Mpls]()
                
//                for multipleMpls in multipleFileMpls {
//                    if multipleMpls.files.filter({ (file) -> Bool in
//                        return !singleFileMpls.contains(where: { (mpls) -> Bool in
//                            return mpls.files[0] == file
//                        })
//                    }).count > 0 {
//                        cleanMultipleFileMpls.append(multipleMpls)
//                    }
//                }
//                return (cleanMultipleFileMpls + singleFileMpls).sorted()
                
                var cleanSingleFileMpls = singleFileMpls
                for multipleMpls in multipleFileMpls {
                    if multipleMpls.files.allSatisfy({ file in
                        return cleanSingleFileMpls.contains(where: { (mpls) -> Bool in
                            return mpls.files[0] == file
                        })
                    }) {
                        cleanSingleFileMpls.removeAll(where: {multipleMpls.files.contains($0.files[0])})
                    }
                }
                return (multipleFileMpls + cleanSingleFileMpls).sorted()
            } else {
                return allMpls
            }
        } else {
            print("No PLAYLIST Folder!")
            throw RemuxerError.noPlaylists
        }
    }
    
    func split(mpls: Mpls) throws -> [WorkTask] {
        return try split(mpls: mpls, restFiles: Set(mpls.files))
    }
    
    func split(mpls: Mpls, restFiles: Set<Path>) throws -> [WorkTask] {
        
        print("Splitting MPLS: \(mpls.fileName)")
        
        if restFiles.count == 0 {
            return []
        }
        
        let clips = mpls.split(chapterPath: configuration.temporaryPath)
        let preferedLanguages = configuration.generatePrimaryLanguages(with: [mpls.primaryLanguage])
        
        return clips.flatMap { (clip) -> [WorkTask] in
            if restFiles.contains(clip.m2tsPath) {
                let output: Path
                let outputBasename = "\(mpls.fileName.filenameWithoutExtension)-\(clip.baseFilename)"
                if mpls.useFFmpeg {
                    return [
                        .init(input: clip.fileName,
                              main: FFmpegMuxer(input: clip.m2tsPath.string,
                                                    output: configuration.temporaryPath.join("\(outputBasename)-ffmpeg-video.mkv").string,
                                                    mode: .videoOnly), chapterSplit: false, canBeIgnored: true),
                        .init(input: clip.fileName,
                              main: FFmpegMuxer(input: clip.m2tsPath.string,
                                                output: configuration.temporaryPath.join("\(outputBasename)-ffmpeg-audio.mkv").string, mode: .audioOnly), chapterSplit: false, canBeIgnored: true)
                    ]
                } else {
                    let outputFilename = "\(outputBasename).mkv"
                    output = configuration.temporaryPath.join(outputFilename)
                    return [.init(input: clip.fileName, main: MkvmergeMuxer.init(input: [clip.m2tsPath.string], output: output.string, audioLanguages: preferedLanguages, subtitleLanguages: preferedLanguages, chapterPath: clip.chapterPath), chapterSplit: false, canBeIgnored: false)]
                }
                
            } else {
                print("Skipping clip: \(clip)")
                return []
            }
            
        }
    }
    
    private func generateFilename(mpls: Mpls) -> String {
        return "\(mpls.fileName.basename(dropExtension: true))-\(mpls.files.map{$0.basename(dropExtension: true)}.joined(separator: "+").prefix(200))"
    }
    
    private func generateSplitArguments(mpls: Mpls) -> [String] {
        guard let splits = configuration.splits, splits.count > 0 else {
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
}

extension RemuxerArgument {
    
    internal func generatePrimaryLanguages(with otherLanguages: [String]) -> Set<String> {
        var preferedLanguages = languages
        otherLanguages.forEach { (l) in
            preferedLanguages.insert(l)
        }
        excludeLanguages.forEach { (l) in
            preferedLanguages.remove(l)
        }
        return preferedLanguages
    }
    
}

//struct SubTask {
//    let main: Converter
//    let alternatives: [SubTask]?
////    let size: Int
//}

struct WorkTask {
    let input: Path
    let main: Converter
    let chapterSplit: Bool
    let splitWorkers: [Converter]?
    let joinWorker: Converter?
    let canBeIgnored: Bool
//    let inputSize: Int
    
    public init(input: Path, main: Converter, chapterSplit: Bool, canBeIgnored: Bool) {
        self.input = input
        self.main = main
        self.chapterSplit = chapterSplit
        self.splitWorkers = nil
        self.joinWorker = nil
        self.canBeIgnored = canBeIgnored
    }
    
    public init(input: Path, main: Converter, chapterSplit: Bool, splitWorkers: [Converter], joinWorker: Converter) {
        self.input = input
        self.main = main
        self.chapterSplit = chapterSplit
        self.splitWorkers = splitWorkers
        self.joinWorker = joinWorker
        self.canBeIgnored = false
    }
}
