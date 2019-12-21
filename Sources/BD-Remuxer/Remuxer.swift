import Foundation
import MediaTools
import MplsParser
import Executable
import URLFileManager
import KwiftUtility
import TrackExtension
import TSCBasic
import Rainbow

let _fm = URLFileManager.default

public class Remuxer {
    
    private let config: RemuxerArgument
    
    private let allowedExitCodes: [CInt]
    
    private let flacQueue = OperationQueue()
    
//    private let processManager = SubProcessManager()
    
    public init(config: RemuxerArgument) throws {
        flacQueue.maxConcurrentOperationCount = 4
        self.config = config
        #if DEBUG
        dump(config)
        #endif
        if self.config.ignoreWarning {
            self.allowedExitCodes = [0, 1]
        } else {
            self.allowedExitCodes = [0]
        }
    }

    private var runningProcess: TSCBasic.Process?

    private func launch(externalExecutable: Executable) throws -> ProcessResult {
        let process = try externalExecutable.generateTSCProcess(outputRedirection: .collect, startNewProcessGroup: false)
        try process.launch()
        runningProcess = process
        let result = try process.waitUntilExit()
        runningProcess = nil
//        switch result.exitStatus {
//        case .signalled(signal: _):
//            throw ExecutableError.tscNonZeroExit(result.exitStatus)
//        default:
//            break
//        }
        return result
    }

    private func launch(externalExecutable: Executable,
                                               checkAllowedExitCodes codes: [CInt]) throws {
        let result = try self.launch(externalExecutable: externalExecutable)
        switch result.exitStatus {
        case .terminated(code: let code):
            if !codes.contains(code) {
                throw ExecutableError.tscNonZeroExit(result.exitStatus)
            }
        case .signalled(signal: _):
            throw ExecutableError.tscNonZeroExit(result.exitStatus)
        }
    }

    private var terminated = false

    func terminate() {
        terminated = true
        flacQueue.cancelAllOperations()
        runningProcess?.signal(SIGTERM)
        do {
            try currentTemporaryPath.map {try _fm.removeItem(at: $0)}
        } catch {
            print("Faield to remove the temp dir at \(currentTemporaryPath!), you can delete it manually")
        }
    }

    func logConverterStart(name: String, input: String, output: String) {
        print("\n\(name):\n\(input)\n->\n\(output)")
    }
    
    func recursiveRun(task: WorkTask) throws -> [URL] {
        do {
            logConverterStart(name: task.main.executableName,
                              input: task.main.inputDescription,
                              output: task.main.outputURL.path)
            try launch(externalExecutable: task.main, checkAllowedExitCodes: allowedExitCodes)
        } catch {
            if task.canBeIgnored {
                return []
            }
            if let splitWorkers = task.splitWorkers {
                for splitWorker in splitWorkers {
                    try launch(externalExecutable: splitWorker, checkAllowedExitCodes: allowedExitCodes)
                }
                do {
                    let result = try launch(externalExecutable: task.joinWorker!)
                    if result.exitStatus == .terminated(code: 2) {
                        throw ExecutableError.tscNonZeroExit(result.exitStatus)
                    }
                    return [task.joinWorker!.outputURL]
                } catch {
                    print("Failed to join file, \(error)")
                    return splitWorkers.map {$0.outputURL}
                }
            } else {
                throw error
            }
        }
        
        if _fm.fileExistance(at: task.main.outputURL).exists {
            // output exists
            return [task.main.outputURL]
        } else if task.chapterSplit, let parts = try? _fm.contentsOfDirectory(at: task.main.outputURL.deletingLastPathComponent()).filter({$0.pathExtension == task.main.outputURL.pathExtension && $0.lastPathComponent.hasPrefix(task.main.outputURL.lastPathComponentWithoutExtension)}) {
            return parts
        } else {
            print("Can't find output file(s).")
            throw RemuxerError.noOutputFile(task.main.outputURL)
        }
    }
    
