//
//  Remuxer.swift
//  Remuxer
//
//  Created by Kojirou on 2018/9/17.
//

import Foundation
import Common
import MplsReader
import ArgumentParser
import SwiftFFmpeg

public enum RemuxerError: Error {
    case errorReadingFile
    case noPlaylists
    case sameFilename
    case outputExist
    case noOutputFile(String)
}

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
    
    var inputs: [String]
    
    var languages: Set<String>
    
    static let defaultLanguages: Set<String> = ["und", "chi", "eng", "jpn"]
    
    var deleteAfterRemux: Bool
    
    var useLibbluray: Bool
    
    var help: Bool
}

public class Remuxer {
    
    let config: RemuxerArgument
    
    let flacQueue = ParallelProcessQueue.init()
    
    let processManager = SubProcessManager()
    
    init() throws {
        var config = RemuxerArgument.init(outputDir: ".", tempDir: ".", mode: .movie, splits: nil, inputs: [], languages: RemuxerArgument.defaultLanguages, deleteAfterRemux: false, useLibbluray: false, help: false)
        let output = Option(name: "--output", anotherName: "-o", requireValue: true, description: "output dir") { (v) in
            config.outputDir = v
        }
        
        let temp = Option(name: "--temp", anotherName: "-t", requireValue: true, description: "temp dir") { (v) in
            config.tempDir = v
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
        let useLibbluray = Option(name: "--use-libbluray", requireValue: false, description: "delete the src after remux") { (v) in
            config.useLibbluray = true
        }
        
        let help = Option(name: "--help", anotherName: "-H", requireValue: false, description: "show help") { (v) in
            config.help = true
        }
        
        let parser = ArgumentParser(usage: "Remuxer --mode \(RemuxerArgument.RemuxMode.allSelection) [OPTIONS] [INPUT]", options: [output, temp, mode, language, splits, deleteAfterRemux, useLibbluray, help]) { (v) in
            config.inputs.append(v)
        }
        try parser.parse(arguments: CommandLine.arguments.dropFirst())
        config.tempDir = config.tempDir.appendingPathComponent("tmp")
        FFmpegLog.set(level: .quite)
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
    
    func recursiveRun(converter: Converter, outputs: inout [String]) throws {
        do {
            converter.printTask()
            try converter.runAndWait(checkNonZeroExitCode: true, beforeRun: beforeRun(p:), afterRun: afterRun(p:))
            if FileManager.default.fileExists(atPath: converter.output) {
                // output exists
                outputs.append(converter.output)
            } else if let parts = try? FileManager.default.contentsOfDirectory(atPath: converter.output.deletingLastPathComponent).filter({$0.hasSuffix(".\(converter.output.pathExtension)") && $0.hasPrefix(converter.output.lastPathComponent.deletingPathExtension)}) {
                outputs.append(contentsOf: parts)
            } else {
                print("Can't find output file(s).")
                throw RemuxerError.noOutputFile(converter.output)
            }
        } catch {
            if let alter = converter.alternative {
                print("Failed: \(error), using alternative converters.")
                try alter.forEach({ (c) in
                    try recursiveRun(converter: c, outputs: &outputs)
                })
            } else {
                throw error
            }
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
                    let finalOutputPath = config.outputDir.appendingPathComponent(task.getBlurayTitle())
                    if FileManager.default.fileExists(atPath: finalOutputPath) {
                        throw RemuxerError.outputExist
                    }
                    if fm.fileExists(atPath: config.tempDir) {
                        try fm.removeItem(atPath: config.tempDir)
                    }
                    try fm.createDirectory(atPath: config.tempDir, withIntermediateDirectories: true, attributes: nil)
                    let converters = try task.parse()
                    var tempFiles = [String]()
                    try converters.forEach({ (converter) in
                        try recursiveRun(converter: converter, outputs: &tempFiles)
                    })
                    if config.deleteAfterRemux {
                        try? fm.removeItem(atPath: bdmvPath)
                    }
                    try tempFiles.forEach { (tempFile) in
                        let mkvinfo = try MkvmergeIdentification(filePath: tempFile)
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
                                  remuxOutputDir: finalOutputPath.appendingPathComponent(subFolder),
                                  deleteAfterRemux: true, mkvinfo: mkvinfo)
                    }
                    clear()
                } catch {
                    print("Remuxing \(bdmvPath) failed!!!")
                    print("error: \(error)")
                }
            })
        case .file:
            var failed: [String] = []
            try? FileManager.default.createDirectory(atPath: config.tempDir, withIntermediateDirectories: true, attributes: nil)
            config.inputs.forEach({ (file) in
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: file, isDirectory: &isDir) {
                    if isDir.boolValue {
                        // input is a directory, remux all contents
                        let outputDir = config.outputDir.appendingPathComponent(file.filename)
                        try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true, attributes: nil)
                        let contents = try! FileManager.default.contentsOfDirectory(atPath: file)
                        contents.forEach({ (fileInDir) in
                            do {
                                try remux(file: fileInDir, remuxOutputDir: outputDir, deleteAfterRemux: false)
                            } catch {
                                print(error)
                                failed.append(fileInDir)
                            }
                        })
                    } else {
                        do {
                            try remux(file: file, remuxOutputDir: config.outputDir, deleteAfterRemux: false)
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
                print("Muxing files failed:\n\(failed.joined(separator: "\n"))")
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
        try! FileManager.default.removeItem(atPath: config.tempDir)
    }
    
}

extension Remuxer {
    
    func remux(file: String, remuxOutputDir: String, deleteAfterRemux: Bool,
               parseOnly: Bool = false, mkvinfo: MkvmergeIdentification? = nil) throws {
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
        
        let mkvinfo = try mkvinfo ?? MkvmergeIdentification.init(filePath: file)
        let modifications = try makeTrackModification(mkvinfo: mkvinfo)
        
        for modify in modifications.enumerated() {
            switch modify.element {
            case .copy(_):
                trackOrder.append("0:\(modify.offset)")
            case .remove(let type):
                switch type {
                case .audio:
                    audioRemoveTracks.append(modify.offset)
                case .subtitle:
                    subtitleRemoveTracks.append(modify.offset)
                default:
                    break
                }
            case .replace(let type, let file, let lang):
                switch type {
                case .audio:
                    audioRemoveTracks.append(modify.offset)
                case .subtitle:
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
        
        print("\nMkvmerge:\n\(file)\n->\n\(outputFilename)")
        try MKVmerge(arguments: arguments).runAndWait(checkNonZeroExitCode: true, beforeRun: beforeRun(p:), afterRun: afterRun(p:))
        
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

// MARK: - Utilities
extension Remuxer {
    
    private func display(modiifcations: [TrackModification]) {
        print("Track modifications: ")
        for m in modiifcations.enumerated() {
            print("\(m.offset): \(m.element)")
        }
    }
    
    private func makeTrackModification(mkvinfo: MkvmergeIdentification) throws -> [TrackModification] {
        let context = try FFmpegInputFormatContext.init(url: mkvinfo.fileName)
        try context.findStreamInfo()
        guard context.streamCount == mkvinfo.tracks.count else {
            print("ffmpeg and mkvmerge track count mismatch!")
            throw RemuxerError.errorReadingFile
        }
        
        let preferedLanguages = config.generatePrimaryLanguages(with: [mkvinfo.primaryLanguage])
        let streams = context.streams
        var flacConverters = [Flac]()
        var ffmpegArguments = ["-v", "quiet", "-nostdin", "-y", "-i", mkvinfo.fileName, "-vn"]
        var trackModifications = [TrackModification].init(repeating: .copy(type: .unknown), count: streams.count)
        
        defer {
            display(modiifcations: trackModifications)
        }
        
        // check track one by one
        print("Checking tracks codec")
        var index = 0
        while index < streams.count {
            let stream = streams[index]
            let streamLanguage = mkvinfo.tracks[index].properties.language ?? "und"
            print("\(stream.index): \(stream.codecParameters.codecId.name) \(stream.isLosslessAudio ? "lossless" : "lossy") \(streamLanguage) \(stream.codecParameters.channelCount)ch")
            if stream.isLosslessAudio, preferedLanguages.contains(streamLanguage) {
                // add to ffmpeg arguments
                let tempFlac = config.tempDir.appendingPathComponent("\(mkvinfo.fileName.filenameWithoutExtension)-\(stream.index)-\(streamLanguage)-ffmpeg.flac")
                let finalFlac = config.tempDir.appendingPathComponent("\(mkvinfo.fileName.filenameWithoutExtension)-\(stream.index)-\(streamLanguage).flac")
                ffmpegArguments.append(contentsOf: ["-map", "0:\(stream.index)", tempFlac])
                flacConverters.append(Flac.init(input: tempFlac, output: finalFlac))
                
                trackModifications[index] = .replace(type: .audio, file: finalFlac, lang: streamLanguage)
            } else if preferedLanguages.contains(streamLanguage) {
                trackModifications[index] = .copy(type: stream.mediaType)
            } else {
                trackModifications[index] = .remove(type: stream.mediaType)
            }
            if stream.isTruehd, index+1<streams.count,
                case let nextStream = streams[index+1],
                nextStream.isAC3 {
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

        try FFmpeg(arguments: ffmpegArguments).runAndWait(checkNonZeroExitCode: true, beforeRun: beforeRun(p:), afterRun: afterRun(p:))
        
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
    
    case copy(type: FFmpegMediaType)
    case replace(type: FFmpegMediaType, file: String, lang: String)
    case remove(type: FFmpegMediaType)
    
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
    
    var type: FFmpegMediaType {
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




import CLibbluray

struct TaskSummary {
    let sizeBefore: UInt64
    let sizeAfter: UInt64
    let startDate: Date
    let endDate: Date
}

struct SubTask {
    var sizeBefore: UInt64
    var sizeAfter: UInt64
    var startDate: Date
    var endDate: Date
    let converter: Converter
    let split: Bool
}

struct BDMVTask {
    let rootPath: String
    let mode: MplsRemuxMode
    let configuration: RemuxerArgument
    
    func parse() throws -> [Converter] {
        
        let mplsList = try scan(removeDuplicate: true)

        // TODO: check conflict
        
        var converters = [Converter]()
        
        if mode == .split {
            var allFiles = Set(mplsList.flatMap {$0.files})
            try mplsList.forEach { (mpls) in
                converters.append(contentsOf: try split(mpls: mpls, restFiles: allFiles))
                mpls.files.forEach({ (usedFile) in
                    allFiles.remove(usedFile)
                })
            }
        } else if mode == .direct {
            try mplsList.forEach { (mpls) in
                if mpls.useFFmpeg || mpls.compressed/* || mpls.remuxMode == .split*/ {
                    converters.append(contentsOf: try split(mpls: mpls))
                } else {
                    let preferedLanguages = configuration.generatePrimaryLanguages(with: [mpls.primaryLanguage])
                    let outputFilename = generateFilename(mpls: mpls)
                    let output = configuration.tempDir.appendingPathComponent(outputFilename + ".mkv")
                    
                    if configuration.splits != nil {
                        let m = MkvmergeMuxer.init(input: mpls.fileName, output: output, audioLanguages: preferedLanguages, subtitleLanguages: preferedLanguages, extraArguments: generateSplitArguments(mpls: mpls))
                        
//                        let outputs = try FileManager.default.contentsOfDirectory(atPath: config.tempDir).filter({$0.hasPrefix(outputFilename)}).map({config.tempDir.appendingPathComponent($0)})
//                        tempFiles.append(contentsOf: outputs)
                        converters.append(m)
                    } else {
                        var m = MkvmergeMuxer(input: mpls.fileName, output: output, audioLanguages: preferedLanguages, subtitleLanguages: preferedLanguages)
                        m.alternative = try split(mpls: mpls)
                        converters.append(m)
                    }
                }
            }
        }
        
        return converters
        

    }
    
    func dumpInfo() throws {
        print("Blu-ray title: \(getBlurayTitle())")
        let mplsList = try scan(removeDuplicate: true)
        print("MPLS List:\n")
        mplsList.forEach {print($0);print()}
    }
    
    func getBlurayTitle() -> String {
        var title: String = rootPath.lastPathComponent
        if configuration.useLibbluray,
            let bd = bd_open(rootPath, nil),
            bd_set_player_setting_str(bd, BLURAY_PLAYER_SETTING_MENU_LANG.rawValue, "jpn") == 1,
            let meta = bd_get_meta(bd),
            let name = meta.pointee.di_name {
                let discName = String.init(cString: name)
                if !discName.isEmpty, discName.prefix(3).lowercased() == title.prefix(3).lowercased() {
                    title = discName
                }
            bd_close(bd)
        }

        title = title.safeFilename().trimmingCharacters(in: .whitespacesAndNewlines)
        return title

    }
    
    func scan(removeDuplicate: Bool) throws -> [Mpls] {
        print("Start scanning BD folder: \(rootPath)")
        let fm = FileManager.default
        let playlistPath = rootPath.appendingPathComponent("BDMV/PLAYLIST")

        if fm.fileExists(atPath: playlistPath) {
            let mplsPaths = try fm.contentsOfDirectory(atPath: playlistPath)
                .filter {$0.hasSuffix(".mpls")}
            if mplsPaths.isEmpty {
                throw RemuxerError.noPlaylists
            }
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
    
    func split(mpls: Mpls) throws -> [Converter] {
        return try split(mpls: mpls, restFiles: Set(mpls.files))
    }
    
    func split(mpls: Mpls, restFiles: Set<String>) throws -> [Converter] {
        
        print("Splitting MPLS: \(mpls.fileName)")
        
        if restFiles.count == 0 {
            return []
        }
        
        let clips = mpls.split(chapterPath: configuration.tempDir)
        let preferedLanguages = configuration.generatePrimaryLanguages(with: [mpls.primaryLanguage])
        
        return clips.compactMap { (clip) -> Converter? in
            if restFiles.contains(clip.m2tsPath) {
                let output: String
                let outputBasename = "\(mpls.fileName.filenameWithoutExtension)-\(clip.baseFilename)"
                if mpls.useFFmpeg {
                    let outputFilename = "\(outputBasename)-ffmpeg.mkv"
                    output = configuration.tempDir.appendingPathComponent(outputFilename)
                    var ff = FFmpegMuxer.init(input: clip.m2tsPath, output: output, mode: .videoOnly)
                    ff.alternative = [FFmpegMuxer(input: clip.m2tsPath, output: output, mode: .audioOnly)]
                    return ff
                } else {
                    let outputFilename = "\(outputBasename).mkv"
                    output = configuration.tempDir.appendingPathComponent(outputFilename)
                    let m = MkvmergeMuxer.init(input: clip.m2tsPath, output: output, audioLanguages: preferedLanguages, subtitleLanguages: preferedLanguages, chapterPath: clip.chapterPath)
                    return m
                }
                
            } else {
                print("Skipping clip: \(clip)")
                return nil
            }
            
        }
    }
    
    private func generateFilename(mpls: Mpls) -> String {
        return "\(mpls.fileName.filenameWithoutExtension)-\(mpls.files.map{$0.filenameWithoutExtension}.joined(separator: "+").prefix(50))"
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
        return preferedLanguages
    }
    
}
