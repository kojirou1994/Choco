//
//  Remuxer.swift
//  Remuxer
//
//  Created by Kojirou on 2018/9/17.
//

import Foundation
import Common
import Utility

struct DefaultConfig {
    
    static let tempDir = ""
    
    static let outputDir = ""
    
    static let preferedLanguages: Set<String> = ["und", "chi", "eng", "jpn"]
    
}

struct Config {
    var outputDir: String
    var tempDir: String
    var mode: RemuxMode
    /// use in splitMpls mode
    var splits: [Int]?
    var inputs: [String]
    var languages: Set<String>
}


enum RemuxMode: String, CaseIterable {
    // auto detect
    case auto
    // direct mux all mpls
    case movie
    // split all mpls
    case episodes
    // print mpls list
    case dump
    // input is *.mkv or something else
    case file
    // input is *.mpls
    case splitMpls
}

public class Remuxer {
    
    let mode: RemuxMode
    
    let tempDir: String
    
    let outputDir: String
    
    let splits: [Int]?
    
    let languages: Set<String>
    
    let inputs: [String]
    
    public init(arguments: [String]) throws {
        let parser = ArgumentParser.init(commandName: "Remuxer", usage: "", overview: "", seeAlso: nil)
        let binder = ArgumentBinder<Config>.init()
        
        binder.bind(option: parser.add(option: "--output", shortName: "-o", kind: String.self, usage: "output dir")) { (config, output) in
            config.outputDir = output
        }
        binder.bind(option: parser.add(option: "--temp", shortName: "-t", kind: String.self, usage: "temp dir")) { (config, temp) in
            config.tempDir = temp
        }
        binder.bind(option: parser.add(option: "--mode", kind: String.self, usage: "remux mode")) { (config, mode) in
            guard let modeV = RemuxMode.init(rawValue: mode) else {
                fatalError("Unknown mode: \(mode)")
            }
            config.mode = modeV
        }
        binder.bind(option: parser.add(option: "--splits", kind: String.self, usage: "split  info")) { (config, splits) in
            let v = splits.split(separator: ",").map({ (str) -> Int in
                if let int = Int(str) {
                    return int
                } else {
                    fatalError("Invalid splits: \(splits)")
                }
            })
            config.splits = v
        }
        binder.bindArray(positional: parser.add(positional: "inputs", kind: [String].self, usage: "input's path")) { (config, inputs) in
            config.inputs = inputs
        }
        
        let result = try parser.parse(Array(CommandLine.arguments.dropFirst()))
        var config = Config.init(outputDir: DefaultConfig.outputDir, tempDir: DefaultConfig.tempDir, mode: .auto, splits: nil, inputs: [], languages: DefaultConfig.preferedLanguages)
        try binder.fill(parseResult: result, into: &config)
        
        av_log_set_level(AV_LOG_QUIET)
        mode = config.mode
        tempDir = config.tempDir.appendingPathComponent("tmp")
        outputDir = config.outputDir
        splits = config.splits
        languages = config.languages
        inputs = config.inputs
        try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true, attributes: nil)
    }
    
    public func start() throws {
        switch mode {
        case .auto, .episodes, .movie, .dump:
            try inputs.forEach({ (input) in
                try remux(blurayPath: input, useMode: mode)
            })
        case .file:
            var failed: [String] = []
            try inputs.forEach({ (file) in
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: file, isDirectory: &isDir) {
                    if isDir.boolValue {
                        let outputDir = self.outputDir.appendingPathComponent(file.filename)
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
                            try remux(file: file, remuxOutputDir: outputDir, deleteAfterRemux: false)
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
        case .splitMpls:
            fatalError("split mode")
        }
    }
    
    func dump(blurayPath: String) throws {
        try remux(blurayPath: blurayPath, useMode: .dump)
    }

    func remux(blurayPath: String, useMode: RemuxMode) throws {
        
        let bdFolderName = blurayPath.filename
        let finalOutputDir = DefaultConfig.outputDir.appendingPathComponent(bdFolderName)
        
        print("Remuxing BD: \(bdFolderName)")
        
        let mplsList = try scan(blurayPath: blurayPath, removeDuplicate: true)
        
        if mplsList.count > 0 {
            print("MPLS List:\n")
            mplsList.forEach {print($0);print()}
        } else {
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
                if mpls.useFFmpeg || mpls.updated {
                    tempFiles.append(contentsOf: try split(mpls: mpls))
                } else {
                    let preferedLanguages = generatePrimaryLanguages(with: [mpls.primaryLanguage])
                    let output = tempDir.appendingPathComponent(generateFilename(mpls: mpls) + ".mkv")
                    
                    let m = MkvmergeMuxer.init(input: mpls.fileName, output: output, audioLanguages: preferedLanguages, subtitleLanguages: preferedLanguages)
                    try m.convert()
                    tempFiles.append(output)
                }
            }
        } else if useMode == .auto {
            fatalError("Auto mode not finished")
        }
        
        try tempFiles.forEach { (tempFile) in
            try remux(file: tempFile, remuxOutputDir: finalOutputDir, deleteAfterRemux: true)
        }
    }
    
    func remux(file: String, remuxOutputDir: String, deleteAfterRemux: Bool) throws {
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
        let modifications = try parse(mkvinfo: mkvinfo)
        
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
        let mkvmerge = try Process.init(executableName: "mkvmerge", arguments: arguments)
        print("\nMkvmerge:\n\(file)\n->\n\(outputFilename)")
        mkvmerge.launchUntilExit()
        try mkvmerge.checkTerminationStatus()
        
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
        
        let clips = mpls.split()
        let preferedLanguages = generatePrimaryLanguages(with: [mpls.primaryLanguage])
        
        return try clips.compactMap { (clip) -> String? in
            if restFiles.contains(clip.m2tsPath) {
                let output: String
                if mpls.useFFmpeg {
                    let outputFilename = "\(mpls.fileName.filenameWithoutExtension)-\(clip.m2tsPath.filenameWithoutExtension)-ffmpeg.mkv"
                    output = tempDir.appendingPathComponent(outputFilename)
                    let ff = FFmpegMuxer.init(input: clip.m2tsPath, output: output)
                    try ff.convert(mode: .videoOnly)
                } else {
                    let outputFilename = "\(mpls.fileName.filenameWithoutExtension)-\(clip.m2tsPath.filenameWithoutExtension).mkv"
                    output = tempDir.appendingPathComponent(outputFilename)
                    let m = MkvmergeMuxer.init(input: clip.m2tsPath, output: output, audioLanguages: preferedLanguages, subtitleLanguages: preferedLanguages, chapterPath: clip.chapterPath)
                    try m.convert()
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
                .map {playlistPath.appendingPathComponent($0)}
            let allMpls = mplsPaths.compactMap({ (path) -> MkvmergeIdentification? in
                do {
                    let id = try MkvmergeIdentification.init(filePath: path)
                    return id
                } catch {
                    print("Invalid file: \(path)")
                    return nil
                }
            }).map(Mpls.init)
            if removeDuplicate {
                let multipleFileMpls = allMpls.filter{ !$0.isSingle }.duplicateMplsRemoved
                let singleFileMpls = allMpls.filter{ $0.isSingle }.duplicateMplsRemoved
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
        var preferedLanguages = DefaultConfig.preferedLanguages
        otherLanguages.forEach { (l) in
            preferedLanguages.insert(l)
        }
        return preferedLanguages
    }
    
    private func generateFilename(mpls: Mpls) -> String {
        return "\(mpls.fileName.filenameWithoutExtension)-\(mpls.files.map{$0.filenameWithoutExtension}.joined(separator: "+"))"
    }
    
    private func generateFilename(clip: MplsClip) -> String {
        return "\(clip.fileName.filenameWithoutExtension)-\(clip.m2tsPath.filenameWithoutExtension)"
    }
    
    private func generateSplitArguments(mpls: Mpls) -> [String] {
        guard let splits = splits, splits.count > 0 else {
            return []
        }
        let totalChaps = splits.reduce(0, +)
        if totalChaps <= mpls.chapterCount {
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
    
    private func parse(mkvinfo: MkvmergeIdentification) throws -> [TrackModification] {
        let context = try AVFormatContext.init(url: mkvinfo.fileName)
        try context.findStreamInfo()
        guard context.streamCount == mkvinfo.tracks.count else {
            print("ffmpeg and mkvmerge track count mismatch!")
            throw RemuxerError.t
        }
        
        let preferedLanguages = generatePrimaryLanguages(with: [mkvinfo.primaryLanguage])
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
            print("\(stream.index): \(stream.codecpar.codecId.name) \(stream.isLosslessAudio ? "lossless" : "lossy") \(stream.language)")
            if stream.isGrossAudio, preferedLanguages.contains(stream.language) {
                // add to ffmpeg arguments
                let tempFlac = tempDir.appendingPathComponent("/\(mkvinfo.fileName.filenameWithoutExtension)-\(stream.index)-\(stream.language)-ffmpeg.flac")
                let finalFlac = tempDir.appendingPathComponent("\(mkvinfo.fileName.filenameWithoutExtension)-\(stream.index)-\(stream.language).flac")
                ffmpegArguments.append(contentsOf: ["-map", "0:\(stream.index)", tempFlac])
                flacConverters.append(Flac.init(input: tempFlac, output: finalFlac))
                
                trackModifications[index] = .replace(type: .audio, file: finalFlac, lang: stream.language)
            } else if preferedLanguages.contains(stream.language) {
                trackModifications[index] = .copy(type: stream.mediaType)
            } else {
                trackModifications[index] = .remove(type: stream.mediaType)
            }
            if stream.isTruehd, index+1<streams.count,
                case let nextStream = streams[index+1],
                nextStream.isAC3, stream.language == nextStream.language {
                // Remove TRUEHD embed-in AC-3 track
                trackModifications[index+1] = .remove(type: .audio)
                index += 1
            }
            index += 1
        }
        
        guard flacConverters.count > 0 else {
            return trackModifications
        }
        
        let ffmpeg = try Process.init(executableName: "ffmpeg", arguments: ffmpegArguments)
        ffmpeg.launchUntilExit()
        try ffmpeg.checkTerminationStatus()
        
        try flacConverters.forEach { (flac) in
            try flac.convert()
            try FileManager.default.removeItem(atPath: flac.input)
        }
        
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
                let currentCount = flacMD5s.countValue(md5)
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
    
    func countValue(_ v: Element) -> Int {
        return self.reduce(0, { (result, current) -> Int in
            if current == v {
                return result + 1
            } else {
                return result
            }
        })
    }
    
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
