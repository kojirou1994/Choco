import Executable
import Foundation
import KwiftUtility
import MediaTools
import MplsParser
import Rainbow
import TrackExtension
import TSCBasic
import URLFileManager

let _fm = URLFileManager.default

public final class BDRemuxer {
  private let config: BDRemuxerConfiguration

  private let allowedExitCodes: [CInt]

  private let audioConvertQueue = OperationQueue()

  private var runningProcess: TSCBasic.Process?

  public init(config: BDRemuxerConfiguration) throws {
    audioConvertQueue.maxConcurrentOperationCount = 4
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

  private func launch(externalExecutable: Executable) throws -> ProcessResult {
    let process = try externalExecutable
      .generateProcess(use: SwiftToolsSupportExecutableLauncher(outputRedirection: .collect))
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

  let verbose = true

  private func launch(externalExecutable: Executable,
                      checkAllowedExitCodes codes: [CInt]) throws {
    if verbose {
      print("Running \(externalExecutable.commandLineArguments)")
    }
    let result = try launch(externalExecutable: externalExecutable)
    switch result.exitStatus {
    case .terminated(code: let code):
      if !codes.contains(code) {
        throw ExecutableError.nonZeroExit(result.exitStatus)
      }
    case .signalled(signal: _):
      throw ExecutableError.nonZeroExit(result.exitStatus)
    }
  }

  private var terminated = false

  public func terminate() {
    terminated = true
    audioConvertQueue.cancelAllOperations()
    runningProcess?.signal(SIGTERM)
    //        do {
    //            try currentTemporaryPath.map { try _fm.removeItem(at: $0) }
    //        } catch {
    //            print("Faield to remove the temp dir at \(currentTemporaryPath!), you can delete it manually")
    //        }
  }

  @usableFromInline
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
            throw ExecutableError.nonZeroExit(result.exitStatus)
          }
          return [task.joinWorker!.outputURL]
        } catch {
          print("Failed to join file, \(error)")
          return splitWorkers.map { $0.outputURL }
        }
      } else {
        throw error
      }
    }

    if _fm.fileExistance(at: task.main.outputURL).exists {
      // output exists
      return [task.main.outputURL]
    } else if task.chapterSplit, let parts = try? _fm.contentsOfDirectory(at: task.main.outputURL.deletingLastPathComponent()).filter({ $0.pathExtension == task.main.outputURL.pathExtension && $0.lastPathComponent.hasPrefix(task.main.outputURL.lastPathComponentWithoutExtension) }) {
      return parts
    } else {
      print("Can't find output file(s).")
      throw BDRemuxerError.noOutputFile(task.main.outputURL)
    }
  }

  func remuxBDMV(at bdmvPath: URL, mode: MplsRemuxMode, temporaryPath: URL) throws -> Summary {
    let startDate = Date()
    var sizeBefore: UInt64 = 0
    var sizeAfter: UInt64 = 0

    let task = BDMVMetadata(rootPath: bdmvPath, mode: mode,// temporaryDirectory: temporaryPath,
                            mainOnly: config.mainTitleOnly, splits: config.splits)
    let finalOutputPath = config.outputRootDirectory.appendingPathComponent(task.getBlurayTitle())
    if _fm.fileExistance(at: finalOutputPath).exists {
      throw BDRemuxerError.outputExist
    }
    let converters: [WorkTask]
    do {
      converters = try task.parse(temporaryDirectory: temporaryPath, language: config.languagePreference)
    } catch {
      throw BDRemuxerError.parseBDMV(error)
    }
    var tempFiles = [URL]()
    for converter in converters {
      tempFiles.append(contentsOf: try recursiveRun(task: converter))
      //            do {
      //            } catch {
      //                throw BDRemuxerError.mplsToMKV(converter, error)
      //            }
    }

    for tempFile in tempFiles {
      let mkvinfo = try readMKV(at: tempFile)

      let duration = Timestamp(ns: UInt64(mkvinfo.container.properties?.duration ?? 0))
      let subFolder: String
      if config.organizeOutput {
        if duration > Timestamp.hour {
          // big
          subFolder = ""
        } else if duration > Timestamp.minute * 10 {
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

      let summary = try _remux(file: tempFile,
                               remuxOutputDir: finalOutputPath.appendingPathComponent(subFolder), temporaryPath: temporaryPath,
                               deleteAfterRemux: true, mkvinfoCache: mkvinfo)

      sizeBefore += summary.sizeBefore
      sizeAfter += summary.sizeAfter
    }
    if config.deleteAfterRemux {
      try? _fm.removeItem(at: bdmvPath)
    }

    return .init(sizeBefore: sizeBefore, sizeAfter: sizeAfter, startDate: startDate, endDate: .init())
  }

  func remuxFile(at path: URL, temporaryPath: URL) throws -> Summary {
    let fileType = _fm.fileExistance(at: path)
    switch fileType {
    case .none:
      throw BDRemuxerError.inputNotExists
    case .directory:
      throw BDRemuxerError.directoryInFileMode
    case .file:
      return try _remux(file: path, remuxOutputDir: config.outputRootDirectory, temporaryPath: temporaryPath, deleteAfterRemux: config.deleteAfterRemux)
    }
  }

  public func run(input: URL) throws -> Summary {
    if terminated {
      throw BDRemuxerError.terminated
    }

    return try self.withTemporaryDirectory { tempDirectory in
      self.currentTemporaryPath = tempDirectory
      defer { self.currentTemporaryPath = nil }
      switch config.mode {
      case .episodes, .movie:
        let mode: MplsRemuxMode = config.mode == .episodes ? .split : .direct
        return try remuxBDMV(at: input, mode: mode, temporaryPath: tempDirectory)
      case .file:
        return try remuxFile(at: input, temporaryPath: tempDirectory)
      }
    }
  }

  var currentTemporaryPath: URL?
}

extension BDRemuxer {

  @usableFromInline
  internal func readMKV(at url: URL) throws -> MkvmergeIdentification {
    try .init(url: url)
  }

  private func _remux(file: URL, remuxOutputDir: URL, temporaryPath: URL,
                      deleteAfterRemux: Bool,
                      parseOnly: Bool = false,
                      mkvinfoCache: MkvmergeIdentification? = nil) throws -> Summary {
    let startDate = Date()
    //        print("Start remuxing file \(file.lastPathComponent)")
    let outputURL = remuxOutputDir
      .appendingPathComponent("\(file.lastPathComponentWithoutExtension).mkv")
    guard !_fm.fileExistance(at: outputURL).exists else {
      //            print("\(outputFilename) already exists!")
      throw BDRemuxerError.outputExist
    }
    let sizeBefore: UInt64
    do {
      sizeBefore = try _fm.attributesOfItem(atURL: file)[.size] as! UInt64
    } catch {
      sizeBefore = 0
    }

    var trackOrder = [Mkvmerge.GlobalOption.TrackOrder]()
    var audioRemovedTrackIndexes = [Int]()
    var videoTrackIndexes = [Int]()
    var subtitleRemoveTracks = [Int]()
    var externalTracks = [(file: URL, lang: String, trackName: String)]()

    let mkvinfo = try mkvinfoCache ?? readMKV(at: file)

    let modifications = try _makeTrackModification(mkvinfo: mkvinfo, temporaryPath: temporaryPath)

    var mainInput = Mkvmerge.Input(file: file.path)

    for modify in modifications.enumerated() {
      switch modify.element {
      case .copy(let type):
        trackOrder.append(.init(fid: 0, tid: modify.offset))
        switch type {
        case .video:
          videoTrackIndexes.append(modify.offset)
        default:
          break
        }
      case .remove(let type):
        switch type {
        case .audio:
          audioRemovedTrackIndexes.append(modify.offset)
        case .subtitles:
          subtitleRemoveTracks.append(modify.offset)
        default:
          break
        }
      case .replace(let type, let files, let lang, let trackName):
        switch type {
        case .audio:
          audioRemovedTrackIndexes.append(modify.offset)
        case .subtitles:
          subtitleRemoveTracks.append(modify.offset)
        default:
          break
        }
        files.forEach { file in
          externalTracks.append((file: file, lang: lang, trackName: trackName))
          trackOrder.append(.init(fid: externalTracks.count, tid: 0))
        }
      }
      if !config.keepTrackName {
        mainInput.options.append(.trackName(tid: modify.offset, name: ""))
      }
    }

    if !config.keepVideoLanguage {
      videoTrackIndexes.forEach { mainInput.options.append(.language(tid: $0, language: "und")) }
    }

    mainInput.options.append(.audioTracks(.disabledTIDs(audioRemovedTrackIndexes)))
    mainInput.options.append(.subtitleTracks(.disabledTIDs(subtitleRemoveTracks)))
    mainInput.options.append(.attachments(.removeAll))

    let externalInputs = externalTracks.map { (track) -> Mkvmerge.Input in
      var options: [Mkvmerge.Input.InputOption] = [.language(tid: 0, language: track.lang)]
      if config.keepTrackName {
        options.append(.trackName(tid: 0, name: track.trackName))
      }
      return .init(file: track.file.path, options: options)
    }
    let splitInfo = generateSplit(splits: config.splits, chapterCount: mkvinfo.chapters.first?.numEntries ?? 0)
    let mkvmerge = Mkvmerge(global: .init(quiet: true, split: splitInfo,
                                          trackOrder: trackOrder),
                            output: outputURL.path, inputs: [mainInput] + externalInputs)
    print("Mkvmerge arguments:\n\(mkvmerge.arguments.joined(separator: " "))")

    print("\nMkvmerge:\n\(file)\n->\n\(outputURL)")
    do {
      try launch(externalExecutable: mkvmerge, checkAllowedExitCodes: allowedExitCodes)
    } catch {
      throw BDRemuxerError.mkvmergeMux(error)
    }

    externalTracks.forEach { t in
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

    let sizeAfter = (try? _fm.attributesOfItem(atURL: outputURL)[.size] as? UInt64) ?? 0

    return .init(sizeBefore: sizeBefore, sizeAfter: sizeAfter, startDate: startDate, endDate: .init())
  }
}

// MARK: - Utilities

extension BDRemuxer {
  @usableFromInline
  internal func withTemporaryDirectory<T>(_ body: (URL) throws -> T) throws -> T {
    let uniqueTempDirectory = config.temperoraryDirectory.appendingPathComponent(UUID().uuidString)
    try _fm.createDirectory(at: uniqueTempDirectory)
    defer {
      do {
        try _fm.removeItem(at: uniqueTempDirectory)
      } catch {
        print("cannot create/remove temp directory: \(uniqueTempDirectory.path)")
        print(error)
      }
    }
    return try body(uniqueTempDirectory)
  }

  private func display(modiifcations: [TrackModification]) {
    print("Track modifications: ")
    for m in modiifcations.enumerated() {
      print("\(m.offset): \(m.element)")
    }
  }

  private func _makeTrackModification(mkvinfo: MkvmergeIdentification,
                                      temporaryPath: URL) throws -> [TrackModification] {
    let preferedLanguages = config.languagePreference.generatePrimaryLanguages(with: mkvinfo.primaryLanguages)
    let tracks = mkvinfo.tracks
    var audioConverters = [AudioConverter]()
    var ffmpegArguments = ["-v", "quiet", "-nostdin", "-y", "-i", mkvinfo.fileName, "-vn"]
    var trackModifications = [TrackModification](repeating: .copy(type: .video), count: tracks.count)

    defer {
      display(modiifcations: trackModifications)
    }

    // check track one by one
    print("Checking tracks codec")
    var currentTrackIndex = 0
    let baseFilename = URL(fileURLWithPath: mkvinfo.fileName).lastPathComponentWithoutExtension

    while currentTrackIndex < tracks.count {
      let currentTrack = tracks[currentTrackIndex]
      let trackLanguage = currentTrack.properties.language ?? "und"
      print(currentTrack.remuxerInfo)
      var embbedAC3Removed = false
      if preferedLanguages.contains(trackLanguage) {
        var trackDone = false
        // keep true-hd
        if currentTrack.isTrueHD, config.keepTrueHD {
          trackModifications[currentTrackIndex] = .copy(type: currentTrack.type)
          trackDone = true
        }
        // remove same spec dts-hd
        if !trackDone, config.removeExtraDTS, currentTrack.isDTSHD {
          var fixed = false
          if case let indexBefore = currentTrackIndex - 1, indexBefore >= 0 {
            let compareTrack = tracks[indexBefore]
            if compareTrack.isTrueHD,
               compareTrack.properties.language == currentTrack.properties.language,
               compareTrack.properties.audioChannels == currentTrack.properties.audioChannels {
              trackModifications[currentTrackIndex] = .remove(type: .audio)
              fixed = true
              // remove the ac3 after
              if !embbedAC3Removed, currentTrackIndex + 1 < tracks.count,
                 case let nextTrack = tracks[currentTrackIndex + 1],
                 nextTrack.isAC3, nextTrack.properties.language == currentTrack.properties.language {
                // Remove TRUEHD embed-in AC-3 track
                trackModifications[currentTrackIndex + 1] = .remove(type: .audio)
                currentTrackIndex += 1
                embbedAC3Removed = true
              }
            }
          }
          if !fixed, case let indexAfter = currentTrackIndex + 1, indexAfter < tracks.count {
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

        // keep flac
        if !trackDone && currentTrack.isFlac && config.keepFlac {
          trackModifications[currentTrackIndex] = .copy(type: currentTrack.type)
          trackDone = true
        }

        // lossless audio -> flac, or fix garbage dts
        if !trackDone && (currentTrack.isLosslessAudio || (config.fixDTS && currentTrack.isGarbageDTS)) {
          // add to ffmpeg arguments
          let tempFFmpegOutputFlac = temporaryPath.appendingPathComponent("\(baseFilename)-\(currentTrackIndex)-\(trackLanguage)-ffmpeg.flac")
          let finalOutputAudioTrack = temporaryPath.appendingPathComponent("\(baseFilename)-\(currentTrackIndex)-\(trackLanguage).\(config.audioPreference.codec.outputFileExtension)")
          ffmpegArguments.append(contentsOf: ["-map", "0:\(currentTrackIndex)", tempFFmpegOutputFlac.path])

          audioConverters.append(.init(input: tempFFmpegOutputFlac, output: finalOutputAudioTrack, preference: config.audioPreference, channelCount: currentTrack.properties.audioChannels!, trackIndex: currentTrackIndex))

          var replaceFiles = [finalOutputAudioTrack]
          // Optionally down mix
          if config.audioPreference.generateStereo, currentTrack.properties.audioChannels! > 2 {
            let tempFFmpegMixdownFlac = temporaryPath.appendingPathComponent("\(baseFilename)-\(currentTrackIndex)-\(trackLanguage)-ffmpeg-downmix.flac")
            let finalDownmixAudioTrack = temporaryPath.appendingPathComponent("\(baseFilename)-\(currentTrackIndex)-\(trackLanguage)-downmix.\(config.audioPreference.codec.outputFileExtension)")
            ffmpegArguments.append(contentsOf: ["-map", "0:\(currentTrackIndex)", "-ac", "2", tempFFmpegMixdownFlac.path])

            audioConverters.append(.init(input: tempFFmpegMixdownFlac, output: finalDownmixAudioTrack, preference: config.audioPreference, channelCount: 2, trackIndex: currentTrackIndex))
            replaceFiles.insert(finalDownmixAudioTrack, at: 0)
          }

          trackModifications[currentTrackIndex] = .replace(type: .audio, files: replaceFiles, lang: trackLanguage, trackName: currentTrack.properties.trackName ?? "")
          trackDone = true
        }

        if !trackDone {
          trackModifications[currentTrackIndex] = .copy(type: currentTrack.type)
        }
      } else {
        trackModifications[currentTrackIndex] = .remove(type: currentTrack.type)
      }

      // handle truehd
      if !embbedAC3Removed, currentTrack.isTrueHD, currentTrackIndex + 1 < tracks.count,
         case let nextTrack = tracks[currentTrackIndex + 1],
         nextTrack.isAC3 {
        // Remove TRUEHD embed-in AC-3 track
        trackModifications[currentTrackIndex + 1] = .remove(type: .audio)
        currentTrackIndex += 1
      }
      currentTrackIndex += 1
    }

    if audioConverters.isEmpty {
      return trackModifications
    }

    print("ffmpeg \(ffmpegArguments.joined(separator: " "))")

    // file's audio tracks -> external temp flac
    try launch(externalExecutable: MediaTools.ffmpeg.executable(ffmpegArguments),
               checkAllowedExitCodes: [0])

    // check duplicate audio track
    let tempFFmpegFlacFiles = audioConverters.map { $0.input }
    let flacMD5s: [String]
    do {
      flacMD5s = try FlacMD5.calculate(inputs: tempFFmpegFlacFiles.map { $0.path })
    } catch {
      throw BDRemuxerError.validateFlacMD5(error)
    }
    precondition(tempFFmpegFlacFiles.count == flacMD5s.count, "Flac MD5 count dont match")

    // verify duplicate audios
    let md5Set = Set(flacMD5s)
    if md5Set.count < flacMD5s.count {
      print("Has duplicate tracks")

      // remove extra duplicate tracks
      for md5 in md5Set {
        let indexes = flacMD5s.indexes(of: md5)
        precondition(indexes.count > 0)
        if indexes.count > 1 {
          indexes.dropFirst().forEach { trackModifications[audioConverters[$0].trackIndex].remove() }
        }
      }

    }

    // external temp flac -> final audio tracks
    audioConverters.forEach { converter in
      self.logConverterStart(name: converter.executableName, input: converter.input.path, output: converter.output.path)

      let operation = AudioConvertOperation(converter: converter) { error in
        print("Audio convert error: \(error)")
      }

      audioConvertQueue.addOperation(operation)
    }
    audioConvertQueue.waitUntilAllOperationsAreFinished()
    if terminated {
      throw BDRemuxerError.terminated
    }

    return trackModifications
  }
}

enum TrackModification: CustomStringConvertible {
  case copy(type: MediaTrackType)
  case replace(type: MediaTrackType, files: [URL], lang: String, trackName: String)
  case remove(type: MediaTrackType)

  mutating func remove() {
    switch self {
    case .replace(type: let type, files: let files, lang: _, trackName: _):
      files.forEach{ try? _fm.removeItem(at: $0) }
      self = .remove(type: type)
    case .copy(type: let type):
      self = .remove(type: type)
    case .remove(type: _):
      return
    }
  }

  var type: MediaTrackType {
    switch self {
    case .replace(type: let type, files: _, lang: _, trackName: _):
      return type
    case .copy(type: let type):
      return type
    case .remove(type: let type):
      return type
    }
  }

  var description: String {
    switch self {
    case .replace(type: let type, files: let files, lang: let lang, trackName: let trackName):
      return "replace(type: \(type), files: \(files.map(\.path)), lang: \(lang), trackName: \(trackName))"
    case .copy(type: let type):
      return "copy(type: \(type))"
    case .remove(type: let type):
      return "remove(type: \(type))"
    }
  }
}

public struct BDMVMetadata {
  public init(rootPath: URL, mode: MplsRemuxMode, mainOnly: Bool,
              //                language: BDRemuxerConfiguration.LanguagePreference,
              splits: [Int]?) {
    self.rootPath = rootPath
    self.mode = mode
    self.mainOnly = mainOnly
    //        self.language = language
    self.splits = splits
  }

  let rootPath: URL
  let mode: MplsRemuxMode
  //    let temporaryDirectory: URL
  let mainOnly: Bool
  //    let language: BDRemuxerConfiguration.LanguagePreference
  let splits: [Int]?

  public func parse(temporaryDirectory: URL, language: BDRemuxerConfiguration.LanguagePreference) throws -> [BDRemuxer.WorkTask] {
    let mplsList = try scan(removeDuplicate: true)

    // TODO: check conflict

    var tasks = [BDRemuxer.WorkTask]()

    if mode == .split {
      var allFiles = Set(mplsList.flatMap { $0.files })
      try mplsList.forEach { mpls in
        tasks.append(contentsOf: try split(mpls: mpls, restFiles: allFiles, temporaryDirectory: temporaryDirectory, language: language))
        mpls.files.forEach { usedFile in
          allFiles.remove(usedFile)
        }
      }
    } else if mode == .direct {
      try mplsList.forEach { mpls in
        if mpls.useFFmpeg || mpls.compressed { /* || mpls.remuxMode == .split*/
          tasks.append(contentsOf: try split(mpls: mpls, temporaryDirectory: temporaryDirectory, language: language))
        } else {
          let preferedLanguages = language.generatePrimaryLanguages(with: [mpls.primaryLanguage])
          let outputFilename = generateFilename(mpls: mpls)
          let output = temporaryDirectory.appendingPathComponent(outputFilename + ".mkv")
          let parsedMpls = try MplsPlaylist.parse(mplsURL: mpls.fileName)
          let chapter = parsedMpls.convert()
          let chapterFile = temporaryDirectory.appendingPathComponent("\(mpls.fileName.lastPathComponentWithoutExtension).txt")
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
            let splitWorkers = try split(mpls: mpls, temporaryDirectory: temporaryDirectory, language: language).map { $0.main }
            let main = Mkvmerge(global: .init(quiet: true, chapterFile: chapterPath), output: output.path, inputs: mpls.files.enumerated().map { Mkvmerge.Input(file: $0.element.path, append: $0.offset != 0, options: [.audioTracks(.enabledLANGs(preferedLanguages)), .subtitleTracks(.enabledLANGs(preferedLanguages))]) })
            let joinWorker = Mkvmerge(global: .init(quiet: true, chapterFile: chapterPath), output: output.path, inputs: splitWorkers.enumerated().map { Mkvmerge.Input(file: $0.element.outputURL.path, append: $0.offset != 0, options: [.audioTracks(.enabledLANGs(preferedLanguages)), .subtitleTracks(.enabledLANGs(preferedLanguages)), .noChapters]) })
            tasks.append(.init(input: mpls.fileName,
                               main: main, chapterSplit: false,
                               splitWorkers: splitWorkers, joinWorker: joinWorker))
          }
        }
      }
    }

    return tasks
  }

  public func dumpInfo() throws {
    print("Blu-ray title: \(getBlurayTitle())")
    let mplsList = try scan(removeDuplicate: true)
    print("MPLS List:\n")
    mplsList.forEach { print($0); print() }
  }

  @usableFromInline
  func getBlurayTitle() -> String {
    rootPath.lastPathComponent.safeFilename().trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func scan(removeDuplicate: Bool) throws -> [Mpls] {
    print("Start scanning BD folder: \(rootPath.path)")
    let playlistPath = rootPath.appendingPathComponent("BDMV/PLAYLIST", isDirectory: true)

    if mainOnly {
      let index = try getMainPlaylist(at: rootPath.path)
      let url = playlistPath.appendingPathComponent("\(String(format: "%05d", index)).mpls")
      return [try Mpls(filePath: url.path)]
    }

    if _fm.fileExistance(at: playlistPath) == .directory {
      let mplsPaths = try _fm.contentsOfDirectory(at: playlistPath).filter { $0.pathExtension.lowercased() == "mpls" }
      if mplsPaths.isEmpty {
        throw BDRemuxerError.noPlaylists
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
        let multipleFileMpls = allMpls.filter { !$0.isSingle }.duplicateRemoved
        let singleFileMpls = allMpls.filter { $0.isSingle }.duplicateRemoved
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
            cleanSingleFileMpls.contains(where: { (mpls) -> Bool in
              mpls.files[0] == file
            })
          }) {
            cleanSingleFileMpls.removeAll(where: { multipleMpls.files.contains($0.files[0]) })
          }
        }
        return (multipleFileMpls + cleanSingleFileMpls).sorted()
      } else {
        return allMpls
      }
    } else {
      print("No PLAYLIST Folder!")
      throw BDRemuxerError.noPlaylists
    }
  }

  private func split(mpls: Mpls, temporaryDirectory: URL, language: BDRemuxerConfiguration.LanguagePreference) throws -> [BDRemuxer.WorkTask] {
    try split(mpls: mpls, restFiles: Set(mpls.files), temporaryDirectory: temporaryDirectory, language: language)
  }

  private func split(mpls: Mpls, restFiles: Set<URL>, temporaryDirectory: URL, language: BDRemuxerConfiguration.LanguagePreference) throws -> [BDRemuxer.WorkTask] {
    print("Splitting MPLS: \(mpls.fileName)")

    if restFiles.count == 0 {
      return []
    }

    let clips = try mpls.split(chapterPath: temporaryDirectory)
    let preferedLanguages = language.generatePrimaryLanguages(with: [mpls.primaryLanguage])

    return clips.flatMap { (clip) -> [BDRemuxer.WorkTask] in
      if restFiles.contains(clip.m2tsPath) {
        let output: URL
        let outputBasename = "\(mpls.fileName.lastPathComponentWithoutExtension)-\(clip.baseFilename)"
        if mpls.useFFmpeg {
          return [
            .init(input: clip.fileName,
                  main: FFmpegMuxer(input: clip.m2tsPath.path,
                                    output: temporaryDirectory.appendingPathComponent("\(outputBasename)-ffmpeg-video.mkv").path,
                                    mode: .videoOnly), chapterSplit: false, canBeIgnored: true),
            .init(input: clip.fileName,
                  main: FFmpegMuxer(input: clip.m2tsPath.path,
                                    output: temporaryDirectory.appendingPathComponent("\(outputBasename)-ffmpeg-audio.mkv").path, mode: .audioOnly), chapterSplit: false, canBeIgnored: true)
          ]
        } else {
          let outputFilename = "\(outputBasename).mkv"
          output = temporaryDirectory.appendingPathComponent(outputFilename)
          return [.init(input: clip.fileName, main: Mkvmerge(global: .init(quiet: true, chapterFile: clip.chapterPath?.path), output: output.path, inputs: [.init(file: clip.m2tsPath.path, options: [.audioTracks(.enabledLANGs(preferedLanguages)), .subtitleTracks(.enabledLANGs(preferedLanguages))])]), chapterSplit: false, canBeIgnored: false)]
        }

      } else {
        print("Skipping clip: \(clip)")
        return []
      }
    }
  }

  private func generateFilename(mpls: Mpls) -> String {
    return "\(mpls.fileName.lastPathComponentWithoutExtension)-\(mpls.files.map { $0.lastPathComponentWithoutExtension }.joined(separator: "+").prefix(200))"
  }
}

fileprivate func generateSplit(splits: [Int]?, chapterCount: Int) -> Mkvmerge.GlobalOption.Split? {
  guard let splits = splits, splits.count > 0 else {
    return nil
  }
  let totalChaps = splits.reduce(0, +)
  if totalChaps == chapterCount {
    var chapIndex = [Int]()
    var chapCount = 0
    splits.forEach { chap in
      chapIndex.append(chap + 1 + chapCount)
      chapCount += chap
    }
    return .chapters(.numbers(chapIndex.dropLast()))
  } else {
    return nil
  }
}

// struct SubTask {
//    let main: Converter
//    let alternatives: [SubTask]?
////    let size: Int
// }
extension BDRemuxer {
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
}