    func remuxBDMV(at bdmvPath: URL, mode: MplsRemuxMode, temporaryPath: URL) -> Result<Summary, RemuxerError> {

        let startDate = Date()
        var sizeBefore: UInt64 = 0
        var sizeAfter: UInt64 = 0

        let task = BDMVTask(rootPath: bdmvPath, mode: mode,temporaryPath: temporaryPath, language: config.language, splits: config.splits)
        let finalOutputPath = config.outputRootDirectory.appendingPathComponent(task.getBlurayTitle())
        if _fm.fileExistance(at: finalOutputPath).exists {
            return .failure(.outputExist)
        }
        let converters: [WorkTask]
        do {
            converters = try task.parse()
        } catch {
            return .failure(.parseBDMV(error))
        }
        var tempFiles = [URL]()
        for converter in converters {
            do {
                tempFiles.append(contentsOf: try recursiveRun(task: converter))
            } catch {
                return .failure(.mplsToMKV(converter, error))
            }
        }
        
        for tempFile in tempFiles {
            let mkvinfo: MkvmergeIdentification
            switch readMKV(at: tempFile) {
            case .failure(let e): return .failure(e)
            case .success(let v): mkvinfo = v
            }

            let duration = Timestamp(ns: UInt64(mkvinfo.container.properties?.duration ?? 0))
            let subFolder: String
            if config.organize {
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
            } else {
                subFolder = ""
            }

            let remuxResult = _remux(file: tempFile,
                      remuxOutputDir: finalOutputPath.appendingPathComponent(subFolder), temporaryPath: temporaryPath,
                      deleteAfterRemux: true, mkvinfoCache: mkvinfo)

            switch remuxResult {
            case .failure(let e): return .failure(e)
            case .success(let summary):
                sizeBefore += summary.sizeBefore
                sizeAfter += summary.sizeAfter
            }
        }
        if config.deleteAfterRemux {
            try? _fm.removeItem(at: bdmvPath)
        }

        return .success(.init(sizeBefore: sizeBefore, sizeAfter: sizeAfter, startDate: startDate, endDate: .init()))
    }
    
    func remuxFile(at path: URL, temporaryPath: URL) -> Result<Summary, RemuxerError> {
        let fileType = _fm.fileExistance(at: path)
        switch fileType {
        case .none:
            return .failure(.inputNotExists)
        case .directory:
            return .failure(.directoryInFileMode)
        case .file:
            return _remux(file: path, remuxOutputDir: config.outputRootDirectory, temporaryPath: temporaryPath, deleteAfterRemux: config.deleteAfterRemux)
        }
    }
    
    func start() {
        terminated = false
        guard !config.inputs.isEmpty else {
            print("No inputs!")
            return
        }

        var workItems = [RemuxerWorkItem]()
        
        config.inputs.forEach { (input) in
            let inputURL = URL(fileURLWithPath: input)
            if terminated {
                workItems.append(.init(input: inputURL, result: .failure(.terminated)))
                return
            }
            do {
                try config.withTemporaryPath({ (tempDirectory) in
                    self.currentTemporaryPath = tempDirectory
                    defer {self.currentTemporaryPath = nil}

                    let result: Result<Summary, RemuxerError>
                    switch config.mode {
                    case .dumpBDMV:
                        let task = BDMVTask(rootPath: inputURL, mode: .direct, temporaryPath: tempDirectory, language: config.language, splits: config.splits)
                        do {
                            try task.dumpInfo()
                        } catch {
                            print("Failed to read BDMV at \(input)")
                        }
                    case .episodes, .movie:
                        let mode: MplsRemuxMode = config.mode == .episodes ? .split : .direct
                        result = remuxBDMV(at: inputURL, mode: mode, temporaryPath: tempDirectory)
                        workItems.append(RemuxerWorkItem(input: inputURL, result: result))
                    case .file:
                        result = remuxFile(at: inputURL, temporaryPath: tempDirectory)
                        workItems.append(RemuxerWorkItem(input: inputURL, result: result))
                    }
                })
            } catch {
                fatalError("cannot create/remove temp directory!\n\(error)")
            }
        }

        if config.mode != .dumpBDMV {
            // show summary
            printSummary(workItems: workItems)
        }
    }
    
    var currentTemporaryPath: URL?
    
}

extension Remuxer {

    private func readMKV(at url: URL) -> Result<MkvmergeIdentification, RemuxerError> {
        do {
            return try .success(.init(url: url))
        } catch {
            return .failure(.mkvmergeIdentification(error))
        }
    }
    
