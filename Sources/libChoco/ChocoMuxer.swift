import PosixExecutableLauncher
import Foundation
import KwiftUtility
import MediaTools
import MplsParser
import Rainbow
import URLFileManager
import Logging
import ISOCodes
import Precondition
import FPExecutableLauncher
import JSON
import NumberKit
import SystemUp
import Command

let fm = URLFileManager.default

public final class ChocoMuxer {
  private let commonOptions: ChocoCommonOptions

  private let ffmpegCodecs: FFmpegCodecs

  struct FFmpegCodecs {
    let x265: Bool
    let x264: Bool
    let svtav1: Bool
    let fdkAAC: Bool
    let libopus: Bool
    let videotoolbox: Bool
    let audiotoolbox: Bool
    let vapoursynth: Bool

    init() throws {
      let options = try FFmpeg(global: .init(enableStdin: false))
        .launch(use: .posix(stdout: .makePipe, stderr: .makePipe), options: .init(checkNonZeroExitCode: false))
        .errorUTF8String
      x265 = options.contains("--enable-libx265")
      x264 = options.contains("--enable-libx264")
      svtav1 = options.contains("--enable-libsvtav1")
      fdkAAC = options.contains("--enable-libfdk-aac")
      libopus = options.contains("--enable-libopus")
      videotoolbox = options.contains("--enable-videotoolbox")
      audiotoolbox = options.contains("--enable-audiotoolbox")
      vapoursynth = options.contains("--enable-vapoursynth")
    }

  }

  private func checkCodecs() throws {
    if commonOptions.video.process == .encode {
      switch commonOptions.video.codec {
      case .x264:
        try preconditionOrThrow(ffmpegCodecs.x264, "ffmpeg no x264!")
      case .x265:
        try preconditionOrThrow(ffmpegCodecs.x265, "ffmpeg no x265!")
      case .svtav1:
        try preconditionOrThrow(ffmpegCodecs.svtav1, "ffmpeg no svtav1!")
      case .h264VT, .hevcVT, .h264VTSW, .hevcVTSW:
        try preconditionOrThrow(ffmpegCodecs.videotoolbox, "ffmpeg no videotoolbox!")
        switch commonOptions.video.quality {
        case .crf:
          try preconditionOrThrow(commonOptions.video.codec.supportsCrf, "Codec \(commonOptions.video.codec) doesn't support crf mode!")
        default:
          break
        }
      }
      if commonOptions.video.encodeScript != nil {
        if commonOptions.video.useIntergratedVapoursynth {
          try preconditionOrThrow(ffmpegCodecs.vapoursynth, "no vapoursynth!")
        } else {
          _ = try ExecutablePath.lookup(type: VsPipe.self).get()
        }
      }
    }
  }

  private func logConfig() {
    logger.info("Configurations:")
    logger.info("FFmpeg: \(ffmpegCodecs)")
    logger.info("Video: \(commonOptions.video)")
    logger.info("Audio: \(commonOptions.audio)")
    logger.info("Language filter: \(commonOptions.language)")
  }

  private let allowedExitCodes: [CInt]

  private let audioConvertQueue = OperationQueue()

  private var runningProcessID: ProcessID?
  var currentTemporaryPath: URL?

  let logger: Logger

  public init(commonOptions: ChocoCommonOptions, logger: Logger) throws {
    audioConvertQueue.maxConcurrentOperationCount = ProcessInfo.processInfo.processorCount
    self.commonOptions = commonOptions
    self.logger = logger
    if self.commonOptions.io.ignoreWarning {
      self.allowedExitCodes = [0, 1]
    } else {
      self.allowedExitCodes = [0]
    }
    // check ffmpeg codecs
    ffmpegCodecs = try .init()
    logConfig()
    try checkCodecs()
  }

  private func launch<E: Executable>(externalExecutable: E) throws -> Command.Output {
    var process = try externalExecutable
      .generateProcess(use: .posix)
      .spawn()
    runningProcessID = process.pid
    defer {
      runningProcessID = nil
    }
    let result = try process.waitOutput()
    return result
  }

  private func launch<E: Executable>(externalExecutable: E,
                                     checkAllowedExitCodes codes: [CInt]) throws {
//    logger.debug("Running \(externalExecutable.commandLineArguments)")
    let result = try launch(externalExecutable: externalExecutable)
    if result.status.exited {
      if !codes.contains(result.status.exitStatus) {
        throw ExecutableError.nonZeroExit
      }
    } else if result.status.signaled {
      throw ExecutableError.nonZeroExit
    }
  }

  private var terminated = false

  public func terminate() {
    terminated = true
    audioConvertQueue.cancelAllOperations()
    runningProcessID.map { _ = Signal.kill.send(to: .processID($0)) }
    runningProcessID = nil
  }

  private func logConverterStart(name: String, input: String, output: String) {
    logger.info("\n\(name):\n\(input)\n->\n\(output)")
  }

  func recursiveRun(task: WorkTask) -> Result<[URL], ChocoError> {
    do {
      logConverterStart(name: task.main.executable.executableName,
                        input: task.main.inputDescription,
                        output: task.main.outputURL.path)
      try launch(externalExecutable: task.main.executable, checkAllowedExitCodes: allowedExitCodes)
    } catch {
      if task.canBeIgnored {
        return .success([])
      }
      guard let splitWorkers = task.splitWorkers else {
        return .failure(.subTask(error))
      }
      for splitWorker in splitWorkers {
        do {
          try launch(externalExecutable: splitWorker.executable, checkAllowedExitCodes: allowedExitCodes)
        } catch {
          return .failure(.subTask(error))
        }
      }
      do {
        let result = try launch(externalExecutable: task.joinWorker!.executable)
        if result.status == .exited(2) {
          throw ExecutableError.nonZeroExit
        }
        return .success([task.joinWorker!.outputURL])
      } catch {
        logger.error("Failed to join the splitted files, the file will be splitted.")
        return .success(splitWorkers.map { $0.outputURL })
      }
    }

    if fm.fileExistance(at: task.main.outputURL).exists {
      // output exists
      return .success([task.main.outputURL])
    } else if task.chapterSplit, let parts = try? fm.contentsOfDirectory(at: task.main.outputURL.deletingLastPathComponent()).filter({ $0.pathExtension == task.main.outputURL.pathExtension && $0.lastPathComponent.hasPrefix(task.main.outputURL.lastPathComponentWithoutExtension) }) {
      return .success(parts)
    } else {
      logger.error("Necessary files are missing: \(task.main.outputURL.path).")
      return .failure(.noOutputFile(task.main.outputURL))
    }
  }
}

