import Foundation
import KwiftUtility
import ArgumentParser
import ExecutableLauncher

extension String {
  func caseInsensitiveStarts(with another: String) -> Bool {
    self.range(of: another, options: [.anchored, .caseInsensitive]) != nil
  }
}

enum Mp4TrackCodec: CaseIterable {
  case hevc
  case avc
  case flac
  case aac
  case ac3
  case eac3
  //  case sup
  case srt
  case trueHD
  case mp3

  static func matched(codec: String) -> Self? {
    allCases.first(where: { $0.match(codec: codec) })
  }

  private var codecs: [String] {
    switch self {
    case .avc:
      return ["MPEG-4p10/AVC/h.264"]
    case .hevc:
      return ["MPEG-H/HEVC/h.265"]
    case .flac:
      return ["FLAC"]
    case .aac:
      return ["AAC"]
    case .ac3:
      return ["AC-3"]
    case .eac3:
      return ["E-AC-3"]
    case .srt:
      return ["SubRip/SRT"]
    case .trueHD:
      return ["TrueHD Atmos"]
    case .mp3:
      return ["MP3"]
    }
  }

  var extractFileExtension: String {
    switch self {
    case .avc: return "264"
    case .hevc: return "265"
    case .flac: return "flac"
    case .aac: return "aac"
    case .ac3: return "ac3"
    case .eac3: return "eac3"
    case .srt: return "srt"
    case .trueHD: return "mlp"
    case .mp3: return "mp3"
    }
  }

  func match(codec: String) -> Bool {
    codecs.contains { codec.caseInsensitiveStarts(with: $0) }
  }
}

//enum MkvTrack {
//  case video(Video)
//  case audio(Audio)
//  case subtitle(Subtitle)
//  struct Video {
//    let fps: VideoRate
//    let path: String
//  }
//
//  struct Audio {
//    let lang: String
//    let path: String
//    let encodedPath: String
//    let needReencode: Bool
//
//    init(lang: String, path: String, needReencode: Bool) {
//      self.lang = lang
//      self.path = path
//      self.needReencode = needReencode
//      if needReencode {
//        self.encodedPath = path.deletingPathExtension.appendingPathExtension("m4a")
//      } else {
//        self.encodedPath = path
//      }
//    }
//  }
//
//  struct Subtitle {
//    let lang: String
//    let path: String
//    let type: SubtitleType
//    enum SubtitleType {
//      case ass
//      case srt
//      case pgs
//    }
//  }
//}

func remove(files: [String]) {
  files.forEach { (p) in
    try? FileManager.default.removeItem(atPath: p)
  }
}

