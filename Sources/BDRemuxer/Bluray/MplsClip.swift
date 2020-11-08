import Foundation
import MplsParser

public struct MplsClip {
  public let fileName: URL
  public let duration: Timestamp
  public let trackLangs: [String]
  public let m2tsPath: URL
  public let chapterPath: URL?
  public let index: Int?

  public init(fileName: URL, duration: Timestamp, trackLangs: [String], m2tsPath: URL, chapterPath: URL?, index: Int?) {
    self.fileName = fileName
    self.duration = duration
    self.trackLangs = trackLangs
    self.m2tsPath = m2tsPath
    self.chapterPath = chapterPath
    self.index = index
  }
}

extension MplsClip: CustomStringConvertible {

  public var description: String {
    "\(fileName.lastPathComponent) -> \(m2tsPath.lastPathComponent) -> \(chapterPath?.path ?? "no chapter file.")"
  }

}