extension ChocoMuxer {

  public func mux(bdmv bdmvPath: URL, options: BDMVRemuxOptions) -> Result<BDMVSummary, ChocoError> {
    if terminated {
      return .failure(.terminated)
    }
    return self.withTemporaryDirectory { temporaryDirectoryURL -> Result<BDMVSummary, ChocoError> in
      let mplsMode: MplsRemuxMode = options.splitPlaylist ? .split : .direct
      let remuxToOutputDirectory = !options.directMode

      let startDate = Date()

      let task = BDMVMetadata(rootPath: bdmvPath, mode: mplsMode,
                              mainOnly: options.mainTitleOnly, split: commonOptions.io.split, logger: logger)
      let finalOutputDirectoryURL = commonOptions.io.outputRootDirectory.appendingPathComponent(task.getBlurayTitle())
      if fm.fileExistance(at: finalOutputDirectoryURL).exists {
        return .failure(.outputExist)
      }

      do {
        try fm.createDirectory(at: finalOutputDirectoryURL)
      } catch {
        return .failure(.createDirectory(finalOutputDirectoryURL))
      }

      let converters: [WorkTask]
      let mplsOutputDirectoryURL = remuxToOutputDirectory ? temporaryDirectoryURL : finalOutputDirectoryURL
      do {
        converters = try task.generateMuxTasks(outputDirectoryURL: mplsOutputDirectoryURL)
      } catch {
        return .failure(.parseBDMV(error))
      }

      var tasks: [BDMVSummary.PlaylistTask] = []
      for converter in converters {
        if terminated {
          break
        }
        let tempFiles: [URL]
        switch recursiveRun(task: converter) {
        case .success(let v):
          tempFiles = v
        case .failure(let e):
          return .failure(e)
        }
        
        if remuxToOutputDirectory {
          for tempFile in tempFiles {
            let startTime = Date()
            let mkvinfo = try! readMKV(at: tempFile)

            let duration = Timestamp(ns: UInt64(mkvinfo.container?.properties?.duration ?? 0))
            let subFolder: String
            if options.organizeOutput {
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

            let outputResult = _remux(
              file: tempFile,
              outputDirectoryURL: finalOutputDirectoryURL.appendingPathComponent(subFolder),
              temporaryPath: temporaryDirectoryURL,
              deleteAfterRemux: true, mkvinfoCache: mkvinfo)

            tasks.append(.init(playlistIndex: 0, segments: [], segmentsSize: 0, output: outputResult, timeSummary: .init(startTime: startTime)))
          }
        }
      }

      return .success(.init(input: bdmvPath, outputDirectory: finalOutputDirectoryURL, timeSummary: .init(startTime: startDate), tasks: tasks))
    }
  }

  public func mux(file: URL, options: FileRemuxOptions) -> Result<FileSummary, ChocoError> {

    logger.info("Start handling file input: \(file.path)")
    if terminated {
      return .failure(.terminated)
    }

    switch fm.fileExistance(at: file) {
    case .none:
      logger.error("The input file does not exist!")
      return .failure(.inputNotExists)
    case .file:
      let startTime = Date()
      return withTemporaryDirectory { tempDirectory in
        logger.info("The input is a regular file.")
        let inputInfo = IOFileInfo(path: file)
        let fileSummary = _remux(file: file, outputDirectoryURL: commonOptions.io.outputRootDirectory, temporaryPath: tempDirectory, deleteAfterRemux: options.removeSourceFiles)

        return .success(.init(files: [.init(input: inputInfo, output: fileSummary, timeSummary: .init(startTime: startTime))], normalFiles: []))
      }
    case .directory:
      logger.info("The input is a directory.")
      if !options.recursive {
        logger.error("Recursive is disabled.")
        return .failure(.directoryInputButNotRecursive)
      }
    }

    // start scan directory
    logger.info("Opening directory")

    let inputPrefix = file.path
    let dirName = file.lastPathComponent

    var files: [FileSummary.FileTask] = []
    var normalFiles: [FileSummary.NormalFileTask] = []

    do {
      let stream = try Fts.open(path: file.path, options: [.physical, .noChdir])
      while !terminated, let entry = try stream.read() {
        if entry.info == .file {
          let currentFileURL = URL(fileURLWithPath: entry.path.string)

          let fileDirPath = currentFileURL.deletingLastPathComponent().path
          guard fileDirPath.hasPrefix(inputPrefix) else {
            logger.error("Path handling incorrect")
            continue
          }
          let outputDirectoryURL = commonOptions.io.outputRootDirectory
            .appendingPathComponent(dirName)
            .appendingPathComponent(String(fileDirPath.dropFirst(inputPrefix.count)))

          let inputInfo = IOFileInfo(path: currentFileURL)
          let startTime = Date()

          // macOS resource files
          if currentFileURL.lastPathComponent == ".DS_Store" || currentFileURL.lastPathComponent.hasPrefix("._") {
            continue
          }

          if options.fileTypes.contains(currentFileURL.pathExtension.lowercased()) {
            // remux
            let outputResult = self.withTemporaryDirectory { tempDirectory in
              _remux(file: currentFileURL, outputDirectoryURL: outputDirectoryURL, temporaryPath: tempDirectory, deleteAfterRemux: options.removeSourceFiles)
            }
            files.append(.init(input: inputInfo, output: outputResult, timeSummary: .init(startTime: startTime)))
          } else {
            // copy
            if options.copyNormalFiles {
              let outputResult: Result<ChocoMuxer.IOFileInfo, ChocoError>
              let dstPath = outputDirectoryURL.appendingPathComponent(currentFileURL.lastPathComponent)
              if fm.fileExistance(at: dstPath).exists, !options.copyOverwrite {
                outputResult = .failure(.outputExist)
              } else {
                do {
                  try fm.createDirectory(at: outputDirectoryURL)
                  let cmd = options.removeSourceFiles ? "mv" : "cp"
                  try AnyExecutable(executableName: cmd, arguments: [currentFileURL.path, dstPath.path])
                    .launch(use: .posix)
                  outputResult = .success(.init(path: dstPath))
                } catch {
                  outputResult = .failure(.copyFile(error))
                }
              }
              normalFiles.append(.init(input: inputInfo, output: outputResult))
            }
          }
        }
      }
    } catch {
      logger.error("Failed to open the directory: \(file.path)")
      return .failure(.openDirectory(file))
    }

    return .success(.init(files: files, normalFiles: normalFiles))
  }


}

extension ChocoMuxer {

