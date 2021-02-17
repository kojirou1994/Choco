import ExecutableLauncher
import Foundation
import KwiftUtility
import MediaTools
import MplsParser
import Rainbow
import TSCBasic
import URLFileManager
import Logging

let _fm = URLFileManager.default

public final class ChocoMuxer {
  private let config: ChocoConfiguration

  private let ffmpegCodecs: FFmpegCodecs

  struct FFmpegCodecs {
    let x265: Bool
    let x264: Bool
    let fdkAAC: Bool
    let libopus: Bool
    let vapoursynth: Bool

    init() throws {
      let options = try FFmpeg(arguments: [])
        .launch(use: TSCExecutableLauncher(outputRedirection: .collect), options: .init(checkNonZeroExitCode: false))
        .utf8stderrOutput()
      x265 = options.contains("--enable-libx265")
      x264 = options.contains("--enable-libx264")
      fdkAAC = options.contains("--enable-libfdk-aac")
      libopus = options.contains("--enable-libopus")
      vapoursynth = options.contains("--enable-vapoursynth")
    }
  }

  private func checkCodecs() throws {
    if config.videoPreference.videoProcess == .encode {
      switch config.videoPreference.codec {
      case .x264:
        try preconditionOrThrow(ffmpegCodecs.x264, "no x264!")
      case .x265:
        try preconditionOrThrow(ffmpegCodecs.x265, "no x265!")
      }
      if config.videoPreference.encodeScript != nil {
        try preconditionOrThrow(ffmpegCodecs.vapoursynth, "no vapoursynth!")
      }
    }
  }

  private let allowedExitCodes: [CInt]

  private let audioConvertQueue = OperationQueue()

  private var runningProcessID: Int32?

  let logger: Logger

  public init(config: ChocoConfiguration, logger: Logger) throws {
    audioConvertQueue.maxConcurrentOperationCount = ProcessInfo.processInfo.processorCount
    self.config = config
    self.logger = logger
    if self.config.ignoreWarning {
      self.allowedExitCodes = [0, 1]
    } else {
      self.allowedExitCodes = [0]
    }
    // check ffmpeg codecs
    ffmpegCodecs = try .init()
    logger.info("FFmpeg codecs: \(ffmpegCodecs)")
    try checkCodecs()
  }

  private func launch<E: Executable>(externalExecutable: E) throws -> ProcessResult {
    let process = try externalExecutable
      .generateProcess(use: TSCExecutableLauncher(outputRedirection: .collect))
    try process.launch()
    runningProcessID = process.processID
    defer {
      runningProcessID = nil
    }
    let result = try process.waitUntilExit()
    return result
  }

  let verbose = true

  private func launch<E: Executable>(externalExecutable: E,
                      checkAllowedExitCodes codes: [CInt]) throws {
    logger.debug("Running \(externalExecutable.commandLineArguments)")
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
    runningProcessID.map { _ = kill($0, SIGTERM) }
    runningProcessID = nil
  }

  func logConverterStart(name: String, input: String, output: String) {
    logger.info("\n\(name):\n\(input)\n->\n\(output)")
  }

