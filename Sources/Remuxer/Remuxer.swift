//
//  Remuxer.swift
//  Remuxer
//
//  Created by Kojirou on 2018/9/17.
//

import Foundation
import SwiftFFmpeg

enum RemuxerError: Error {
    case t
    case processError(code: Int32)
}

public enum DiscType: String, CaseIterable {
    case movie
    case episodes
    case dump
}

extension String {
    
    var filenameWithoutExtension: String {
        return URL.init(fileURLWithPath: self).deletingPathExtension().lastPathComponent
    }
    
    var filename: String {
        return URL.init(fileURLWithPath: self).lastPathComponent
    }
    
    func appendingPathComponent(_ str: String) -> String {
        return URL.init(fileURLWithPath: self).appendingPathComponent(str).path
    }
    
    var deletingPathExtension: String {
        return URL.init(fileURLWithPath: self).deletingPathExtension().path
    }
    
    var deletingLastPathComponent: String {
        return URL.init(fileURLWithPath: self).deletingLastPathComponent().path
    }
}

let jsonDecoder = JSONDecoder()

//"HDMV PGS"
//"PCM"
// AC-3 TrueHD
//TrueHD Atmos

class Remuxer {
    
    let tempOutDir: String
    
    init() {
        tempOutDir = Config.tempDir.appendingPathComponent("tmp")
        try? FileManager.default.createDirectory(atPath: tempOutDir, withIntermediateDirectories: true, attributes: nil)
    }
    
    private func scanBDMV(rootpath: String) throws -> [Mpls] {
        print("Start scanning BD folder: \(rootpath)")
        let fm = FileManager.default
        let playlistPath = rootpath.appendingPathComponent("BDMV/PLAYLIST")
//        let streamPath = rootpath.appendingPathComponent("BDMV/STREAM")
        if fm.fileExists(atPath: playlistPath) {
            let mplsPaths = try fm.contentsOfDirectory(atPath: playlistPath).filter {$0.hasSuffix(".mpls")}.map {playlistPath + "/" + $0}
            let mplss = mplsPaths.compactMap({ (path) -> MkvmergeIdentification? in
                do {
                    let id = try MkvmergeIdentification.init(filePath: path)
                    return id
                } catch {
                    print("Invalid file: \(path)")
                    return nil
                }
                
            }).map(Mpls.init)
            return mplss
        } else {
            print("No PLAYLIST Folder!")
            exit(1)
        }
    }
    
    func autoStart(input: String) throws {
        if input.hasSuffix(".mpls") {
            try split(mplsPath: input)
        } else {
            try remux(bdPath: input)
        }
    }
    