    private func _remux(file: URL, remuxOutputDir: URL, temporaryPath: URL,
                        deleteAfterRemux: Bool,
                        parseOnly: Bool = false,
                        mkvinfoCache: MkvmergeIdentification? = nil) -> Result<Summary, RemuxerError> {
        let startDate = Date()
//        print("Start remuxing file \(file.lastPathComponent)")
        let outputURL = remuxOutputDir
            .appendingPathComponent("\(file.lastPathComponentWithoutExtension).mkv")
        guard !_fm.fileExistance(at: outputURL).exists else {
//            print("\(outputFilename) already exists!")
//            throw RemuxerError.outputExist
            return .failure(.outputExist)
        }
        let sizeBefore: UInt64
        do {
            sizeBefore = try _fm.attributesOfItem(atURL: file)[.size] as! UInt64
        } catch {
            sizeBefore = 0
        }


        var trackOrder = [Mkvmerge.GlobalOption.TrackOrder]()
        var audioRemoveTracks = [Int]()
        var subtitleRemoveTracks = [Int]()
        var externalTracks = [(file: URL, lang: String, trackName: String)]()
        
        let mkvinfo: MkvmergeIdentification
        if mkvinfoCache == nil {
            switch readMKV(at: file) {
            case .failure(let e):
                return .failure(e)
            case .success(let v):
                mkvinfo = v
            }
        } else {
            mkvinfo = mkvinfoCache!
        }

        let modifications: [TrackModification]
        switch _makeTrackModification(mkvinfo: mkvinfo, temporaryPath: temporaryPath) {
        case .failure(let e):
            return .failure(e)
        case .success(let v):
            modifications = v
        }
        
        var mainInput = Mkvmerge.Input(file: file.path)
        
        for modify in modifications.enumerated() {
            switch modify.element {
            case .copy(_):
                trackOrder.append(.init(fid: 0, tid: modify.offset))
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
                trackOrder.append(.init(fid: externalTracks.count, tid: 0))
            }
            if !config.keepTrackName {
                mainInput.options.append(.trackName(tid: modify.offset, name: ""))
            }
        }

        mainInput.options.append(.audioTracks(.disabledTIDs(audioRemoveTracks)))
        mainInput.options.append(.subtitleTracks(.disabledTIDs(subtitleRemoveTracks)))
        mainInput.options.append(.attachments(.removeAll))
        
        let externalInputs = externalTracks.map { (track) -> Mkvmerge.Input in
            var options: [Mkvmerge.Input.InputOption] = [.language(tid: 0, language: track.lang)]
            if config.keepTrackName {
                options.append(.trackName(tid: 0, name: track.trackName))
            }
            return .init(file: track.file.path, options: options)
        }
        
        let mkvmerge = Mkvmerge.init(global: .init(quiet: true, split: generateSplit(splits: config.splits, chapterCount: mkvinfo.chapters.first?.numEntries ?? 0), trackOrder: trackOrder), output: outputURL.path, inputs: [mainInput] + externalInputs)
        print("Mkvmerge arguments:\n\(mkvmerge.arguments.joined(separator: " "))")
        
        print("\nMkvmerge:\n\(file)\n->\n\(outputURL)")
        do {
            try launch(externalExecutable: mkvmerge, checkAllowedExitCodes: allowedExitCodes)
        } catch {
            return .failure(.mkvmergeMux(error))
        }

        externalTracks.forEach { (t) in
            do {
                try _fm.removeItem(at: t.file)
            } catch {
                print("Can not delete file: \(t.file)")
            }
        }
        if deleteAfterRemux {
            do {
                try _fm.removeItem(at: file)
            } catch {
                print("Can not delete file: \(file)")
            }
        }

        let sizeAfter: UInt64
        do {
            sizeAfter = try _fm.attributesOfItem(atURL: outputURL)[.size] as! UInt64
        } catch {
            sizeAfter = 0
        }

        return .success(.init(sizeBefore: sizeBefore, sizeAfter: sizeAfter, startDate: startDate, endDate: .init()))
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
    
    private func _makeTrackModification(mkvinfo: MkvmergeIdentification,
                                       temporaryPath: URL) -> Result<[TrackModification], RemuxerError> {
        let preferedLanguages = config.language.generatePrimaryLanguages(with: mkvinfo.primaryLanguages)
        let tracks = mkvinfo.tracks
        var flacConverters = [FlacEncoder]()
        var ffmpegArguments = ["-v", "quiet", "-nostdin", "-y", "-i", mkvinfo.fileName, "-vn"]
        var trackModifications = [TrackModification].init(repeating: .copy(type: .video), count: tracks.count)
        
        defer {
            display(modiifcations: trackModifications)
        }
        
        // check track one by one
        print("Checking tracks codec")
        var currentTrackIndex = 0
        let baseFilename = URL(fileURLWithPath:  mkvinfo.fileName).lastPathComponentWithoutExtension
        
        while currentTrackIndex < tracks.count {
            let currentTrack = tracks[currentTrackIndex]
            let trackLanguage = currentTrack.properties.language ?? "und"
            print(currentTrack.remuxerInfo)
            var embbedAC3Removed = false
            if preferedLanguages.contains(trackLanguage) {
                var trackDone = false
                if currentTrack.isTrueHD, config.keepTrueHD {
                    trackModifications[currentTrackIndex] = .copy(type: currentTrack.type)
                    trackDone = true
                }
                if !trackDone, config.removeExtraDTS, currentTrack.isDTSHD {
                    var fixed = false
                    if case let indexBefore = currentTrackIndex-1, indexBefore >= 0 {
                        let compareTrack = tracks[indexBefore]
                        if compareTrack.isTrueHD,
                            compareTrack.properties.language == currentTrack.properties.language,
                        compareTrack.properties.audioChannels == currentTrack.properties.audioChannels {
                            trackModifications[currentTrackIndex] = .remove(type: .audio)
                            fixed = true
                            // remove the ac3 after
                            if !embbedAC3Removed, currentTrackIndex+1<tracks.count,
                                case let nextTrack = tracks[currentTrackIndex+1],
                                nextTrack.isAC3, nextTrack.properties.language == currentTrack.properties.language {
                                // Remove TRUEHD embed-in AC-3 track
                                trackModifications[currentTrackIndex+1] = .remove(type: .audio)
                                currentTrackIndex += 1
                                embbedAC3Removed = true
                            }
                        }
                    }
                    if !fixed, case let indexAfter = currentTrackIndex+1, indexAfter < tracks.count {
                        let compareTrack = tracks[indexAfter]
                        if compareTrack.isTrueHD,
                            compareTrack.properties.language == currentTrack.properties.language,
                            compareTrack.properties.audioChannels == currentTrack.properties.audioChannels {
                            trackModifications[currentTrackIndex] = .remove(type: .audio)
                            fixed = true
                        }
                    }
                    trackDone = fixed
                }

                if !trackDone, currentTrack.isLosslessAudio {
                    // add to ffmpeg arguments
                    let tempFlac = temporaryPath.appendingPathComponent("\(baseFilename)-\(currentTrackIndex)-\(trackLanguage)-ffmpeg.flac")
                    let finalFlac = temporaryPath.appendingPathComponent("\(baseFilename)-\(currentTrackIndex)-\(trackLanguage).flac")
                    ffmpegArguments.append(contentsOf: ["-map", "0:\(currentTrackIndex)", tempFlac.path])
                    var flac = FlacEncoder(input: tempFlac.path, output: finalFlac.path)
                    flac.level = 8
                    flac.forceOverwrite = true
                    flac.silent = true
                    flacConverters.append(flac)
                    
                    trackModifications[currentTrackIndex] = .replace(type: .audio, file: finalFlac, lang: trackLanguage, trackName: currentTrack.properties.trackName ?? "")
                    trackDone = true
                }

                if !trackDone {
                    trackModifications[currentTrackIndex] = .copy(type: currentTrack.type)
                }
            } else {
                trackModifications[currentTrackIndex] = .remove(type: currentTrack.type)
            }

            // handle truehd
            if !embbedAC3Removed, currentTrack.isTrueHD, currentTrackIndex+1<tracks.count,
                case let nextTrack = tracks[currentTrackIndex+1],
                nextTrack.isAC3 {
                // Remove TRUEHD embed-in AC-3 track
                trackModifications[currentTrackIndex+1] = .remove(type: .audio)
                currentTrackIndex += 1
            }
            currentTrackIndex += 1
        }
        
        guard flacConverters.count > 0 else {
            return .success(trackModifications)
        }
        
        print("ffmpeg \(ffmpegArguments.joined(separator: " "))")

        do {
            try launch(externalExecutable: MediaTools.ffmpeg.executable(ffmpegArguments),
                   checkAllowedExitCodes: [0])
        } catch {
            return .failure(.ffmpegExtractAudio(error))
        }
        
        flacConverters.forEach { (flac) in
            self.logConverterStart(name: "flac", input: flac.input, output: flac.output)

            let operation = FlacConvertOperation(flac: flac)
            operation.completionBlock = {
                do {
                    try _fm.removeItem(at: URL(fileURLWithPath: flac.input))
                } catch {
                    print("Failed to remove the temp flac file at \(flac.input)")
                }
            }

            flacQueue.addOperation(operation)
        }
        flacQueue.waitUntilAllOperationsAreFinished()
        if terminated {
            return .failure(.terminated)
        }
        
        // check duplicate audio track
        let flacPaths = flacConverters.map({$0.output})
        let flacMD5s: [String]
        do {
            flacMD5s = try FlacMD5.calculate(inputs: flacPaths)
        } catch {
            return .failure(.validateFlacMD5(error))
        }
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
                        if filesWithSameMD5.contains(file.path) {
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
        
        return .success(trackModifications)
    }
    
}

enum TrackModification {
    
    case copy(type: MediaTrackType)
    case replace(type: MediaTrackType, file: URL, lang: String, trackName: String)
    case remove(type: MediaTrackType)
    
    mutating func remove() {
        switch self {
        case .replace(type: let type, file: let file, lang: _, trackName: _):
            try? _fm.removeItem(at: file)
            self = .remove(type: type)
        case .copy(type: let type):
            self = .remove(type: type)
        case .remove(type: _):
            return
        }
        
    }
    
    var type: MediaTrackType {
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

//struct SubTask {
//    var sizeBefore: UInt64
//    var sizeAfter: UInt64
//    var startDate: Date
//    var endDate: Date
//    let converter: Converter
//    let split: Bool
//}

struct BDMVTask {
    let rootPath: URL
    let mode: MplsRemuxMode
    let temporaryPath: URL
    let language: RemuxerArgument.LanguagePreference
    let splits: [Int]?
    
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
                    let preferedLanguages = language.generatePrimaryLanguages(with: [mpls.primaryLanguage])
                    let outputFilename = generateFilename(mpls: mpls)
                    let output = temporaryPath.appendingPathComponent(outputFilename + ".mkv")
                    let parsedMpls = try MplsPlaylist.parse(mplsURL: mpls.fileName)
                    let chapter = parsedMpls.convert()
                    let chapterFile = temporaryPath.appendingPathComponent("\(mpls.fileName.lastPathComponentWithoutExtension).txt")
                    let chapterPath: String?
                    if !chapter.isEmpty {
                        try chapter.exportOgm().write(toFile: chapterFile.path, atomically: true, encoding: .utf8)
                        chapterPath = chapterFile.path
                    } else {
                        chapterPath = nil
                    }
                    
                    if splits != nil {
                        
                        tasks.append(.init(input: mpls.fileName, main: Mkvmerge(global: .init(quiet: true, split: generateSplit(splits: splits, chapterCount: mpls.chapterCount), chapterFile: chapterPath), output: output.path, inputs: [.init(file: mpls.fileName.path, options: [.audioTracks(.enabledLANGs(preferedLanguages)), .subtitleTracks(.enabledLANGs(preferedLanguages))])]), chapterSplit: true, canBeIgnored: false))
                    } else {
                        let splitWorkers = try split(mpls: mpls).map {$0.main}
                        let main = Mkvmerge.init(global: .init(quiet: true, chapterFile: chapterPath), output: output.path, inputs: mpls.files.enumerated().map {Mkvmerge.Input.init(file: $0.element.path, append: $0.offset != 0, options: [.audioTracks(.enabledLANGs(preferedLanguages)), .subtitleTracks(.enabledLANGs(preferedLanguages))])})
                        let joinWorker = Mkvmerge(global: .init(quiet: true, chapterFile: chapterPath), output: output.path, inputs: splitWorkers.enumerated().map {Mkvmerge.Input.init(file: $0.element.outputURL.path, append: $0.offset != 0, options: [.audioTracks(.enabledLANGs(preferedLanguages)), .subtitleTracks(.enabledLANGs(preferedLanguages)), .noChapters])})
                        tasks.append(.init(input: mpls.fileName,
                                           main: main, chapterSplit: false,
                                           splitWorkers: splitWorkers, joinWorker: joinWorker
                                           ))
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
        rootPath.lastPathComponent.safeFilename().trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func scan(removeDuplicate: Bool) throws -> [Mpls] {
        print("Start scanning BD folder: \(rootPath)")
        let playlistPath = rootPath.appendingPathComponent("BDMV/PLAYLIST", isDirectory: true)

        if _fm.fileExistance(at: playlistPath) == .directory {
            let mplsPaths = try _fm.contentsOfDirectory(at: playlistPath).filter {$0.pathExtension.lowercased() == "mpls"}
            if mplsPaths.isEmpty {
                throw RemuxerError.noPlaylists
            }
            let allMpls = mplsPaths.compactMap { (mplsPath) -> Mpls? in
                do {
                    return try .init(filePath: mplsPath.path)
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
    
    func split(mpls: Mpls, restFiles: Set<URL>) throws -> [WorkTask] {
        
        print("Splitting MPLS: \(mpls.fileName)")
        
        if restFiles.count == 0 {
            return []
        }
        
        let clips = try mpls.split(chapterPath: temporaryPath)
        let preferedLanguages = language.generatePrimaryLanguages(with: [mpls.primaryLanguage])
        
        return clips.flatMap { (clip) -> [WorkTask] in
            if restFiles.contains(clip.m2tsPath) {
                let output: URL
                let outputBasename = "\(mpls.fileName.lastPathComponentWithoutExtension)-\(clip.baseFilename)"
                if mpls.useFFmpeg {
                    return [
                        .init(input: clip.fileName,
                              main: FFmpegMuxer(input: clip.m2tsPath.path,
                                                    output: temporaryPath.appendingPathComponent("\(outputBasename)-ffmpeg-video.mkv").path,
                                                    mode: .videoOnly), chapterSplit: false, canBeIgnored: true),
                        .init(input: clip.fileName,
                              main: FFmpegMuxer(input: clip.m2tsPath.path,
                                                output: temporaryPath.appendingPathComponent("\(outputBasename)-ffmpeg-audio.mkv").path, mode: .audioOnly), chapterSplit: false, canBeIgnored: true)
                    ]
                } else {
                    let outputFilename = "\(outputBasename).mkv"
                    output = temporaryPath.appendingPathComponent(outputFilename)
                    return [.init(input: clip.fileName, main: Mkvmerge.init(global: .init(quiet: true, chapterFile: clip.chapterPath?.path), output: output.path, inputs: [.init(file: clip.m2tsPath.path, options: [.audioTracks(.enabledLANGs(preferedLanguages)), .subtitleTracks(.enabledLANGs(preferedLanguages))])]), chapterSplit: false, canBeIgnored: false)]
                }
                
            } else {
                print("Skipping clip: \(clip)")
                return []
            }
            
        }
    }
    
    private func generateFilename(mpls: Mpls) -> String {
        return "\(mpls.fileName.lastPathComponentWithoutExtension)-\(mpls.files.map{$0.lastPathComponentWithoutExtension}.joined(separator: "+").prefix(200))"
    }
    
}

private func generateSplit(splits: [Int]?, chapterCount: Int) -> Mkvmerge.GlobalOption.Split? {
        guard let splits = splits, splits.count > 0 else {
            return nil
        }
        let totalChaps = splits.reduce(0, +)
        if totalChaps == chapterCount {
            var chapIndex = [Int]()
            var chapCount = 0
            splits.forEach { (chap) in
                chapIndex.append(chap+1+chapCount)
                chapCount += chap
            }
            return .chapters(.numbers(chapIndex.dropLast()))
        } else {
            return nil
        }
    }

//struct SubTask {
//    let main: Converter
//    let alternatives: [SubTask]?
////    let size: Int
//}

public struct WorkTask {
    public let input: URL
    public let main: Converter
    public let chapterSplit: Bool
    public let splitWorkers: [Converter]?
    public let joinWorker: Converter?
    public let canBeIgnored: Bool
//    let inputSize: Int
    
    public init(input: URL, main: Converter, chapterSplit: Bool, canBeIgnored: Bool) {
        self.input = input
        self.main = main
        self.chapterSplit = chapterSplit
        self.splitWorkers = nil
        self.joinWorker = nil
        self.canBeIgnored = canBeIgnored
    }
    
    public init(input: URL, main: Converter, chapterSplit: Bool, splitWorkers: [Converter], joinWorker: Converter) {
        self.input = input
        self.main = main
        self.chapterSplit = chapterSplit
        self.splitWorkers = splitWorkers
        self.joinWorker = joinWorker
        self.canBeIgnored = false
    }
}