  func recursiveRun(task: WorkTask) throws -> [URL] {
    do {
      logConverterStart(name: task.main.executable.executableName,
                        input: task.main.inputDescription,
                        output: task.main.outputURL.path)
      try launch(externalExecutable: task.main.executable, checkAllowedExitCodes: allowedExitCodes)
    } catch {
      if task.canBeIgnored {
        return []
      }
      if let splitWorkers = task.splitWorkers {
        for splitWorker in splitWorkers {
          try launch(externalExecutable: splitWorker.executable, checkAllowedExitCodes: allowedExitCodes)
        }
        do {
          let result = try launch(externalExecutable: task.joinWorker!.executable)
          if result.exitStatus == .terminated(code: 2) {
            throw ExecutableError.nonZeroExit(result.exitStatus)
          }
          return [task.joinWorker!.outputURL]
        } catch {
          logger.error("Failed to join the splitted files, the file will be splitted.")
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
      logger.error("Necessary files are missing: \(task.main.outputURL.path).")
      throw ChocoError.noOutputFile(task.main.outputURL)
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
      throw ChocoError.outputExist
    }
    let converters: [WorkTask]
    do {
      converters = try task.parse(temporaryDirectory: temporaryPath, language: config.languagePreference)
    } catch {
      throw ChocoError.parseBDMV(error)
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
                               outputDirectoryURL: finalOutputPath.appendingPathComponent(subFolder), temporaryPath: temporaryPath,
                               deleteAfterRemux: true, mkvinfoCache: mkvinfo)

      sizeBefore += summary.sizeBefore
      sizeAfter += summary.sizeAfter
    }
    if config.deleteAfterRemux {
      try? _fm.removeItem(at: bdmvPath)
    }

    return .init(sizeBefore: sizeBefore, sizeAfter: sizeAfter, startDate: startDate, endDate: .init())
  }

  func remuxFile(at path: URL, outputDirectoryURL: URL, temporaryPath: URL) throws -> Summary {
    let fileType = _fm.fileExistance(at: path)
    switch fileType {
    case .none:
      throw ChocoError.inputNotExists
    case .directory:
      throw ChocoError.directoryInFileMode
    case .file:
      return try _remux(file: path, outputDirectoryURL: outputDirectoryURL, temporaryPath: temporaryPath, deleteAfterRemux: config.deleteAfterRemux)
    }
  }

  public func run(input: URL) throws -> Summary {
    if terminated {
      throw ChocoError.terminated
    }

    switch config.mode {
    case .episodes, .movie:
      return try withTemporaryDirectory { tempDirectory in
        let mode: MplsRemuxMode = config.mode == .episodes ? .split : .direct
        return try remuxBDMV(at: input, mode: mode, temporaryPath: tempDirectory)
      }
    case .file:
      return try withTemporaryDirectory { tempDirectory in
        try remuxFile(at: input, outputDirectoryURL: config.outputRootDirectory, temporaryPath: tempDirectory)
      }
    case .directory:
      try preconditionOrThrow(_fm.fileExistance(at: input) == .directory)

      let startDate = Date()
      var sizeBefore: UInt64 = 0
      var sizeAfter: UInt64 = 0

      let inputPrefix = input.path
      let dirName = input.lastPathComponent

      let succ = _fm.forEachContent(in: input, handleFile: true, handleDirectory: false, skipHiddenFiles: false) { fileURL in
        guard !terminated else {
          return
        }
        let fileDirPath = fileURL.deletingLastPathComponent().path
        guard fileDirPath.hasPrefix(inputPrefix) else {
          logger.error("Path handling incorrect")
          return
        }
        let outputDirectoryURL = config.outputRootDirectory
          .appendingPathComponent(dirName)
          .appendingPathComponent(String(fileDirPath.dropFirst(inputPrefix.count)))

        do {
          switch fileURL.pathExtension.lowercased() {
          case "mkv", "mp4", "ts", "m2ts", "vob":
            // remux
            try self.withTemporaryDirectory { tempDirectory in
              let subSummary = try remuxFile(at: fileURL, outputDirectoryURL: outputDirectoryURL, temporaryPath: tempDirectory)
              sizeBefore += subSummary.sizeBefore
              sizeAfter += subSummary.sizeAfter
            }
          default:
          // copy
            if config.copyDirectoryFile {
              try _fm.createDirectory(at: outputDirectoryURL)
              try _fm.copyItem(at: fileURL, to: outputDirectoryURL.appendingPathComponent(fileURL.lastPathComponent))
            }
          }
        } catch {
          logger.error("Error processing file: \(error)")
        }
      }
      try preconditionOrThrow(succ, "Cannot read dir")

      return .init(sizeBefore: sizeBefore, sizeAfter: sizeAfter,
                   startDate: startDate, endDate: .init())
    }
  }

  var currentTemporaryPath: URL?
}

extension ChocoMuxer {

  @usableFromInline
  internal func readMKV(at url: URL) throws -> MkvMergeIdentification {
    try .init(url: url)
  }