    /// auto remux bd pllaylists
    ///
    /// - Parameter bdPath: Blu-ray Disk path
    /// - Throws:
    func remux(bdPath: String, type: DiscType = .movie) throws {
        
        let bdFolderName = bdPath.filename
        let finalOutputDir = Config.outputDir.appendingPathComponent(bdFolderName)
        
        print("Remuxing BD: \(bdFolderName)")
        
        let allMpls = try scanBDMV(rootpath: bdPath)
        
        let multipleFileMpls = allMpls.filter{ $0.files.count > 1 }.filetedByMe
        let singleFileMpls = allMpls.filter{ $0.files.count == 1 }.filetedByMe
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
        
        if singleFileMpls.count > 0 {
            print("Single File MPLS:")
            singleFileMpls.forEach {print($0);print()}
        }
        if cleanMultipleFileMpls.count > 0 {
            print("Multiple File MPLS:")
            cleanMultipleFileMpls.forEach {print($0);print()}
        }
        
        if type == .dump {
            return
        }
        
        // TODO: check conflict
        
        let finalMpls = cleanMultipleFileMpls + singleFileMpls
        
        if type == .episodes {
            // split mode
            var allFiles = Set(finalMpls.flatMap {$0.files})
            try finalMpls.forEach { (mpls) in
                try split(mpls: mpls, files: allFiles)
                mpls.files.forEach({ (usedFile) in
                    allFiles.remove(usedFile)
                })
            }
            return
        }
        
        let merges = finalMpls.flatMap { (mpls) -> [Mkvmerge] in
            
            let preferedLanguages = generatePrimaryLanguages(with: [mpls.primaryLanguage])
            
            let filename = mpls.fileName.filenameWithoutExtension
            
            // TODO: MPLS split mode
            if mpls.useFFmpeg {
                return mpls.files.compactMap({ (path) -> Mkvmerge? in
                    let ffmpegOutputFilename = "\(filename)-\(path.filenameWithoutExtension)-ffmpeg.mkv"
                    let output = tempOutDir.appendingPathComponent(ffmpegOutputFilename)
                    let ffmpeg = FFmpegMerge.init(input: path, output: output)
                    let mkvmerge = Mkvmerge.init(input: output, output: finalOutputDir.appendingPathComponent(ffmpegOutputFilename))
                    do {
                        try ffmpeg.mux()
                        return mkvmerge
                    } catch {
                        do {
                            try ffmpeg.mux(mode: .videoOnly)
                            print("File \(path) is invalid!But video-only mode works.")
                            return mkvmerge
                        } catch {
                            print("File \(path) is invalid!")
                            return nil
                        }
                    }
                })
                
            } else if mpls.updated {
                return mpls.files.map({ (path) -> Mkvmerge in
                    let output = tempOutDir + "/" + filename + "-" + path.filenameWithoutExtension + ".mkv"
                    return Mkvmerge.init(input: path, output: output, audioLanguages: preferedLanguages, subtitleLanguages: preferedLanguages)
                })
            } else {
                let output = tempOutDir + "/" + filename + "-\(mpls.files.map{$0.filenameWithoutExtension}.joined(separator: "+")).mkv"
                return [Mkvmerge.init(input: mpls.fileName, output: output, audioLanguages: preferedLanguages, subtitleLanguages: preferedLanguages)]
            }
            
        }
        
        try merges.forEach { (m) in
            try m.mux()
            try remux(file: m.output, outDir: finalOutputDir, deleteAfterRemux: true)
        }
    }
    
