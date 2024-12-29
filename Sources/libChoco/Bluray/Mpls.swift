import Foundation
import MplsParser
import MediaTools

extension MplsPlayItem {
  var langs: [String] {
    //        return [stn.video + stn.audio + stn.pg].joined().map{ $0.attribute.lang }
    var result = [String]()
    result.append(contentsOf: stn.video.map {$0.attribute.lang})
    for audio in stn.audio {
      result.append(audio.attribute.lang)
      if audio.codec == .trueHD {
        result.append(audio.attribute.lang)
      }
    }
    result.append(contentsOf: stn.pg.map {$0.attribute.lang})
    return result
  }
}

public struct Mpls {

  public let chapterCount: Int

  public let duration: Timestamp

  public let files: [URL]

  public let size: UInt

  public let fileName: URL

  public let trackLangs: [String]

  public let compressed: Bool

  public init(filePath: String) throws {
    let mkvid = try MkvMergeIdentification(filePath: filePath)
    try self.init(mkvid)
  }

  public init(_ info: MkvMergeIdentification) throws {
    guard let size = info.container?.properties?.playlistSize,
          let files = info.container?.properties?.playlistFile,
          let durationValue = info.container?.properties?.playlistDuration else {
      throw ChocoError.errorReadingFile
      fatalError("Invalid MPLS: \(info)")
    }

    if files.count == 0 {
      print("No files?")
      print("MPLS: \(info)")
      fatalError()
    } else if case let fileSet = Set(files), fileSet.count < files.count {
      // contains repeated files
      compressed = true
      self.size = size / UInt(files.count)
      self.files = fileSet.sorted().map(URL.init(fileURLWithPath:))
      self.duration = .init(ns: 0)
      //                .init(ns: durationValue / UInt64(files.count))
    } else {
      compressed = false
      self.size = size
      self.files = files.map(URL.init(fileURLWithPath:))
      self.duration = .init(ns: UInt64(durationValue))
    }
    trackLangs = info.tracks?.map { $0.properties?.language ?? "und" } ?? []
    fileName = URL(fileURLWithPath: info.fileName!)
    chapterCount = Int(info.container?.properties?.playlistChapters ?? 0)
  }

}

extension Mpls: Comparable, Equatable, CustomStringConvertible {

  public var description: String {
    """
    fileName: \(fileName.lastPathComponent)
    files:
    \(files.map {" - " + $0.lastPathComponent}.joined(separator: "\n"))
    chapterCount: \(chapterCount)
    size: \(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
    duration: \(duration.description)
    trackLangs: \(trackLangs)
    compressed: \(compressed)
    """
  }

  public static func < (lhs: Mpls, rhs: Mpls) -> Bool {
    lhs.fileName.lastPathComponent < rhs.fileName.lastPathComponent
  }

  public static func == (lhs: Mpls, rhs: Mpls) -> Bool {
    (lhs.duration, lhs.size, lhs.files, lhs.trackLangs) == (rhs.duration, rhs.size, rhs.files, rhs.trackLangs)
  }
}