//
//func toMp4(file: String, extractOnly: Bool) throws {
//
//  do {
//    let context = try FFmpegInputFormatContext.init(url: file)
//    try context.findStreamInfo()
//    //    context.dumpFormat(isOutput: false)
//    for stream in context.streams {
//      let codecParameters = stream.codecParameters
//      print(codecParameters.codecId)
//      if stream.mediaType == .video,
//         codecParameters.codecId == .h264,
//         invalidPixelFormats.contains(codecParameters.pixelFormat) {
//        throw Mp4Error.unsupportedPixelFormat(stream.codecParameters.pixelFormat)
//      }
//      if stream.mediaType == .video {
//        print(codecParameters.pixelFormat)
//      }
//    }
//  }
//
//  let mkvinfo = try MkvmergeIdentification.init(filePath: file)
//
//  // multi audio tracks mkv is not supported
//  //    guard mkvinfo.tracks.filter({$0.type == "audio"}).count < 2 else {
//  //        return
//  //    }
//
//  let mp4path = file.deletingPathExtension.appendingPathExtension("mp4")
//  remove(files: [mp4path])
//  let tempfile = UUID.init().uuidString.appendingPathExtension("mp4")
//  let chapterpPath = file.deletingPathExtension.appendingPathExtension("chap.txt")
//  var arguments = [file, "tracks"]
//  arguments.reserveCapacity(mkvinfo.tracks.count + 3)
//  var tracks = [MkvTrack]()
//  tracks.reserveCapacity(mkvinfo.tracks.count)
//  try mkvinfo.tracks.forEach { (track) in
//    print("\(track.id) \(track.codec) \(track.type)")
//
//    let trackExtension: String
//    var needReencode = false
//    switch track.codec {
//    case "MPEG-H/HEVC/h.265":
//      trackExtension = "265"
//    case "FLAC":
//      trackExtension = "flac"
//      needReencode = true
//    case "AAC":
//      trackExtension = "aac"
//    case "AC-3", "E-AC-3":
//      trackExtension = "ac3"
//    case "MPEG-4p10/AVC/h.264":
//      trackExtension = "264"
//    case "HDMV PGS":
//      trackExtension = "sup"
//    case "PCM":
//      trackExtension = "wav"
//      needReencode = true
//    case "SubStationAlpha":
//      trackExtension = "ass"
//    case "SubRip/SRT":
//      trackExtension = "srt"
//    case "TrueHD Atmos":
//      trackExtension = "truehd"
//      needReencode = true
//    case "DTS-HD Master Audio":
//      trackExtension = "dts"
//      needReencode = true
//    default:
//      throw Mp4Error.unsupportedCodec(track.codec)
//    }
//    let outputTrackName = "\(file.deletingPathExtension).\(track.id).\(track.properties.language ?? "und").\(trackExtension)"
//
//    switch track.type {
//    case .video:
//      let fpsValue = 1_000_000_000_000/UInt64(track.properties.defaultDuration!)
//      let fps: VideoRate
//      switch fpsValue {
//      case 23976:
//        fps = .k23_976
//      case 25000:
//        fps = .k25
//      case 29970:
//        fps = .k29_97
//      case 24000:
//        fps = .k24
//      case 50000:
//        fps = .k50
//      case 59940:
//        fps = .k59_94
//      default:
//        throw Mp4Error.unsupportedFps(fpsValue)
//      }
//      //            print(fps)
//      tracks.append(.video(.init(fps: fps, path: outputTrackName)))
//    case .audio:
//      tracks.append(.audio(.init(lang: track.properties.language ?? "und", path: outputTrackName, needReencode: needReencode)))
//    case .subtitles:
//      let type: MkvTrack.Subtitle.SubtitleType
//      switch track.codec {
//      case "HDMV PGS":
//        type = .pgs
//      case "SubStationAlpha":
//        type = .ass
//      case "SubRip/SRT":
//        type = .srt
//      default:
//        print("Invalid subtitle codec: \(track.codec)")
//        throw Mp4Error.unsupportedCodec(track.codec)
//      }
//      let extractedTrack = MkvTrack.subtitle(.init(lang: track.properties.language ?? "und", path: outputTrackName, type: type))
//    }
//
//    arguments.append("\(track.id):\(outputTrackName)")
//  }
//  //    print(arguments.joined(separator: " "))
//  //    dump(tracks)
//
//  arguments.append(contentsOf: ["chapters", "-s", chapterpPath])
//
//  // MARK: - mkvextract
//  print("Extracting tracks...")
//  try MKVextract(arguments: arguments).runAndWait(checkNonZeroExitCode: true, beforeRun: beforRun(p:), afterRun: afterRun(p:))
//  if extractOnly {
//    return
//  }
//  defer {
//    remove(files: tracks.flatMap({ (track) -> [String] in
//      switch track {
//      case .audio(let a): return [a.path, a.encodedPath]
//      case .video(let v): return [v.path]
//      default: return []
//      }
//    }))
//    remove(files: [tempfile, chapterpPath])
//  }
//  try tracks.forEach { (track) in
//    if case let MkvTrack.audio(a) = track, a.needReencode {
//      try FFmpeg(arguments: ["-v", "quiet", "-nostdin",
//                             "-y", "-i", a.path, "-c:a", "alac", a.encodedPath]).runAndWait(checkNonZeroExitCode: true, beforeRun: beforRun(p:), afterRun: afterRun(p:))
//    }
//  }
//  var boxArg = ["-tmp", "."]
//  tracks.forEach { (track) in
//    switch track {
//    case .audio(let a):
//      if a.lang != "und" {
//        boxArg.append(contentsOf: ["-add", "\(a.encodedPath):lang=\(a.lang)"])
//      } else {
//        boxArg.append(contentsOf: ["-add", a.encodedPath])
//      }
//    case .video(let v):
//      boxArg.append(contentsOf: ["-add", v.path, "-fps", v.fps.description])
//    default:
//      break
//    }
//  }
//
//  boxArg.append(tempfile)
//  try MP4Box(arguments: boxArg).runAndWait(checkNonZeroExitCode: true, beforeRun: beforRun(p:), afterRun: afterRun(p:))
//  var remuxerArg: [String]
//  if FileManager.default.fileExists(atPath: chapterpPath) {
//    remuxerArg = ["--chapter", chapterpPath]
//  } else {
//    remuxerArg = []
//  }
//  remuxerArg.append(contentsOf: ["-i", "\(tempfile)?1:handler=", "-o", mp4path])
//  try LsmashRemuxer(arguments: remuxerArg).runAndWait(checkNonZeroExitCode: true, beforeRun: beforRun(p:), afterRun: afterRun(p:))
//}

import URLFileManager
import MediaTools
import Logging
import MediaUtility