    /// automatic remux and convert gross audio tracks
    ///
    /// - Parameters:
    ///   - file: the path of file to be remuxed
    ///   - outDir: output dir
    ///   - deleteAfterRemux: delete after remux
    /// - Throws:
    func remux(file: String, outDir: String, deleteAfterRemux: Bool) throws {
        let outputFilename = outDir.appendingPathComponent(file.filename)
        guard outputFilename != file else {
            print("OutDir must be different from input's dir")
            return
        }
        var arguments = ["-q", "--output", outputFilename]
        var trackOrder = [String]()
        var audioRemoveTracks = [Int]()
        var subtitleRemoveTracks = [Int]()
        var externalTracks = [(file: String, lang: String)]()
        
        let modifications = try parse(file: file, audioOutDir: file.deletingLastPathComponent)
        
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
        print("Mkvmerge:\n\(file)\n->\n\(outputFilename)\n")
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
    
    func split(mplsPath: String) throws {
        let mpls = try Mpls.init(filePath: mplsPath)
        try split(mpls: mpls)
    }
    
    /// split mpls with a file list
    ///
    /// - Parameters:
    ///   - mpls: <#mpls description#>
    ///   - files: <#files description#>
    /// - Throws: <#throws value description#>
    func split(mpls: Mpls, files: Set<String> = []) throws {
        
        print("Splitting MPLS: \(mpls.fileName)")
        
        let bdFolder = mpls.fileName.deletingLastPathComponent.deletingLastPathComponent.deletingLastPathComponent.filename
        let finalOutDir = Config.outputDir.appendingPathComponent(bdFolder)
        
        guard let clips = mpls.split() else {
            print("MPLS \(mpls) can't be splited!")
            return
        }
        dump(clips)
        
        let preferedLanguages = generatePrimaryLanguages(with: [mpls.primaryLanguage])
        
        try clips.forEach { (clip) in
            let mux: Bool
            if files.count == 0 {
                mux = true
            } else if files.contains(clip.m2tsPath) {
                mux = true
            } else {
                mux = false
            }
            if mux {
                let output: String
                if mpls.useFFmpeg {
                    let outputFilename = "\(mpls.fileName.filenameWithoutExtension)-\(clip.m2tsPath.filenameWithoutExtension)-ffmpeg.mkv"
                    output = tempOutDir.appendingPathComponent(outputFilename)
                    let ff = FFmpegMerge.init(input: clip.m2tsPath, output: output)
                    try ff.mux(mode: .videoOnly)
                } else {
                    let outputFilename = "\(mpls.fileName.filenameWithoutExtension)-\(clip.m2tsPath.filenameWithoutExtension).mkv"
                    output = tempOutDir.appendingPathComponent(outputFilename)
                    let m = Mkvmerge.init(input: clip.m2tsPath, output: output, audioLanguages: preferedLanguages, subtitleLanguages: preferedLanguages, chapterPath: clip.chapterPath)
                    try m.mux()
                }
                try remux(file: output, outDir: finalOutDir, deleteAfterRemux: true)
                
            } else {
                print("Skipping clip: \(clip)")
            }
            
        }
    }
    
    private func generatePrimaryLanguages(with otherLanguages: [String]) -> Set<String> {
        var preferedLanguages = Config.preferedLanguages
        otherLanguages.forEach { (l) in
            preferedLanguages.insert(l)
        }
        return preferedLanguages
    }
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - file: <#file description#>
    ///   - audioOutDir: <#audioOutDir description#>
    /// - Returns: <#return value description#>
    /// - Throws: <#throws value description#>
    private func parse(file: String, audioOutDir: String) throws -> [Modify] {
        let context = try AVFormatContext.init(url: file)
        try context.findStreamInfo()
        let mkvinfo = try MkvmergeIdentification.init(filePath: file)
        let ffmpegLang = context.streams.map({$0.language})
        let mkvmergeLang = mkvinfo.tracks.map({$0.properties.language ?? "und"})
        guard ffmpegLang == mkvmergeLang else {
            print("ffmpeg and mkvmerge generate different languages!")
            print("ffmpeg: \(ffmpegLang)")
            print("mkvmerge: \(mkvmergeLang)")
            throw RemuxerError.t
        }
//        dump(ffmpegLang)
        var preferedLanguages = generatePrimaryLanguages(with: [context.primaryLanguage])
//        try convertLosslessAudio(input: file, outputDir: audioOutDir, preferedLanguages: preferedLanguages)
        
        let streams = context.streams
        var flacConverters = [Flac]()
        var arguments = ["-v", "quiet", "-nostdin", "-y", "-i", file, "-vn"]
        var trackModifications = [Modify].init(repeating: .copy(type: .unknown), count: streams.count)
        
        func displayModify() {
            print("Track modifications: ")
            for m in trackModifications.enumerated() {
                print("\(m.offset): \(m.element)")
            }
        }
        
        // check track one by one
        print("Checking tracks codec")
        var index = 0
        while index < streams.count {
            let stream = streams[index]
            print("\(stream.index): \(stream.codecpar.codecId.name) \(stream.isLosslessAudio ? "lossless" : "lossy") \(stream.language)")
            if stream.isGrossAudio, preferedLanguages.contains(stream.language) {
                // add to convert queue
                arguments.append("-map")
                arguments.append("0:\(stream.index)")
                let tempFlac = "\(audioOutDir)/\(file.filenameWithoutExtension)-\(stream.index)-\(stream.language)-ffmpeg.flac"
                let finalFlac = "\(audioOutDir)/\(file.filenameWithoutExtension)-\(stream.index)-\(stream.language).flac"
                arguments.append(tempFlac)
                flacConverters.append(Flac.init(input: tempFlac, output: finalFlac))
                
                trackModifications[index] = .replace(type: .audio, file: finalFlac, lang: stream.language)
            } else if preferedLanguages.contains(stream.language) {
                trackModifications[index] = .copy(type: stream.mediaType)
            } else {
                trackModifications[index] = .remove(type: stream.mediaType)
            }
            if stream.isTruehd, index+1<streams.count,
                case let nextStream = streams[index+1], nextStream.isAC3 {
                trackModifications[index+1] = .remove(type: .audio)
                index += 1
            }
            index += 1
        }
        
        guard flacConverters.count > 0 else {
            displayModify()
            return trackModifications
        }
        let ffmpeg = try Process.init(executableName: "ffmpeg", arguments: arguments)
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
                var allTracks = [(Int, Modify)]()
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
        
        displayModify()
        
        return trackModifications
    }
}

enum Modify {
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