  internal func readMKV(at url: URL) throws -> MkvMergeIdentification {
    logger.info("Reading mkv file \(url.path)")
    return try .init(url: url)
  }

  /// main function, remux mkv file
  private func _remux(file: URL, outputDirectoryURL: URL, temporaryPath: URL,
                      deleteAfterRemux: Bool,
                      parseOnly: Bool = false,
                      mkvinfoCache: MkvMergeIdentification? = nil) -> Result<IOFileInfo, ChocoError> {

    let outputURL = outputDirectoryURL
      .appendingPathComponent("\(file.lastPathComponentWithoutExtension).mkv")

    guard !fm.fileExistance(at: outputURL).exists else {
      return .failure(.outputExist)
    }

    let mkvinfo: MkvMergeIdentification
    do {
      mkvinfo = try mkvinfoCache ?? readMKV(at: file)
    } catch {
      return .failure(.mkvmergeIdentification(error))
    }

    let modifications: [TrackModification]
    switch _makeTrackModification(mkvinfo: mkvinfo, temporaryPath: temporaryPath) {
    case .success(let v):
      modifications = v
    case .failure(let e):
      return .failure(e)
    }

    var trackOrderAndType = [(MkvMerge.GlobalOption.TrackOrder, MediaTrackType)]()
    var videoRemovedTrackIndexes = [Int]()
    var audioRemovedTrackIndexes = [Int]()
    var subtitleRemoveTracks = [Int]()
    /// copied video tracks
    var videoCopiedTrackIndexes = [Int]()
    var externalTracks = [(file: URL, lang: Language, trackName: String, flags: [MkvMerge.Input.InputOption.Flag : Bool])]()

    var mainInput = MkvMerge.Input(file: file.path)

    for modify in modifications.enumerated() {
      switch modify.element {
      case .copy(let type):
        trackOrderAndType.append((.init(fid: 0, tid: modify.offset), type))
        switch type {
        case .video:
          videoCopiedTrackIndexes.append(modify.offset)
        default:
          break
        }
      case .remove(let type, _):
        switch type {
        case .audio:
          audioRemovedTrackIndexes.append(modify.offset)
        case .subtitles:
          subtitleRemoveTracks.append(modify.offset)
        case .video:
          videoRemovedTrackIndexes.append(modify.offset)
        }
      case let .replace(type, files, lang, trackName, flags):
        switch type {
        case .audio:
          audioRemovedTrackIndexes.append(modify.offset)
        case .subtitles:
          subtitleRemoveTracks.append(modify.offset)
        case .video:
          videoRemovedTrackIndexes.append(modify.offset)
        }
        files.forEach { file in
          externalTracks.append((file, lang, trackName, flags))
          trackOrderAndType.append((.init(fid: externalTracks.count, tid: 0), type))
        }
      }

      switch modify.element {
      case .copy:
        if !commonOptions.meta.keep(.trackName) {
          mainInput.options.append(.trackName(tid: modify.offset, name: ""))
        }
      default: break
      }
    }

    if !commonOptions.meta.keep(.videoLanguage) {
      videoCopiedTrackIndexes.forEach { mainInput.options.append(.language(tid: $0, language: "und")) }
    }
    if !commonOptions.meta.keep(.attachments) {
      mainInput.options.append(.attachments(.removeAll))
    }
    if !commonOptions.meta.keep(.tags) {
      mainInput.options.append(.noGlobalTags)
      //      mainInput.options.append(.trackTags(.removeAll))
    }

    func correctTrackSelection(type: MediaTrackType, removedIndexes: [Int]) -> MkvMerge.Input.InputOption.TrackSelect {
      if mkvinfo.tracks?.count(where: {$0.trackType == type}) == removedIndexes.count {
        return .removeAll
      } else {
        return .disabledTIDs(removedIndexes)
      }
    }

    mainInput.options.append(.videoTracks(correctTrackSelection(type: .video, removedIndexes: videoRemovedTrackIndexes)))
    mainInput.options.append(.audioTracks(correctTrackSelection(type: .audio, removedIndexes: audioRemovedTrackIndexes)))
    mainInput.options.append(.subtitleTracks(correctTrackSelection(type: .subtitles, removedIndexes: subtitleRemoveTracks)))

    let externalInputs = externalTracks.map { (track) -> MkvMerge.Input in
      var options: [MkvMerge.Input.InputOption] = [.language(tid: 0, language: track.lang.alpha3BibliographicCode)]
      options.append(.trackName(tid: 0, name: commonOptions.meta.keep(.trackName) ? track.trackName : ""))
      options.append(.noGlobalTags)
      options.append(.noChapters)
      options.append(.trackTags(.removeAll))
      track.flags.forEach { (flag, value) in
        options.append(.flag(tid: 0, flag, value))
      }
      return .init(file: track.file.path, options: options)
    }
    let splitInfo = generateMkvmergeSplit(split: commonOptions.io.split, chapterCount: mkvinfo.chapters?.first?.numEntries ?? 0)

    let trackOrder: [MkvMerge.GlobalOption.TrackOrder]
    if commonOptions.meta.sortTrackType {
      let typePriority = [MediaTrackType.video, .audio, .subtitles]
      trackOrder = typePriority.reduce(into: [], { partialResult, currentType in
        partialResult.append(contentsOf: trackOrderAndType.filter { $0.1 == currentType }.map(\.0))
      })
    } else {
      trackOrder = trackOrderAndType.map(\.0)
    }

    let mkvGlobal = MkvMerge.GlobalOption(quiet: true, title: commonOptions.meta.keep(.title) ? nil : "", trackOrder: trackOrder, split: splitInfo, flushOnClose: true, experimentalFeatures: [.append_and_split_flac])

    let mkvmerge = MkvMerge(
      global: mkvGlobal,
      output: outputURL.path, inputs: [mainInput] + externalInputs)
//    logger.debug("\(mkvmerge.commandLineArguments.joined(separator: " "))")

    logger.info("Mkvmerge: \(file.path) -------> \(outputURL.path)")
    do {
      try launch(externalExecutable: mkvmerge, checkAllowedExitCodes: allowedExitCodes)
    } catch {
      logger.info("muxing failed, remove the unfinished file.")
      try? fm.removeItem(at: outputURL)
      return .failure(.mkvmergeMux(error))
    }

    externalTracks.forEach { t in
      do {
        try fm.removeItem(at: t.file)
      } catch {
        logger.warning("Can not delete temp file: \(t.file)")
      }
    }

    if deleteAfterRemux {
      do {
        try fm.removeItem(at: file)
      } catch {
        logger.warning("Can not delete original file: \(file)")
      }
    }

    return .success(.init(path: outputURL))
  }
}

// MARK: - Utilities

extension ChocoMuxer {

