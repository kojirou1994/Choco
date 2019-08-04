import Foundation
@_exported import MediaTools
import MplsParser
import ArgumentParser
import Executable
import URLFileManager

public enum RemuxerError: Error {
    case errorReadingFile
    case noPlaylists
    case sameFilename
    case outputExist
    case noOutputFile(URL)
}

let _fm = URLFileManager()

struct RemuxerArgument {
    
    private(set) internal var outputPath: URL
    
    private var temporaryPath: URL
    
    public func makeTemporaryPath() throws -> URL {
        let t = temporaryPath.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try _fm.createDirectory(at: t)
        return t
    }
    
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
        
        static var allSelection: String {
            return allCases.map{$0.rawValue}.joined(separator: "|")
        }
    }
    
    private(set) internal var mode: RemuxMode
    
    private(set) internal var splits: [Int]?
    
    private(set) internal var inputs: [URL]
    
    struct LanguagePreference {
        
        static let defaultLanguages: Set<String> = ["und", "chi", "eng", "jpn"]
        
        static var `default`: Self {
            .init(languages: Self.defaultLanguages, excludeLanguages: [])
        }
        var languages: Set<String>
        
        var excludeLanguages: Set<String>
        
        func generatePrimaryLanguages(with otherLanguages: [String]) -> Set<String> {
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
    
    private(set) internal var language: LanguagePreference
    
//    var excludeLanguages: Set<String>
    
    private(set) internal var deleteAfterRemux: Bool
    
    private(set) internal var keepTrackName: Bool
    
    private(set) internal var keepTrueHD: Bool
    
    private(set) internal var help: Bool
    
    static func parse() throws -> Self {
        var config = RemuxerArgument.init(outputPath: URL(fileURLWithPath: "."), temporaryPath: URL(fileURLWithPath: "."), mode: .movie, splits: nil, inputs: [], language: .default, deleteAfterRemux: false, keepTrackName: false, keepTrueHD: false, help: false)
        let output = Option(name: "--output", anotherName: "-o", requireValue: true, description: "output dir") { (v) in
            config.outputPath = URL.init(fileURLWithPath: v)
        }
        
        let temp = Option(name: "--temp", anotherName: "-t", requireValue: true, description: "temp dir") { (v) in
            config.temporaryPath = URL.init(fileURLWithPath: v)
        }
        
        let mode = Option(name: "--mode", requireValue: true, description: "remux mode") { (v) in
            guard let modeV = RemuxerArgument.RemuxMode.init(rawValue: v) else {
                fatalError("Unknown mode: \(v)")
            }
            config.mode = modeV
        }
        let language = Option(name: "--language", requireValue: true, description: "valid languages") { (v) in
            config.language.languages = Set(v.components(separatedBy: ",") + ["und"])
        }
        let excludeLanguage = Option(name: "--exclude-language", requireValue: true, description: "exclude languages") { (v) in
            config.language.excludeLanguages = Set(v.components(separatedBy: ","))
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
        
        let keepTrueHD = Option(name: "--keep-true-hd", requireValue: false, description: "keep TrueHD track") { (v) in
            config.keepTrueHD = true
        }
        
        let help = Option(name: "--help", anotherName: "-H", requireValue: false, description: "show help") { (v) in
            config.help = true
        }
        
        let parser = ArgumentParser(usage: "Remuxer --mode \(RemuxerArgument.RemuxMode.allSelection) [OPTIONS] [INPUT]", options: [output, temp, mode, language, splits, deleteAfterRemux, keepTrackName, keepTrueHD, help, excludeLanguage]) { (v) in
            config.inputs.append(URL(fileURLWithPath: v))
        }
        try parser.parse(arguments: CommandLine.arguments.dropFirst())
        
        if config.help {
            parser.showHelp(to: &StdOutputStream.stderrOutputStream)
            exit(0)
        }
        config.temporaryPath = config.temporaryPath.appendingPathComponent("BD-Remuxer-tmp", isDirectory: true)
        try _fm.createDirectory(at: config.temporaryPath)
        return config
    }
}

public class Remuxer {
    
    private let config: RemuxerArgument
    
    private let flacQueue = ParallelProcessQueue.init()
    
    private let processManager = SubProcessManager()
    
    public init() throws {
//        FFmpegLog.set(level: .quite)
        flacQueue.maxConcurrentCount = 4
        self.config = try .parse()
        dump(config)
    }
    
    private func beforeRun(p: Process) {
        p.terminationHandler = {self.processManager.remove(process: $0)}
    }
    
    private func afterRun(p: Process) {
        processManager.add(process: p)
    }
    
    func recursiveRun(task: WorkTask) throws -> [URL] {
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
        
        if _fm.fileExistance(at: task.main.outputPath).exists {
            // output exists
            return [task.main.outputPath]
        } else if task.chapterSplit, let parts = try? _fm.contentsOfDirectory(at: task.main.outputPath.deletingLastPathComponent()).filter({$0.pathExtension == task.main.outputPath.pathExtension && $0.lastPathComponent.hasPrefix(task.main.outputPath.lastPathComponentWithoutExtension)}) {
            return parts
        } else {
            print("Can't find output file(s).")
            throw RemuxerError.noOutputFile(task.main.outputPath)
        }
    }
    
    func remuxBDMV(at bdmvPath: URL, mode: MplsRemuxMode, temporaryPath: URL) throws {
        let task = BDMVTask(rootPath: bdmvPath, mode: mode,temporaryPath: temporaryPath, language: config.language, splits: config.splits)
        let finalOutputPath = config.outputPath.appendingPathComponent(task.getBlurayTitle(), isDirectory: true)
        if _fm.fileExistance(at: finalOutputPath).exists {
            throw RemuxerError.outputExist
        }
        let converters = try task.parse()
        var tempFiles = [URL]()
        try converters.forEach({ (converter) in
            tempFiles.append(contentsOf: try recursiveRun(task: converter))
        })
        
        try tempFiles.forEach { (tempFile) in
            let mkvinfo = try MkvmergeIdentification(url: tempFile)
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
                      remuxOutputDir: finalOutputPath.appendingPathComponent(subFolder), temporaryPath: temporaryPath,
                      deleteAfterRemux: true, mkvinfo: mkvinfo)
        }
        if config.deleteAfterRemux {
            try? _fm.removeItem(at: bdmvPath)
        }
    }
    
    func remuxFile(at path: URL, temporaryPath: URL) throws {
        let fileType = _fm.fileExistance(at: path)
        switch fileType {
        case .none:
            print("\(path.path) doesn't exist!")
        case .directory:
            // input is a directory, remux all contents
            let outputDir = config.outputPath.appendingPathComponent(path.lastPathComponent, isDirectory: true)
            try _fm.createDirectory(at: outputDir)
            
            let contents = try _fm.contentsOfDirectory(at: path)
            
            contents.forEach({ (fileInDir) in
                do {
                    try remux(file: fileInDir, remuxOutputDir: outputDir, temporaryPath: temporaryPath, deleteAfterRemux: false)
                } catch {
                    print(error)
                }
            })
        case .file:
            do {
                try remux(file: path, remuxOutputDir: config.outputPath, temporaryPath: temporaryPath, deleteAfterRemux: false)
            } catch {
                print(error)
            }
        }
    }
    
    func run() {
        if config.inputs.isEmpty {
            print("No inputs!")
            return
        }
//        var failedTasks: [String] = []
        
        config.inputs.forEach { (path) in
            do {
                let temporaryPath = try config.makeTemporaryPath()
                self.currentTemporaryPath = temporaryPath
                
                switch config.mode {
                case .dumpBDMV:
                    let task = BDMVTask(rootPath: path, mode: .direct, temporaryPath: temporaryPath, language: config.language, splits: config.splits)
                    try task.dumpInfo()
                case .episodes, .movie:
                    let mode: MplsRemuxMode = config.mode == .episodes ? .split : .direct
                    try remuxBDMV(at: path, mode: mode, temporaryPath: temporaryPath)
                case .file:
                    try remuxFile(at: path, temporaryPath: temporaryPath)
                }
                
                try _fm.removeItem(at: temporaryPath)
                self.currentTemporaryPath = nil
            } catch {
                print("Error while handling file \(path.path), info: \(error)")
            }
            
        }
    }
    
    var currentTemporaryPath: URL?
    
    func clear() {
        processManager.terminateAll()
        flacQueue.terminateAllProcesses()
        if let t = currentTemporaryPath {
            try! _fm.removeItem(at: t)
        }
    }
    
}

extension Remuxer {
    
    func remux(file: URL, remuxOutputDir: URL, temporaryPath: URL, deleteAfterRemux: Bool,
               parseOnly: Bool = false, mkvinfo: MkvmergeIdentification? = nil) throws {
        let outputFilename = remuxOutputDir.appendingPathComponent("\(file.lastPathComponentWithoutExtension).mkv")
        guard !_fm.fileExistance(at: outputFilename).exists else {
            print("\(outputFilename) already exists!")
            throw RemuxerError.outputExist
        }

        var trackOrder = [Mkvmerge.GlobalOption.TrackOrder]()
        var audioRemoveTracks = [Int]()
        var subtitleRemoveTracks = [Int]()
        var externalTracks = [(file: URL, lang: String, trackName: String)]()
        
        let mkvinfo = try mkvinfo ?? MkvmergeIdentification.init(url: file)
        let modifications = try makeTrackModification(mkvinfo: mkvinfo, temporaryPath: temporaryPath)
        
        var mainInput = Mkvmerge.Input.init(file: file.path)
        
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
        
        let mkvmerge = Mkvmerge.init(global: .init(quiet: true, split: generateSplit(splits: config.splits, chapterCount: mkvinfo.chapters.first?.numEntries ?? 0), trackOrder: trackOrder), output: outputFilename.path, inputs: [mainInput] + externalInputs)
        print("Mkvmerge arguments:\n\(mkvmerge.arguments.joined(separator: " "))")
        
        print("\nMkvmerge:\n\(file)\n->\n\(outputFilename)")
        try mkvmerge.runAndWait(checkNonZeroExitCode: true, beforeRun: beforeRun(p:), afterRun: afterRun(p:))
        
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
    
    private func makeTrackModification(mkvinfo: MkvmergeIdentification,
                                       temporaryPath: URL) throws -> [TrackModification] {
//        let context = try FFmpegInputFormatContext.init(url: mkvinfo.fileName)
//        try context.findStreamInfo()
//        guard context.streamCount == mkvinfo.tracks.count else {
//            print("ffmpeg and mkvmerge track count mismatch!")
//            throw RemuxerError.errorReadingFile
//        }
        
        let preferedLanguages = config.language.generatePrimaryLanguages(with: mkvinfo.primaryLanguages)
//        let streams = context.streams
        let tracks = mkvinfo.tracks
        var flacConverters = [FlacEncoder]()
        var ffmpegArguments = ["-v", "quiet", "-nostdin", "-y", "-i", mkvinfo.fileName, "-vn"]
        var trackModifications = [TrackModification].init(repeating: .copy(type: .video), count: tracks.count)
        
        defer {
            display(modiifcations: trackModifications)
        }
        
        // check track one by one
        print("Checking tracks codec")
        var index = 0
        let baseFilename = URL(fileURLWithPath:  mkvinfo.fileName).lastPathComponentWithoutExtension
        
        while index < tracks.count {
            let track = tracks[index]
            let trackLanguage = track.properties.language ?? "und"
            print("\(index): \(track.codec) \(track.isLosslessAudio ? "lossless" : "lossy") \(trackLanguage) \(track.properties.audioChannels ?? 0)ch")
            if preferedLanguages.contains(trackLanguage) {
                if track.isTrueHD, config.keepTrueHD {
                    trackModifications[index] = .copy(type: track.type)
                } else if track.isLosslessAudio {
                    // add to ffmpeg arguments
                    let tempFlac = temporaryPath.appendingPathComponent("\(baseFilename)-\(index)-\(trackLanguage)-ffmpeg.flac")
                    let finalFlac = temporaryPath.appendingPathComponent("\(baseFilename)-\(index)-\(trackLanguage).flac")
                    ffmpegArguments.append(contentsOf: ["-map", "0:\(index)", tempFlac.path])
                    var flac = FlacEncoder(input: tempFlac.path, output: finalFlac.path)
                    flac.level = 8
                    flac.forceOverwrite = true
                    flac.silent = true
                    flacConverters.append(flac)
                    
                    trackModifications[index] = .replace(type: .audio, file: finalFlac, lang: trackLanguage, trackName: track.properties.trackName ?? "")
                } else {
                    trackModifications[index] = .copy(type: track.type)
                }
            } else {
                trackModifications[index] = .remove(type: track.type)
            }

            // handle truehd
            if track.isTrueHD, index+1<tracks.count,
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

        try MediaTools.ffmpeg.executable(ffmpegArguments).runAndWait(checkNonZeroExitCode: true, beforeRun: beforeRun(p:), afterRun: afterRun(p:))
        
        flacConverters.forEach { (flac) in
            let process = try! flac.convert()
            process.terminationHandler = { p in
                if p.terminationStatus != 0 {
                    print("error while converting flac \(flac.input)")
                }
                try? flac.inputPaths.forEach(_fm.removeItem(at:))
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
        
        return trackModifications
    }
    
}

enum TrackModification {
    
    case copy(type: TrackType)
    case replace(type: TrackType, file: URL, lang: String, trackName: String)
    case remove(type: TrackType)
    
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
    let rootPath: URL
    let mode: MplsRemuxMode
//    let configuration: RemuxerArgument
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
                    let parsedMpls = try mplsParse(path: mpls.fileName.path)
                    let chapter = parsedMpls.convert()
                    let chapterFile = temporaryPath.appendingPathComponent("\(mpls.fileName.lastPathComponentWithoutExtension).txt")
                    let chapterPath: String?
                    if chapter.isValid {
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
                        let joinWorker = Mkvmerge(global: .init(quiet: true, chapterFile: chapterPath), output: output.path, inputs: splitWorkers.enumerated().map {Mkvmerge.Input.init(file: $0.element.outputPath.path, append: $0.offset != 0, options: [.audioTracks(.enabledLANGs(preferedLanguages)), .subtitleTracks(.enabledLANGs(preferedLanguages)), .noChapters])})
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

struct WorkTask {
    let input: URL
    let main: Converter
    let chapterSplit: Bool
    let splitWorkers: [Converter]?
    let joinWorker: Converter?
    let canBeIgnored: Bool
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