extension Chapter {
  /*
   ref: https://forum.doom9.org/showthread.php?t=158296
   */
  public func exportApple() -> String {
    let samples = nodes.enumerated().map { node in
      "<TextSample sampleTime=\"\(node.element.timestamp.description)\">\(node.element.title)</TextSample>"
    }.joined(separator: "\n")

    return """
    <?xml version="1.0" encoding="UTF-8" ?>
    <!-- GPAC 3GPP Text Stream -->
    <TextStream version="1.1">
    <TextStreamHeader width="480" height="368" layer="0" translation_x="0" translation_y="0">
    <TextSampleDescription horizontalJustification="center" verticalJustification="bottom" backColor="0 0 0 0" verticalText="no" fillTextRegion="no" continuousKaraoke="no" scroll="None">
    <FontTable>
    <FontTableEntry fontName="Arial" fontID="1"/>
    </FontTable>
    <TextBox top="0" left="0" bottom="368" right="480"/>
    <Style styles="Normal" fontID="1" fontSize="32" color="ff ff ff ff"/>
    </TextSampleDescription>
    </TextStreamHeader>
    \(samples)
    </TextStream>
    """

  }
}

extension Resolution {
  var par: String {
    var num = self.width
    var den = self.height
    let limit = min(num, den)
    if num == 0 || den == 0 || limit == 1 || num == den {
      return "1:1"
    } else {
      for number in 2..<limit {
        while num % number == 0, den % number == 0 {
          num = num / number
          den = den / number
        }
      }
      return "\(num):\(den)"
    }
  }
}

extension MkvMergeIdentification.Track {

  var importLanguage: String? {
    switch self.type {
    case .video:
      return nil
    default:
      return properties.language == "und" ? nil : properties.language
    }
  }

  var extractFileExtension: String {
    Mp4TrackCodec.matched(codec: codec)?.extractFileExtension ?? ""
  }

  var supportsMp4: Bool {
    Mp4TrackCodec.matched(codec: codec) != nil
  }
  /*
   DAR: Display Aspect Ratio
   SAR: Sample Aspect Ratio

   DAR = Resolution * SAR
   */
  var par: String? {
    if let pixelDimensions = properties.pixelDimensions,
       let displayDimensions = properties.displayDimensions {
      let pixelResolution = Resolution(pixelDimensions)!
      let displayResolution = Resolution(displayDimensions)!
      if pixelResolution != displayResolution {
        return Resolution(width: pixelResolution.height * displayResolution.width,
                          height: pixelResolution.width * displayResolution.height)
          .par
      }
    }
    return nil
  }
}

let fm = URLFileManager.default
var logger = Logger(label: "mkv-to-mp4")

struct MkvToMp4: ParsableCommand {

  static var configuration: CommandConfiguration {
    .init(subcommands: [Check.self, Mux.self])
  }

  struct Check: ParsableCommand {
    @Argument
    var inputs: [String]

    func run() throws {
      inputs.forEach { input in
        logger.info("Open input: \(input)")
        let succ = fm.forEachContent(in: URL(fileURLWithPath: input), handleFile: true, handleDirectory: false, skipHiddenFiles: true) { fileURL in
          guard fileURL.pathExtension.lowercased() == "mkv" else {
            return
          }
          do {
            logger.info("Checking file: \(fileURL.path)")
            let info = try MkvMergeIdentification(url: fileURL)
            let unsupportedTracks = info.tracks.filter { !$0.supportsMp4 }
            if unsupportedTracks.isEmpty {
              logger.info("OK")
            } else {
              logger.error("Some tracks is not supported by mp4.")
              for track in unsupportedTracks {
                logger.info("\(track)")
              }
            }
          } catch {
            logger.error("Failed to read! Error: \(error)")
          }
        }
        if !succ {
          logger.error("Cannot open input: \(input)")
        }
      }
    }
  }

  struct Mux: ParsableCommand {
    //  @Flag()
    //  var extractOnly = false

    @Argument
    var inputs: [String]

    //  @Flag
    //  var recursive: Bool = false

    @Flag
    var overwrite: Bool = false

    @Flag
    var verbose: Bool = false

    @Flag
    var keepTrackName: Bool = false

    @Option
    var tmp: String = "./tmp"

    @Option(help: "MP4Box tmp dir, if not set, tmp is used")
    var mp4Tmp: String?

    @Option
    var output: String = "./"

    @Option
    var undAudioLang: String?

    mutating func validate() throws {
      if verbose {
        logger.logLevel = .debug
      }
    }