  private func withTemporaryDirectory<T>(_ body: (URL) -> Result<T, ChocoError>) -> Result<T, ChocoError> {
    let uniqueTempDirectory = commonOptions.io.temperoraryDirectory.appendingPathComponent(UUID().uuidString)
    logger.info("Creating temp dir at: \(uniqueTempDirectory.path)")
    do {
      try fm.createDirectory(at: uniqueTempDirectory)
    } catch {
      logger.error("Failed to create.")
      return .failure(.createDirectory(uniqueTempDirectory))
    }
    var taskSuccess = false
    defer {
      let needRemove: Bool
      switch (commonOptions.io.keepTempMethod, taskSuccess) {
      case (.always, _),
        (.failed, false):
        needRemove = false
      default:
        needRemove = true
      }
      if needRemove {
        do {
          try fm.removeItem(at: uniqueTempDirectory)
        } catch {
          logger.error("cannot remove temp directory: \(uniqueTempDirectory.path), error: \(error)")
        }
      }
    }
    self.currentTemporaryPath = uniqueTempDirectory
    defer { self.currentTemporaryPath = nil }
    let result = body(uniqueTempDirectory)
    taskSuccess = true
    return result
  }

  private func display(modiifcations: [TrackModification]) {
    logger.info("Track modifications: ")
    for m in modiifcations.enumerated() {
      logger.info("\(m.offset): \(m.element)")
    }
  }