  private func _remux(file: URL, outputDirectoryURL: URL, temporaryPath: URL,
                      deleteAfterRemux: Bool,
                      parseOnly: Bool = false,
                      mkvinfoCache: MkvMergeIdentification? = nil) throws -> Summary {
    let startDate = Date()
    let outputURL = outputDirectoryURL
      .appendingPathComponent("\(file.lastPathComponentWithoutExtension).mkv")
    guard !_fm.fileExistance(at: outputURL).exists else {
      throw ChocoError.outputExist
    }
    let sizeBefore: UInt64
    do {
      sizeBefore = try _fm.attributesOfItem(atURL: file)[.size] as! UInt64
    } catch {
      sizeBefore = 0
    }

    let mkvinfo = try mkvinfoCache ?? readMKV(at: file)
    let modifications = try _makeTrackModification(mkvinfo: mkvinfo, temporaryPath: temporaryPath)

    var trackOrder = [MkvMerge.GlobalOption.TrackOrder]()
    var videoRemovedTrackIndexes = [Int]()
    var audioRemovedTrackIndexes = [Int]()
    var subtitleRemoveTracks = [Int]()
    /// copied video tracks
    var videoCopiedTrackIndexes = [Int]()
    var externalTracks = [(file: URL, lang: String, trackName: String)]()


    var mainInput = MkvMerge.Input(file: file.path)

    for modify in modifications.enumerated() {
      switch modify.element {
      case .copy(let type):
        trackOrder.append(.init(fid: 0, tid: modify.offset))
        switch type {
        case .video:
          videoCopiedTrackIndexes.append(modify.offset)
        default:
          break
        }
      case .remove(let type):
        switch type {
        case .audio:
          audioRemovedTrackIndexes.append(modify.offset)
        case .subtitles:
          subtitleRemoveTracks.append(modify.offset)
        case .video:
          videoRemovedTrackIndexes.append(modify.offset)
        }
      case .replace(let type, let files, let lang, let trackName):
        switch type {
        case .audio:
          audioRemovedTrackIndexes.append(modify.offset)
        case .subtitles:
          subtitleRemoveTracks.append(modify.offset)
        case .video:
          videoRemovedTrackIndexes.append(modify.offset)
        }
        files.forEach { file in
          externalTracks.append((file: file, lang: lang, trackName: trackName))
          trackOrder.append(.init(fid: externalTracks.count, tid: 0))
        }
      }

      switch modify.element {
      case .copy, .replace:
        if !config.keepTrackName {
          mainInput.options.append(.trackName(tid: modify.offset, name: ""))
        }
      default: break
      }
    }

    if !config.keepVideoLanguage {
      videoCopiedTrackIndexes.forEach { mainInput.options.append(.language(tid: $0, language: "und")) }
    }


    func correctTrackSelection(type: MediaTrackType, removedIndexes: [Int]) -> MkvMerge.Input.InputOption.TrackSelect {
      if mkvinfo.tracks.count(where: {$0.type == type}) == removedIndexes.count {
        return .removeAll
      } else {
        return .disabledTIDs(removedIndexes)
      }
    }

    mainInput.options.append(.videoTracks(correctTrackSelection(type: .video, removedIndexes: videoRemovedTrackIndexes)))
    mainInput.options.append(.audioTracks(correctTrackSelection(type: .video, removedIndexes: audioRemovedTrackIndexes)))
    mainInput.options.append(.subtitleTracks(correctTrackSelection(type: .video, removedIndexes: subtitleRemoveTracks)))
    mainInput.options.append(.attachments(.removeAll))

    let externalInputs = externalTracks.map { (track) -> MkvMerge.Input in
      var options: [MkvMerge.Input.InputOption] = [.language(tid: 0, language: track.lang)]
      options.append(.trackName(tid: 0, name: config.keepTrackName ? track.trackName : ""))
      options.append(.noGlobalTags)
      options.append(.noChapters)
      options.append(.trackTags(.removeAll))
      return .init(file: track.file.path, options: options)
    }
    let splitInfo = generateSplit(splits: config.splits, chapterCount: mkvinfo.chapters.first?.numEntries ?? 0)
    let mkvmerge = MkvMerge(
      global: .init(quiet: true, split: splitInfo, trackOrder: trackOrder),
      output: outputURL.path, inputs: [mainInput] + externalInputs)
    logger.debug("\(mkvmerge.commandLineArguments.joined(separator: " "))")

    logger.info("Mkvmerge: \(file) -------> \(outputURL)")
    do {
      try launch(externalExecutable: mkvmerge, checkAllowedExitCodes: allowedExitCodes)
    } catch {
      throw ChocoError.mkvmergeMux(error)
    }

    externalTracks.forEach { t in
      do {
        try _fm.removeItem(at: t.file)
      } catch {
        logger.warning("Can not delete temp file: \(t.file)")
      }
    }

    if deleteAfterRemux {
      do {
        try _fm.removeItem(at: file)
      } catch {
        logger.warning("Can not delete original file: \(file)")
      }
    }

    let sizeAfter = (try? _fm.attributesOfItem(atURL: outputURL)[.size] as? UInt64) ?? 0

    return .init(sizeBefore: sizeBefore, sizeAfter: sizeAfter, startDate: startDate, endDate: .init())
  }
}

// MARK: - Utilities

extension ChocoMuxer {