    func run() throws {
      inputs.forEach { input in
        logger.info("Open input: \(input)")
        let succ = fm.forEachContent(in: URL(fileURLWithPath: input), handleFile: true, handleDirectory: false, skipHiddenFiles: true) { fileURL in
          guard fileURL.pathExtension.lowercased() == "mkv" else {
            return
          }
          do {
            logger.info("Remuxing file: \(fileURL.path)")
            try convert(file: fileURL)
          } catch {
            logger.error("Failed to remux! Error: \(error)")
          }
        }
        if !succ {
          logger.error("Cannot open input: \(input)")
        }
      }

    }

    func convert(file: URL) throws {
      let info = try MkvMergeIdentification(url: file)
      let outputFileURL = URL(fileURLWithPath: output).appendingPathComponent(file.deletingPathExtension().lastPathComponent).appendingPathExtension("mp4")

      try preconditionOrThrow(!fm.fileExistance(at: outputFileURL).exists, "Output already existed!")

      let tempDir = URL(fileURLWithPath: tmp)

      func tempFileURL(pathExtension: String) -> URL {
        tempDir
          .appendingPathComponent(UUID().uuidString)
          .appendingPathExtension(pathExtension)
      }

      let supportedTracks = info.tracks
        .enumerated()
        .filter { $0.element.supportsMp4 }

      try preconditionOrThrow(supportedTracks.filter{$0.element.type == .video}.count == 1,
                              "Must have exactly 1 video track!")

      let extractedTracks = supportedTracks.map { _, track in
        tempFileURL(pathExtension: track.extractFileExtension)
      }

      var extractions: [MkvExtractionMode] = [
        .tracks(.init(outputs: zip(supportedTracks, extractedTracks)
                        .map { .init(trackID: $0.0.offset, filename: $0.1.path) }))
      ]

      let extractedChapterFileURL: URL?
      let hasChapter = !info.chapters.isEmpty
      if hasChapter {
        extractedChapterFileURL = tempFileURL(pathExtension: "txt")
        extractions.append(.chapter(.init(simple: true, outputFilename: extractedChapterFileURL!.path)))
      } else {
        extractedChapterFileURL = nil
      }

      let launcher = TSCExecutableLauncher(outputRedirection: .collect)

      logger.info("Extracting...")
      let extractor = MkvExtract(
        filepath: file.path,
        extractions: extractions)
      let extractionResult = try extractor.launch(use: launcher)
      defer {
        logger.info("Removing extracted tracks")
        extractedTracks.forEach { fileURL in
          try? fm.removeItem(at: fileURL)
        }
      }
      logger.debug("mkvextract output:\n\((try? extractionResult.utf8Output()) ?? "")")

      logger.info("Muxing...")
      var importings = zip(supportedTracks, extractedTracks).map { track, trackFile -> MP4Box.FileImporting in
        var lang = track.element.importLanguage
        if lang == nil {
          switch track.element.type {
          case .audio:
            lang = undAudioLang
          default:
            break
          }
        }
        var name: String?
        if keepTrackName {
          name = track.element.properties.trackName
        }
        var hdlr: String?
        var layout: String?
        if Mp4TrackCodec.matched(codec: track.element.codec) == .srt {
          hdlr = "sbtl"
          layout = "-1"
        }
        var group: Int?
        if track.element.type == .audio {
          group = 1
        }
        return MP4Box.FileImporting(filename: trackFile.path, trackSelection: nil, name: name ?? "", fps: nil, group: group, par: track.element.par, language: lang, isChapter: false, hdlr: hdlr, layout: layout)
      }
      if let chapterFileURL = extractedChapterFileURL,
         case let chapter = try Chapter(ogmFileURL: chapterFileURL),
         !chapter.isEmpty {
        let appleChapterFileURL = tempFileURL(pathExtension: "ttxt")
        try chapter.exportApple().write(to: appleChapterFileURL, atomically: true, encoding: .utf8)
        importings.append(.init(filename: appleChapterFileURL.path, trackSelection: nil, name: "", fps: nil, group: nil, par: nil, language: nil, isChapter: true, hdlr: nil, layout: nil))

      }

      let muxer = MP4Box(importings: importings,
                         tmp: mp4Tmp ?? tmp, output: outputFileURL.path)
      logger.debug("MP4Box arguments: \(muxer.arguments)")
      let muxerResult = try muxer.launch(use: launcher)
      logger.debug("MP4Box output:\n\((try? muxerResult.utf8Output()) ?? "")")

    }
  }
}

func changeFilename(origin: String) -> String {
  let lowercased = origin.lowercased()
  if lowercased.contains("flac") {
    return origin.replacingOccurrences(of: "flac", with: "alac")
      .replacingOccurrences(of: "Flac", with: "Alac")
      .replacingOccurrences(of: "FLAC", with: "ALAC")
    //                     .replacingOccurrences(of: "flac", with: "alac")
  } else {
    return origin
  }
}

MkvToMp4.main()