  private func _makeTrackModification(mkvinfo: MkvMergeIdentification,
                                      temporaryPath: URL) -> Result<[TrackModification], ChocoError> {

    let primaryLanguage: Language = mkvinfo.tracks?
      .first { $0.trackType == .audio }?
      .properties?.language.flatMap { str in
        if let v = Language(argument: str) {
          return v
        } else {
          logger.warning("Unknown language code in mkvinfo: \(str)")
          return nil
        }
      } ?? .und
    logger.info("Primary language detected: \(primaryLanguage.alpha3BibliographicCode)")

    let ffmpegMainInputFileID = 0
    var currentFFmpegAdditionalInputFileID = 1
    let tracks = mkvinfo.tracks ?? []
    var audioConverters = [AudioConverter]()
    var ffmpeg = FFmpeg(global: .init(hideBanner: true, overwrite: true, enableStdin: false),
                        inputs: [.init(url: mkvinfo.fileName!)])

    let forceUseFilePrimaryLanguage: Bool
    do {
      let filteredAudioCount = tracks
        .filter { $0.trackType == .audio }
        .count(where: { commonOptions.language.shouldMuxTrack(trackLanguage: $0.trackLanguageCode, trackType: $0.trackType, primaryLanguage: primaryLanguage, forcePrimary: false) })
      logger.info("Valid audio tracks count will be \(filteredAudioCount)")
      if commonOptions.language.preventNoAudio {
        forceUseFilePrimaryLanguage = filteredAudioCount == 0
      } else {
        forceUseFilePrimaryLanguage = false
      }
      logger.info("Force use input file's primary language: \(forceUseFilePrimaryLanguage)")
    }

    var trackModifications = [TrackModification](repeating: .copy(type: .video), count: tracks.count)

    defer {
      display(modiifcations: trackModifications)
    }

    let mediainfo: JSON
    do {
      let output = try MediaInfo(full: true, output: .json, files: [mkvinfo.fileName!])
        .launch(use: .posix(stdout: .makePipe, stderr: .makePipe))
        .output
      mediainfo = try .read(string: output).get()
    } catch {
      return .failure(.mediainfo(error))
    }

    // check track one by one
    logger.info("Checking tracks codec")
    var currentTrackIndex = tracks.startIndex
    let baseFilename = URL(fileURLWithPath: mkvinfo.fileName!).lastPathComponentWithoutExtension

    var videoHandled = false

    while currentTrackIndex < tracks.count {
      let currentTrack = tracks[currentTrackIndex]
      let trackLanguage = currentTrack.trackLanguageCode
      logger.info("\(currentTrack.remuxerInfo)")
      if currentTrack.properties?.enabledTrack == false,
         !commonOptions.meta.keep(.disabled) {
        trackModifications[currentTrackIndex] = .remove(type: currentTrack.trackType, reason: .trackDisabled)
        currentTrackIndex += 1
        continue
      }
      switch currentTrack.trackType {
      case .video:
        if videoHandled {
          break
        }
        videoHandled = true

        // mediainfo infos
        let media = try! (mediainfo.root?["media"]).unwrap()
        let tracks = try! (media["track"]?.array).unwrap()
        let videoTrack = tracks.first(where: { $0["@type"]! == "Video" })!
        _ = consume media
        _ = consume tracks


        /*
         "Width":"720",
         "Height":"480",
         "Sampled_Width":"720",
         "Sampled_Height":"480",
         "PixelAspectRatio":"1.212",
         "DisplayAspectRatio":"1.819",
         "DisplayAspectRatio_String":"16:9",
         "DisplayAspectRatio_Original":"1.818",
         "DisplayAspectRatio_Original_String":"16:9",
         "FrameRate":"59.940",
         "FrameRate_String":"59.940 FPS",
         "FrameRate_Original":"29.970",
         "FrameRate_Original_String":"29.970 (30000/1001) FPS",
         "FrameRate_Original_Num":"30000",
         "FrameRate_Original_Den":"1001",
         */

        switch commonOptions.video.process {
        case .encode:
          let width = try! (videoTrack["Width"]?.string.flatMap(UInt.init)).unwrap("no width")
          let height = try! (videoTrack["Height"]?.string.flatMap(UInt.init)).unwrap("no height")
          let sar: SampleAspectRatio
          if videoTrack["PixelAspectRatio"]?.string == "1.000" {
            sar = .init(1)
          } else {
            do {
              let darString = try (videoTrack["DisplayAspectRatio_String"]?.string).unwrap("no dar")
              let errInfo = "invalid dar format: \(darString)"
              let parts = try darString.splitTwoPart(":").unwrap()
              let dar = try SampleAspectRatio(.init(parts.0).unwrap(errInfo), .init(parts.1).unwrap(errInfo))

              sar = dar.divided(by: SampleAspectRatio(Int(width), Int(height)))
            } catch {
              fatalError("cannot detect sar from dar! error: \(error)")
            }
          }
          let fps = try! {
            do {
              let num = try (videoTrack["FrameRate_Original_Num"]?.string.flatMap(UInt.init)).unwrap("no framerate num origin")
              let den = try (videoTrack["FrameRate_Original_Den"]?.string.flatMap(UInt.init)).unwrap("no framerate den origin")
              return Rational(Int(num), Int(den))
            } catch {
              do {
                let num = try (videoTrack["FrameRate_Num"]?.string.flatMap(UInt.init)).unwrap("no framerate num")
                let den = try (videoTrack["FrameRate_Den"]?.string.flatMap(UInt.init)).unwrap("no framerate den")
                return Rational(Int(num), Int(den))
              } catch {
                // try find known fps values
                let value = try (videoTrack["FrameRate"]?.string).unwrap("no framerate value (FrameRate)")
                switch value {
                case "23.976": return .init(24000, 1001)
                case "29.97": return .init(30000, 1001)
                default: throw ChocoError.invalidFPS(value)
                }
              }
            }
          }()
          logger.info("video track sar: \(sar)")
          logger.info("video track fps: \(fps)")

          if commonOptions.video.progressiveOnly {
            logger.info("Progressive-only mode enabled, checking video track scan type.")
            // check scan type
            if let scanType = videoTrack["ScanType"]?.string {
              logger.info("Scan type: \(scanType)")
              if scanType.lowercased() != "progressive" {
                logger.info("Non progressive detected, skip this file.")
                return .failure(.nonProgTrackInProgOnlyMode)
              }
            } else {
              logger.warning("No scan type found!")
            }
          }

          let encodedTrackFile = temporaryPath.appendingPathComponent("\(baseFilename)-\(currentTrackIndex)-\(trackLanguage)-encoded.mkv")
          
          // autocrop
          // TODO: generate crop info using user's filter
          let cropInfo: CropInfo?
          if commonOptions.video.autoCrop {
            logger.info("Calculating crop info with ffmpeg..")
            switch ffmpegCrop(file: mkvinfo.fileName!, baseFilter: commonOptions.video.cropFilter, limit: commonOptions.video.cropLimit, round: commonOptions.video.cropRound, skip: commonOptions.video.cropSkip, frames: commonOptions.video.cropFrames, logger: logger) {
            case .success(let v):
              logger.info("Calculated: \(v)")
              cropInfo = v
            case .failure(let err):
              return .failure(err)
            }
          } else {
            cropInfo = nil
          }

          if let encodeScript = commonOptions.video.encodeScript {
            // use script template
            let script = try! generateScript(
              encodeScript: encodeScript, filePath: mkvinfo.fileName!,
              trackIndex: currentTrackIndex,
              cropInfo: cropInfo,
              encoderDepth: commonOptions.video.codec.depth,
              fps: fps
            )
            let scriptFileURL = temporaryPath.appendingPathComponent("\(baseFilename)-\(currentTrackIndex)-generated_script.py")
            try! script.write(to: scriptFileURL, atomically: false, encoding: .utf8)

            var videoOutput = FFmpeg.Output(url: encodedTrackFile.path, options: commonOptions.video.ffmpegIOOptions(cropInfo: nil, sourceSAR: sar))

            if commonOptions.video.useIntergratedVapoursynth {
              logger.info("Using ffmpeg integrated Vapoursynth!")
              videoOutput.options.append(.map(inputFileID: currentFFmpegAdditionalInputFileID, streamSpecifier: nil, isOptional: false, isNegativeMapping: false))
              ffmpeg.inputs.append(.init(url: scriptFileURL.path, options: [.format("vapoursynth")]))
              ffmpeg.outputs.append(videoOutput)
              currentFFmpegAdditionalInputFileID += 1
            } else {
              // use vspipe piping to ffmpeg
              defer {
                runningProcessID = nil
              }
              do {
                let pipeline = try ContiguousPipeline(VsPipe(script: scriptFileURL.path, output: .file(.stdout), container: .y4m))

                let vspipeFFmpeg = FFmpeg(global: .init(hideBanner: true), 
                                          inputs: [.init(url: "pipe:")],
                                          outputs: [videoOutput])

                try pipeline.append(vspipeFFmpeg, isLast: true)

                try pipeline.run()

                runningProcessID = (pipeline.processes.first?.processIdentifier).map(ProcessID.init)


                pipeline.waitUntilExit()
                for p in pipeline.processes {
                  guard p.terminationReason == .exit, p.terminationStatus == 0 else {
                    throw ExecutableError.nonZeroExit
                  }
                }
              } catch {
                return .failure(.subTask(error))
              }
            }
          } else {
            // encode use ffmpeg
            var outputOptions: [FFmpeg.OutputOption] = [
              .map(inputFileID: ffmpegMainInputFileID, streamSpecifier: .streamIndex(currentTrackIndex), isOptional: false, isNegativeMapping: false),
              .mapMetadata(outputSpec: nil, inputFileIndex: -1, inputSpec: nil),
              .mapChapters(inputFileIndex: -1),
            ]
            outputOptions.append(contentsOf: commonOptions.video.ffmpegIOOptions(cropInfo: cropInfo, sourceSAR: sar))
            // output
            ffmpeg.outputs.append(.init(url: encodedTrackFile.path, options: outputOptions))
          }

          trackModifications[currentTrackIndex] = .replace(type: .video, files: [encodedTrackFile], lang: trackLanguage, trackName: currentTrack.properties?.trackName ?? "", flags: currentTrack.flags)
        case .none:
          trackModifications[currentTrackIndex] = .remove(type: .video, reason: .trackTypeDisabled)
        case .copy:
          break // default is copy
        }
      case .audio, .subtitles:
        var embbedAC3Removed = false
        // language filter
        if commonOptions.language.shouldMuxTrack(trackLanguage: trackLanguage, trackType: currentTrack.trackType, primaryLanguage: primaryLanguage, forcePrimary: forceUseFilePrimaryLanguage) {
          var trackDone = false
          // check subtitle(pgs) count
          if currentTrack.trackType == .subtitles {
            let media = try! (mediainfo.root?["media"]).unwrap()
            let tracks = try! (media["track"]?.array).unwrap()
            let subtitleTrack = tracks.first(where: { $0["StreamOrder"]?.string == "\(currentTrackIndex)" })!
            precondition(subtitleTrack["StreamOrder"]! == "\(currentTrackIndex)", "track id mismatch between mkvmerge and mediainfo")
            precondition(subtitleTrack["@type"]! == "Text", "track type mismatch between mkvmerge and mediainfo")
            if subtitleTrack["Format"]?.string == "PGS",
               let elementCountString = subtitleTrack["ElementCount"]?.string,
               let elementCount = Int(elementCountString) {
              if elementCount < commonOptions.meta.minPGSCount {
                trackModifications[currentTrackIndex] = .remove(type: .subtitles, reason: .subtitleCount(elementCount))
                trackDone = true
              }
            }
          }
          // keep true-hd
          if currentTrack.isTrueHD, commonOptions.audio.shouldCopy(.truehd) {
            trackModifications[currentTrackIndex] = .copy(type: currentTrack.trackType)
            trackDone = true
          }
          if !commonOptions.audio.encodeAudio {
            trackModifications[currentTrackIndex] = .copy(type: currentTrack.trackType)
            trackDone = true
          }
          // remove same spec dts-hd
          if !trackDone, commonOptions.audio.removeExtraDTS, currentTrack.isDTSHD {
            var fixed = false
            if case let indexBefore = tracks.index(before: currentTrackIndex),
               indexBefore >= tracks.startIndex {
              let compareTrack = tracks[indexBefore]
              if compareTrack.isTrueHD,
                 compareTrack.properties?.language == currentTrack.properties?.language,
                 compareTrack.properties?.audioChannels == currentTrack.properties?.audioChannels {
                trackModifications[currentTrackIndex] = .remove(type: .audio, reason: .extraDTSHD)
                fixed = true
                // remove the ac3 after
                if !embbedAC3Removed, currentTrackIndex + 1 < tracks.count,
                   case let nextTrack = tracks[currentTrackIndex + 1],
                   nextTrack.isAC3, nextTrack.properties?.language == currentTrack.properties?.language {
                  // Remove TRUEHD embed-in AC-3 track
                  trackModifications[currentTrackIndex + 1] = .remove(type: .audio, reason: .embedAC3InTrueHD)
                  currentTrackIndex += 1
                  embbedAC3Removed = true
                }
              }
            }
            if !fixed, case let indexAfter = tracks.index(after: currentTrackIndex),
               indexAfter < tracks.endIndex {
              let compareTrack = tracks[indexAfter]
              if compareTrack.isTrueHD,
                 compareTrack.properties?.language == currentTrack.properties?.language,
                 compareTrack.properties?.audioChannels == currentTrack.properties?.audioChannels {
                trackModifications[currentTrackIndex] = .remove(type: .audio, reason: .extraDTSHD)
                fixed = true
              }
            }
            trackDone = fixed
          }

          // keep flac
          if !trackDone && currentTrack.isFlac && commonOptions.audio.shouldCopy(.flac) {
            trackModifications[currentTrackIndex] = .copy(type: currentTrack.trackType)
            trackDone = true
          }

          // lossless audio -> flac, or fix garbage dts
          if !trackDone && (currentTrack.isLosslessAudio || (commonOptions.audio.shouldFix(.dts) && currentTrack.isGarbageDTS)) {
            let codec = currentTrack.isLosslessAudio ? commonOptions.audio.codec : commonOptions.audio.codecForLossyAudio
            // add to ffmpeg arguments
            let tempFFmpegOutputFlac = temporaryPath.appendingPathComponent("\(baseFilename)-\(currentTrackIndex)-\(trackLanguage)-ffmpeg.flac")
            let finalOutputAudioTrack = temporaryPath.appendingPathComponent("\(baseFilename)-\(currentTrackIndex)-\(trackLanguage).\(codec.outputFileExtension)")
            ffmpeg.outputs.append(.init(url: tempFFmpegOutputFlac.path, options: [
              .map(inputFileID: ffmpegMainInputFileID, streamSpecifier: .streamIndex(currentTrackIndex), isOptional: false, isNegativeMapping: false),
              .avOption(name: "compression_level", value: "0", streamSpecifier: nil),
              .mapMetadata(outputSpec: nil, inputFileIndex: -1, inputSpec: nil),
              .mapChapters(inputFileIndex: -1),
            ]))

            audioConverters.append(
              .init(
                input: tempFFmpegOutputFlac,
                output: finalOutputAudioTrack,
                codec: codec,
                lossyAudioChannelBitrate: commonOptions.audio.lossyAudioChannelBitrate,
                reduceBitrate: commonOptions.audio.reduceBitrate,
                preferedTool: commonOptions.audio.preferedTool,
                ffmpegCodecs: ffmpegCodecs,
                channelCount: Int(currentTrack.properties!.audioChannels!),
                trackIndex: currentTrackIndex)
            )

            var replaceFiles = [finalOutputAudioTrack]
            // Optionally down mix
            if commonOptions.audio.downmixMethod == .all, currentTrack.properties!.audioChannels! > 2 {
              let tempFFmpegMixdownFlac = temporaryPath.appendingPathComponent("\(baseFilename)-\(currentTrackIndex)-\(trackLanguage)-ffmpeg-downmix.flac")
              let finalDownmixAudioTrack = temporaryPath.appendingPathComponent("\(baseFilename)-\(currentTrackIndex)-\(trackLanguage)-downmix.\(codec.outputFileExtension)")
              ffmpeg.outputs.append(.init(url: tempFFmpegMixdownFlac.path, options: [
                .map(inputFileID: ffmpegMainInputFileID, streamSpecifier: .streamIndex(currentTrackIndex), isOptional: false, isNegativeMapping: false),
                .audioChannels(2, streamSpecifier: nil),
                .avOption(name: "compression_level", value: "0", streamSpecifier: nil),
                .mapMetadata(outputSpec: nil, inputFileIndex: -1, inputSpec: nil),
                .mapChapters(inputFileIndex: -1),
              ]))

              audioConverters.append(
                .init(
                  input: tempFFmpegMixdownFlac,
                  output: finalDownmixAudioTrack,
                  codec: codec,
                  lossyAudioChannelBitrate: commonOptions.audio.lossyAudioChannelBitrate,
                  reduceBitrate: commonOptions.audio.reduceBitrate,
                  preferedTool: commonOptions.audio.preferedTool,
                  ffmpegCodecs: ffmpegCodecs,
                  channelCount: 2,
                  trackIndex: currentTrackIndex)
              )

              replaceFiles.insert(finalDownmixAudioTrack, at: 0)
            }

            trackModifications[currentTrackIndex] = .replace(type: .audio, files: replaceFiles, lang: trackLanguage, trackName: currentTrack.properties?.trackName ?? "", flags: currentTrack.flags)
            trackDone = true
          }

          if !trackDone {
            trackModifications[currentTrackIndex] = .copy(type: currentTrack.trackType)
          }
        } else {
          // invalid language
          trackModifications[currentTrackIndex] = .remove(type: currentTrack.trackType, reason: .languageFilter(trackLanguage))
        } // language end

        // handle truehd
        if !embbedAC3Removed, currentTrack.isTrueHD, currentTrackIndex + 1 < tracks.count,
           case let nextTrack = tracks[currentTrackIndex + 1],
           nextTrack.isAC3 {
          // Remove TRUEHD embed-in AC-3 track
          trackModifications[currentTrackIndex + 1] = .remove(type: .audio, reason: .embedAC3InTrueHD)
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
      return .success(trackModifications)
    }

    if !ffmpeg.outputs.isEmpty {
      // ffmpeg has output, should launch ffmpeg
//      logger.info("\(ffmpeg.commandLineArguments)")
      // file's audio tracks -> external temp flac
      do {
        try launch(externalExecutable: ffmpeg, checkAllowedExitCodes: [0])
      } catch {
        return .failure(.subTask(error))
      }
    }

    // check duplicate audio track
    // TODO: use libflac to read md5
    do {
      let tempFFmpegFlacFiles = audioConverters.map { $0.input }
      if !tempFFmpegFlacFiles.isEmpty {
        let flacMD5s: [String]
        do {
          flacMD5s = try FlacEncoder.md5Calculator(inputs: tempFFmpegFlacFiles.map { $0.path })
            .launch(use: .posix(stdout: .makePipe, stderr: .makePipe))
            .output.split(separator: UInt8(ascii: "\n")).map {
              String(decoding: $0, as: UTF8.self)
            }
        } catch {
          return .failure(.validateFlacMD5(error))
        }

        precondition(tempFFmpegFlacFiles.count == flacMD5s.count, "Flac MD5 count dont match")

        // verify duplicate audios
        let md5Set = Set(flacMD5s)
        if md5Set.count < flacMD5s.count {
          logger.info("Has duplicate tracks")

          // remove extra duplicate tracks
          for md5 in md5Set {
            let indexes = flacMD5s.indexes(of: md5)
            precondition(indexes.count > 0)
            if indexes.count > 1 {
              indexes.dropFirst().forEach { trackModifications[audioConverters[$0].trackIndex].remove(reason: .duplicateAudioHash) }
            }
          }
        }
      }
    } // end of duplicated audio check

    // clean temp flac
    audioConverters.forEach { converter in
      _ = try? AnyExecutable(executableName: "metaflac", arguments: ["--remove-tag", "encoder", converter.input.path])
        .launch(use: .posix)
    }

    // external temp flac -> final audio tracks
    audioConverters.forEach { converter in
      self.logConverterStart(name: converter.executable.executableName, input: converter.input.path, output: converter.output.path)

      let operation = AudioConvertOperation(converter: converter) { [logger] error in
        logger.error("Audio convert error: \(error)")
      }

      audioConvertQueue.addOperation(operation)
    }
    audioConvertQueue.waitUntilAllOperationsAreFinished()
    if terminated {
      return .failure(.terminated)
    }

    return .success(trackModifications)
  }
}

struct InputProperties {
  struct Common {
    let codec: String
    let duration: String
    let bitrate: String
    let streamSize: String
  }

  struct Video {
    let colorSpace: String
    let chromaSubsampling: String
    let isProgressive: Bool
  }

  struct Audio {
    let samplingRate: String
    let bitDepth: String
  }
}

struct TrackHandleStatus {
  var handled: Bool
  let id: Int


}

enum TrackModification: CustomStringConvertible {
  case copy(type: MediaTrackType)
  case replace(type: MediaTrackType, files: [URL], lang: Language, trackName: String, flags: [MkvMerge.Input.InputOption.Flag: Bool])
  case remove(type: MediaTrackType, reason: RemoveReason)

  enum RemoveReason {
    case subtitleCount(Int)
    case duplicateAudioHash
    case trackTypeDisabled
    case embedAC3InTrueHD
    case extraDTSHD
    case languageFilter(Language)
    case trackDisabled
  }

  mutating func remove(reason: RemoveReason) {
    switch self {
    case .replace(type: let type, files: let files, _, _, _):
      files.forEach{ try? fm.removeItem(at: $0) }
      self = .remove(type: type, reason: reason)
    case .copy(type: let type):
      self = .remove(type: type, reason: reason)
    case .remove(type: _):
      return
    }
  }

  var type: MediaTrackType {
    switch self {
    case .replace(type: let type, _, _, _, _):
      return type
    case .copy(type: let type):
      return type
    case .remove(type: let type, reason: _):
      return type
    }
  }

  var description: String {
    switch self {
    case .replace(type: let type, files: let files, lang: let lang, trackName: let trackName, _):
      return "replace(type: \(type), files: \(files.map(\.path)), lang: \(lang), trackName: \(trackName))"
    case .copy(type: let type):
      return "copy(type: \(type))"
    case .remove(type: let type, reason: let reason):
      return "remove(type: \(type), reason: \(reason))"
    }
  }
}

public struct BDMVMetadata {
  public init(rootPath: URL, mode: MplsRemuxMode, mainOnly: Bool, split: ChocoSplit?, logger: Logger) {
    self.rootPath = rootPath
    self.mode = mode
    self.mainOnly = mainOnly
    self.split = split
    self.logger = logger
  }

  let rootPath: URL
  let mode: MplsRemuxMode
  let mainOnly: Bool
  let split: ChocoSplit?
  let logger: Logger

  public func generateMuxTasks(outputDirectoryURL: URL) throws -> [ChocoMuxer.WorkTask] {
    let mplsList = try scan(removeDuplicate: true)

    // TODO: check conflict

    var tasks = [ChocoMuxer.WorkTask]()

    switch mode {
    case .split:
      var allFiles = Set(mplsList.flatMap { $0.files })
      try mplsList.forEach { mpls in
        tasks.append(contentsOf: try split(mpls: mpls, restFiles: allFiles, temporaryDirectory: outputDirectoryURL))
        mpls.files.forEach { usedFile in
          allFiles.remove(usedFile)
        }
      }
    case .direct:
      try mplsList.forEach { mpls in
        if mpls.useFFmpeg || mpls.compressed { /* || mpls.remuxMode == .split*/
          tasks.append(contentsOf: try split(mpls: mpls, temporaryDirectory: outputDirectoryURL))
        } else {
          let outputFilename = generateFilename(mpls: mpls)
          let output = outputDirectoryURL.appendingPathComponent(outputFilename + ".mkv")
          let parsedMpls = try MplsPlaylist.parse(mplsContents: Data(contentsOf: mpls.fileName))
          let chapter = parsedMpls.convert()
          let chapterFile = outputDirectoryURL.appendingPathComponent("\(mpls.fileName.lastPathComponentWithoutExtension).xml")
          let chapterPath: String?
          if !chapter.isEmpty {
            try chapter.exportMkvChapXML(to: chapterFile)
            chapterPath = chapterFile.path
          } else {
            chapterPath = nil
          }

          if split != nil {
            tasks.append(.init(input: mpls.fileName, main: .init(MkvMerge(global: .init(quiet: true, split: generateMkvmergeSplit(split: split, chapterCount: mpls.chapterCount)), output: output.path, inputs: [.init(file: mpls.fileName.path)])), chapterSplit: true, canBeIgnored: false))
          } else {
            let splitWorkers = try split(mpls: mpls, temporaryDirectory: outputDirectoryURL).map { $0.main }
            let main = MkvMerge(global: .init(quiet: true, chapterFile: chapterPath), output: output.path, inputs: mpls.files.enumerated().map { MkvMerge.Input(file: $0.element.path, append: $0.offset != 0) })
            let joinWorker = MkvMerge(global: .init(quiet: true, chapterFile: chapterPath), output: output.path, inputs: splitWorkers.enumerated().map { MkvMerge.Input(file: $0.element.outputURL.path, append: $0.offset != 0, options: [.noChapters]) })
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
    logger.info("Blu-ray title: \(getBlurayTitle())")
    let mplsList = try scan(removeDuplicate: true)
    logger.info("MPLS List:\n")
    mplsList.forEach { print($0); print() }
  }

  func getBlurayTitle() -> String {
    rootPath.lastPathComponent.safeFilename().trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func scan(removeDuplicate: Bool) throws -> [Mpls] {
    logger.info("Start scanning BD folder: \(rootPath.path)")
    let playlistPath = rootPath.appendingPathComponent("BDMV/PLAYLIST", isDirectory: true)

    if mainOnly {
      let index = try getMainPlaylist(at: rootPath.path)
      let url = playlistPath.appendingPathComponent("\(String(format: "%05d", index)).mpls")
      return [try Mpls(filePath: url.path)]
    }

    if fm.fileExistance(at: playlistPath) == .directory {
      let mplsPaths = try fm.contentsOfDirectory(at: playlistPath).filter { $0.pathExtension.lowercased() == "mpls" }
      if mplsPaths.isEmpty {
        throw ChocoError.noPlaylists
      }
      let allMpls = mplsPaths.compactMap { (mplsPath) -> Mpls? in
        do {
          return try .init(filePath: mplsPath.path)
        } catch {
          logger.error("Invalid file: \(mplsPath), error: \(error)")
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
      logger.error("No PLAYLIST Folder!")
      throw ChocoError.noPlaylists
    }
  }

  private func split(mpls: Mpls, temporaryDirectory: URL) throws -> [ChocoMuxer.WorkTask] {
    try split(mpls: mpls, restFiles: Set(mpls.files), temporaryDirectory: temporaryDirectory)
  }

  private func split(mpls: Mpls, restFiles: Set<URL>, temporaryDirectory: URL) throws -> [ChocoMuxer.WorkTask] {
    logger.info("Splitting MPLS: \(mpls.fileName.lastPathComponent)")

    if restFiles.count == 0 {
      return []
    }

    let clips = try mpls.split(chapterPath: temporaryDirectory)

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
          return [.init(input: clip.fileName, main: .init(MkvMerge(global: .init(quiet: true, chapterFile: clip.chapterPath?.path), output: output.path, inputs: [.init(file: clip.m2tsPath.path)])), chapterSplit: false, canBeIgnored: false)]
        }

      } else {
        logger.info("Skipping clip: \(clip)")
        return []
      }
    }
  }

  private func generateFilename(mpls: Mpls) -> String {
    return "\(mpls.fileName.lastPathComponentWithoutExtension)-\(mpls.files.map { $0.lastPathComponentWithoutExtension }.joined(separator: "+").prefix(200))"
  }
}

fileprivate func generateMkvmergeSplit(split: ChocoSplit?, chapterCount: Int) -> MkvMerge.GlobalOption.Split? {
  guard let split = split else {
    return nil
  }
  func calculateChapIndex(_ block: () -> Int?) -> MkvMerge.GlobalOption.Split? {
    var chapIndex = [Int]()
    var chapCount = 0
    while let nextChapCount = block() {
      let nextChapIndex = nextChapCount + 1 + chapCount
      if nextChapIndex > chapterCount {
        break
      }
      chapIndex.append(nextChapIndex)
      chapCount += nextChapCount
    }
    guard !chapIndex.isEmpty else {
      return nil
    }
    return .chapters(.numbers(chapIndex))
  }
  switch split {
  case .everyChap(let everyChapCount):
    return calculateChapIndex { everyChapCount }
  case .eachChap(let eachChaps):
    var iterator = eachChaps.makeIterator()
    return calculateChapIndex { iterator.next() }
  }
}

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

struct ChocoVideoTrackInfo {
  let trackIndex: Int
  let trackIndexForSameType: Int
  let codec: String
  let lang: String
  let name: String
  let bitrate: Int
  let width: Int
  let height: Int
  let croppingMeta: CropInfo?
}

struct ChocoAudioTrackInfo {
  let trackIndex: Int
  let trackIndexForSameType: Int
  let codec: String
  let lang: String
  let name: String
  let bitrate: Int
}