  private func withTemporaryDirectory<T>(_ body: (URL) throws -> T) throws -> T {
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
    self.currentTemporaryPath = uniqueTempDirectory
    defer { self.currentTemporaryPath = nil }
    return try body(uniqueTempDirectory)
  }

  private func display(modiifcations: [TrackModification]) {
    print("Track modifications: ")
    for m in modiifcations.enumerated() {
      print("\(m.offset): \(m.element)")
    }
  }

  private func _makeTrackModification(mkvinfo: MkvMergeIdentification,
                                      temporaryPath: URL) throws -> [TrackModification] {
    let preferedLanguages = config.languagePreference.generatePrimaryLanguages(with: mkvinfo.primaryLanguages)
    let tracks = mkvinfo.tracks
    var audioConverters = [AudioConverter]()
    var ffmpegArguments = ["-v", "quiet", "-y", "-i", mkvinfo.fileName]
    let defaultFFmpegArgumentsCount = ffmpegArguments.count
    var trackModifications = [TrackModification](repeating: .copy(type: .video), count: tracks.count)

    defer {
      display(modiifcations: trackModifications)
    }

    // check track one by one
    logger.info("Checking tracks codec")
    var currentTrackIndex = 0
    let baseFilename = URL(fileURLWithPath: mkvinfo.fileName).lastPathComponentWithoutExtension

    while currentTrackIndex < tracks.count {
      let currentTrack = tracks[currentTrackIndex]
      let trackLanguage = currentTrack.properties.language ?? "und"
      print(currentTrack.remuxerInfo)
      switch currentTrack.type {
      case .video:
        switch config.videoPreference.videoProcess {
        case .encode:
          let encodedTrackFile = temporaryPath.appendingPathComponent("\(baseFilename)-\(currentTrackIndex)-\(trackLanguage)-encoded.mkv")

          let commonArguments = [
            "-c:v", "lib\(config.videoPreference.codec.rawValue)",
            "-pix_fmt", config.videoPreference.codec.pixelFormat,
            "-crf", "\(config.videoPreference.crf)",
            "-preset", config.videoPreference.preset.rawValue
          ]
          if let encodeScript = config.videoPreference.encodeScript {
            // use script template
            let script = try generateScript(filePath: mkvinfo.fileName, encodeScript: encodeScript)
            let scriptFileURL = temporaryPath.appendingPathComponent("\(baseFilename)-\(currentTrackIndex)-generated_script.py")
            try script.write(to: scriptFileURL, atomically: true, encoding: .utf8)

            let vspipe = AnyExecutable(executableName: "vspipe", arguments: ["-y", scriptFileURL.path, "-"])
            var ffmpeg = AnyExecutable(executableName: "ffmpeg",
                                       arguments: [
                                        //                                        "-nostdin",
                                        "-i", "pipe:"
                                       ])
            ffmpeg.arguments.append(contentsOf: commonArguments)
            ffmpeg.arguments.append(encodedTrackFile.path)
            let pipe = Pipe()
            let vsLauncher = FPExecutableLauncher(standardOutput: .pipe(pipe))
            let ffLauncher = FPExecutableLauncher(standardInput: .pipe(pipe))
            let vsProcess = try vspipe.generateProcess(use: vsLauncher)
            let ffProcess = try ffmpeg.generateProcess(use: ffLauncher)

            vsProcess.launch()
            ffProcess.launch()

            runningProcessID = vsProcess.processIdentifier
            defer {
              runningProcessID = nil
            }

            vsProcess.waitUntilExit()
            ffProcess.waitUntilExit()
          } else {
            // encode use ffmpeg
            ffmpegArguments.append(contentsOf: ["-map", "0:\(currentTrackIndex)"])
            ffmpegArguments.append(contentsOf: commonArguments)
            // autocrop
            if config.videoPreference.autoCrop {
              logger.info("Calculating crop info..")
              let cropInfo = try calculateAutoCrop(at: mkvinfo.fileName, previews: 100, tempFile: temporaryPath.appendingPathComponent("\(UUID()).mkv"))
              logger.info("Calculated: \(cropInfo)")
              ffmpegArguments.append("-vf")
              ffmpegArguments.append(cropInfo.ffmpegArgument)
            } // auto crop end
            // output
            ffmpegArguments.append(encodedTrackFile.path)
          }

          trackModifications[currentTrackIndex] = .replace(type: .video, files: [encodedTrackFile], lang: trackLanguage, trackName: currentTrack.properties.trackName ?? "")
        case .none:
          trackModifications[currentTrackIndex] = .remove(type: .video)
        case .copy:
          break // default is copy
        }
      case .audio, .subtitles:
        var embbedAC3Removed = false
        if preferedLanguages.contains(trackLanguage) {
          var trackDone = false
          // keep true-hd
          if currentTrack.isTrueHD, config.keepTrueHD {
            trackModifications[currentTrackIndex] = .copy(type: currentTrack.type)
            trackDone = true
          }
          if !config.audioPreference.encodeAudio {
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

            audioConverters.append(.init(input: tempFFmpegOutputFlac, output: finalOutputAudioTrack, preference: config.audioPreference, ffmpegCodecs: ffmpegCodecs, channelCount: currentTrack.properties.audioChannels!, trackIndex: currentTrackIndex))

            var replaceFiles = [finalOutputAudioTrack]
            // Optionally down mix
            if config.audioPreference.downmixMethod == .all, currentTrack.properties.audioChannels! > 2 {
              let tempFFmpegMixdownFlac = temporaryPath.appendingPathComponent("\(baseFilename)-\(currentTrackIndex)-\(trackLanguage)-ffmpeg-downmix.flac")
              let finalDownmixAudioTrack = temporaryPath.appendingPathComponent("\(baseFilename)-\(currentTrackIndex)-\(trackLanguage)-downmix.\(config.audioPreference.codec.outputFileExtension)")
              ffmpegArguments.append(contentsOf: ["-map", "0:\(currentTrackIndex)", "-ac", "2", tempFFmpegMixdownFlac.path])

              audioConverters.append(.init(input: tempFFmpegMixdownFlac, output: finalDownmixAudioTrack, preference: config.audioPreference, ffmpegCodecs: ffmpegCodecs, channelCount: 2, trackIndex: currentTrackIndex))
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
      }

      currentTrackIndex += 1
    }

    guard trackModifications.contains(where: { mod in
      switch mod {
      case .replace: return true
      default: return false
      }
    }) else {
      return trackModifications
    }

    if ffmpegArguments.count != defaultFFmpegArgumentsCount {
      // ffmpeg arguments modified, should launch ffmpeg
      logger.info("ffmpeg \(ffmpegArguments.joined(separator: " "))")
      // file's audio tracks -> external temp flac
      try launch(externalExecutable: FFmpeg(arguments: ffmpegArguments),
                 checkAllowedExitCodes: [0])
    }

    // check duplicate audio track
    #warning("use libflac to read")
    let tempFFmpegFlacFiles = audioConverters.map { $0.input }
    let flacMD5s: [String]
    do {
      if tempFFmpegFlacFiles.isEmpty {
        flacMD5s = .init()
      } else {
        flacMD5s = try FlacMD5.calculate(inputs: tempFFmpegFlacFiles.map { $0.path })
      }
    } catch {
      throw ChocoError.validateFlacMD5(error)
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
      throw ChocoError.terminated
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

  public func parse(temporaryDirectory: URL, language: ChocoConfiguration.LanguagePreference) throws -> [ChocoMuxer.WorkTask] {
    let mplsList = try scan(removeDuplicate: true)

    // TODO: check conflict

    var tasks = [ChocoMuxer.WorkTask]()

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
            tasks.append(.init(input: mpls.fileName, main: .init(MkvMerge(global: .init(quiet: true, split: generateSplit(splits: splits, chapterCount: mpls.chapterCount), chapterFile: chapterPath), output: output.path, inputs: [.init(file: mpls.fileName.path, options: [.audioTracks(.enabledLANGs(preferedLanguages)), .subtitleTracks(.enabledLANGs(preferedLanguages))])])), chapterSplit: true, canBeIgnored: false))
          } else {
            let splitWorkers = try split(mpls: mpls, temporaryDirectory: temporaryDirectory, language: language).map { $0.main }
            let main = MkvMerge(global: .init(quiet: true, chapterFile: chapterPath), output: output.path, inputs: mpls.files.enumerated().map { MkvMerge.Input(file: $0.element.path, append: $0.offset != 0, options: [.audioTracks(.enabledLANGs(preferedLanguages)), .subtitleTracks(.enabledLANGs(preferedLanguages))]) })
            let joinWorker = MkvMerge(global: .init(quiet: true, chapterFile: chapterPath), output: output.path, inputs: splitWorkers.enumerated().map { MkvMerge.Input(file: $0.element.outputURL.path, append: $0.offset != 0, options: [.audioTracks(.enabledLANGs(preferedLanguages)), .subtitleTracks(.enabledLANGs(preferedLanguages)), .noChapters]) })
            tasks.append(.init(input: mpls.fileName,
                               main: .init(main), chapterSplit: false,
                               splitWorkers: splitWorkers, joinWorker: .init(joinWorker)))
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
        throw ChocoError.noPlaylists
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
      throw ChocoError.noPlaylists
    }
  }

  private func split(mpls: Mpls, temporaryDirectory: URL, language: ChocoConfiguration.LanguagePreference) throws -> [ChocoMuxer.WorkTask] {
    try split(mpls: mpls, restFiles: Set(mpls.files), temporaryDirectory: temporaryDirectory, language: language)
  }

  private func split(mpls: Mpls, restFiles: Set<URL>, temporaryDirectory: URL, language: ChocoConfiguration.LanguagePreference) throws -> [ChocoMuxer.WorkTask] {
    print("Splitting MPLS: \(mpls.fileName)")

    if restFiles.count == 0 {
      return []
    }

    let clips = try mpls.split(chapterPath: temporaryDirectory)
    let preferedLanguages = language.generatePrimaryLanguages(with: [mpls.primaryLanguage])

    return clips.flatMap { (clip) -> [ChocoMuxer.WorkTask] in
      if restFiles.contains(clip.m2tsPath) {
        let output: URL
        let outputBasename = "\(mpls.fileName.lastPathComponentWithoutExtension)-\(clip.baseFilename)"
        if mpls.useFFmpeg {
          return [
            .init(input: clip.fileName,
                  main: .init(FFmpegCopyMuxer(input: clip.m2tsPath.path,
                                    output: temporaryDirectory.appendingPathComponent("\(outputBasename)-ffmpeg-video.mkv").path,
                                    mode: .video)), chapterSplit: false, canBeIgnored: true),
            .init(input: clip.fileName,
                  main: .init(FFmpegCopyMuxer(input: clip.m2tsPath.path,
                                              output: temporaryDirectory.appendingPathComponent("\(outputBasename)-ffmpeg-audio.mkv").path, mode: .audio)), chapterSplit: false, canBeIgnored: true)
          ]
        } else {
          let outputFilename = "\(outputBasename).mkv"
          output = temporaryDirectory.appendingPathComponent(outputFilename)
          return [.init(input: clip.fileName, main: .init(MkvMerge(global: .init(quiet: true, chapterFile: clip.chapterPath?.path), output: output.path, inputs: [.init(file: clip.m2tsPath.path, options: [.audioTracks(.enabledLANGs(preferedLanguages)), .subtitleTracks(.enabledLANGs(preferedLanguages))])])), chapterSplit: false, canBeIgnored: false)]
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

fileprivate func generateSplit(splits: [Int]?, chapterCount: Int) -> MkvMerge.GlobalOption.Split? {
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
extension ChocoMuxer {
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


