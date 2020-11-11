import Foundation
import KwiftUtility
import KwiftExtension

public enum StreamType: UInt8 {
  case reserved = 0
  case usedByPlayItem = 1
  case usedBySubPathType23456 = 2
  case usedBySubPathType7 = 3
  case sameWith2 = 4
}

public enum MplsReadError: Error {
  case noMplsHeader(Data)
  case noVersionHeader(Data)
  case invalidCodec(UInt8)
  case invalidCharacterCode(UInt8)
  case invalidAudioFormat(UInt8)
  case invalidVideoFormat(UInt8)
  case invalidAudioRate(UInt8)
  case invalidVideoRate(UInt8)
  case invalidSubPathType(UInt8)
}

struct MplsMark {
  static let mplsHeader: [UInt8] = [0x4d, 0x50, 0x4c, 0x53] // "MPLS"
  static let mplsVersionAHeader: [UInt8] = [0x30, 0x32, 0x30, 0x30] // "0200"
  static let mplsVersionBHeader: [UInt8] = [0x30, 0x31, 0x30, 0x30] // "0100"
  static let mplsVersionCHeader: [UInt8] = [0x30, 0x33, 0x30, 0x30] // "0300"

  static let ChapterMark: [UInt8] = [0xff, 0xff, 0x00, 0x00, 0x00, 0x00]
  static let SearchM2TS: [UInt8] = [0x4d, 0x32, 0x54, 0x53]//"M2TS"
  static let VideoAttMark: [UInt8] = [0x05, 0x1b]
  static let PlayMarkType: UInt8 = 0x01
}

typealias DataHandle = ByteReader<Data>

extension MplsPlaylist {


  public static func parse(mplsURL: URL) throws -> Self {
    var reader = try autoreleasepool {
      try DataHandle(.init(contentsOf: mplsURL))
    }

    // MARK: parse header
    let mpls = try reader.read(4)
    guard mpls.elementsEqual(MplsMark.mplsHeader) else {
      throw MplsReadError.noMplsHeader(mpls)
    }
    let versionHeader = try reader.read(4)
    guard versionHeader.elementsEqual(MplsMark.mplsVersionAHeader) ||
            versionHeader.elementsEqual(MplsMark.mplsVersionBHeader) ||
            versionHeader.elementsEqual(MplsMark.mplsVersionCHeader) else {
      throw MplsReadError.noVersionHeader(versionHeader)
    }
    // MARK: parse indexes
    let playlistStartIndex = try reader.read(4).joined(UInt32.self)
    let chapterStartIndex = try reader.read(4).joined(UInt32.self)
    let extensionDataStartIndex = try reader.read(4).joined(UInt32.self)

    // go to playlist start index
    try reader.seek(to: Int(playlistStartIndex))

    // MARK: parse play items
    try reader.skip(4) // playlistLength
    // reserved
    try reader.skip(2)

    let playItemCount = try reader.read(2).joined(UInt16.self)
    let subPathCount = try reader.read(2).joined(UInt16.self)
    var duration = Timestamp.init(ns: 0)

    var playItems = [MplsPlayItem]()
    for _ in 0..<playItemCount {
      // PlayItem Length
      let playItemLength = try reader.read(2).joined(UInt16.self)
      let currentIndex = reader.readerOffset

      // Primary Clip identifer
      let clipId = String.init(decoding: try reader.read(5), as: UTF8.self)
      // skip the redundant "M2TS" CodecIdentifier
      let codecId = String.init(decoding: try reader.read(4), as: UTF8.self)
      precondition(codecId == "M2TS")
      /// reserved 11 bits + isMultiAngle 1 bit + connectionCondition 4 bits
      let combined = try reader.read(2).joined(UInt16.self)
      let isMultiAngle = (combined << 11) >> 15 == 1
      let connectionCondition = UInt8.init(truncatingIfNeeded: (combined << 12) >> 12)
      precondition([0x01, 0x05, 0x06].contains(connectionCondition))
      let stcId = try reader.read(1).joined(UInt8.self)
      let inTime = try Timestamp(mpls: UInt64(reader.read(4).joined(UInt32.self)))
      let outTime = try Timestamp(mpls: UInt64(reader.read(4).joined(UInt32.self)))

      try reader.skip(8) // uoMaskTable
      /// random_access_flag  1 bit + reserved 7bits
      _ = try (reader.readByte() & 0b10000000) != 0 // randomAccessFlag
      let stillMode = try reader.readByte()
      if stillMode == 1 {
        _ = try reader.read(2) // stillTime
      } else {
        //reserved
        _ = try reader.read(2)
      }
      let multiAngle: MultiAngle
      if isMultiAngle {
        let numAngles = try reader.read(1).joined(UInt8.self)
        // reserved 6 bits + isDifferentAudio 1 bit + isSeamlessAngleChange 1 bit
        let combined = try reader.readByte()
        let isDifferentAudio = (combined & 0b00000010) != 0
        let isSeamlessAngleChange = (combined & 0b00000001) != 0
        var angles = [MultiAngleData.Angle]()
        for _ in 1..<numAngles {
          let clipId = String.init(decoding: try reader.read(5), as: UTF8.self)
          let clipCodecId = String.init(decoding: try reader.read(4), as: UTF8.self)
          precondition(clipCodecId == "M2TS")
          let stcId = try reader.readByte()
          angles.append(.init(clipId: clipId, clipCodecId: clipCodecId, stcId: stcId))
        }
        multiAngle = .yes(.init(isDifferentAudio: isDifferentAudio, isSeamlessAngleChange: isSeamlessAngleChange, angles: angles))
      } else {
        multiAngle = .no
      }

      // MARK: parse STN
      try reader.skip(2) // stnLength
      // Skip 2 reserved bytes
      try reader.skip(2)

      let numPrimaryVideo = try reader.readByte()
      let numPrimaryAudio = try reader.readByte()
      let numPg = try reader.readByte()
      let numIg = try reader.readByte()
      let numSecondaryAudio = try reader.readByte()
      let numSecondaryVideo = try reader.readByte()
      let numPipPg = try reader.readByte()

      // 5 reserve bytes
      try reader.skip(5)

      var video = [MplsStream]()
      video.reserveCapacity(Int(numPrimaryVideo))
      for _ in 0..<numPrimaryVideo {
        video.append(try .parse(from: &reader))
      }

      var audio = [MplsStream]()
      audio.reserveCapacity(Int(numPrimaryAudio))
      for _ in 0..<numPrimaryAudio {
        audio.append(try .parse(from: &reader))
      }

      var pg = [MplsStream]()
      pg.reserveCapacity(Int(numPg))
      for _ in 0..<numPg {
        pg.append(try .parse(from: &reader))
      }

      try reader.seek(to: currentIndex + Int(playItemLength))

      let stn = MplsPlayItemStn.init(numPrimaryVideo: numPrimaryVideo, numPrimaryAudio: numPrimaryAudio,
                                     numPg: numPg, numIg: numIg, numSecondaryAudio: numSecondaryAudio,
                                     numSecondaryVideo: numSecondaryVideo, numPipPg: numPipPg,
                                     video: video, audio: audio, pg: pg)

      playItems.append(.init(clipId: clipId, connectionCondition: connectionCondition,
                             stcId: stcId, inTime: inTime, outTime: outTime, relativeInTime: duration,
                             stn: stn, multiAngle: multiAngle))
      duration += outTime - inTime
    }

    // MARK: - parse subpath
    var subPaths: [MplsSubPath] = []
    for _ in 0..<subPathCount {
      _ = try reader.read(4).joined(UInt32.self) // length
      try  reader.skip(1) //reserved
      let subPathTypeValue = try reader.readByte()
      let subPathType = try SubPathType.init(value: subPathTypeValue)
      // reserved 15 bits + isRepeatSubPath 1 bit
      try reader.skip(1)
      let isRepeatSubPath = (try reader.readByte() & 0b00000001) == 1
      try reader.skip(1) // reserved
      let subPlayItemCount = try reader.readByte()
      var subPlayItems = [SubPlayItem]()
      for _ in 0..<subPlayItemCount {
        try reader.skip(2) //length
        let clpiFilename = String.init(decoding: try reader.read(5), as: UTF8.self)
        let codecId = String.init(decoding: try reader.read(4), as: UTF8.self)
        try reader.skip(3)
        let two = try reader.readByte()
        let connectionCondition = (two & 0b0001_1110) >> 1
        let isMultiClipEntries = (two & 0b0000_0001) == 1
        let refToStcId = try reader.readByte()
        let inTime = Timestamp.init(mpls: try reader.read(4).joined(UInt64.self))
        let outTime = Timestamp.init(mpls: try reader.read(4).joined(UInt64.self))
        let syncPlayItemId = try reader.read(2).joined(UInt16.self)
        let syncStartPtsOfPlayItem = Timestamp.init(mpls: try reader.read(4).joined(UInt64.self))
        var clips = [SubPlayItemClip]()
        if isMultiClipEntries {
          let numClips = try reader.readByte()
          try reader.skip(1)
          for _ in 1..<numClips {
            let clpiFilename = String.init(decoding:try  reader.read(5), as: UTF8.self)
            let codecId = String.init(decoding:try  reader.read(4), as: UTF8.self)
            let refToStcId = try reader.readByte()
            clips.append(SubPlayItemClip.init(clpiFilename: clpiFilename, codecId: codecId, refToStcId: refToStcId))
          }
        }
        subPlayItems.append(.init(
                              clpiFilename: clpiFilename, codecId: codecId, connectionCondition: connectionCondition,
                              syncPlayItemId: syncPlayItemId, refToStcId: refToStcId, isMultiClipEntries: isMultiClipEntries,
                              inTime: inTime, outTime: outTime, syncStartPtsOfPlayItem: syncStartPtsOfPlayItem, clips: clips))
      }
      subPaths.append(.init(type: subPathType, isRepeatSubPath: isRepeatSubPath, items: subPlayItems))
    }

    // MARK: parse Chapters
    try reader.seek(to: Data.Index(chapterStartIndex))
    try reader.skip(4) //chapterLength
    let chapterCount = try reader.read(2).joined(UInt16.self)

    var chapters = [MplsChapter]()

    for _ in 0..<chapterCount {
      let markId = try reader.readByte()
      let chapterType = try reader.readByte()
      let playItemIndex = try reader.read(2).joined(UInt16.self)
      let absoluteTimestamp = Timestamp.init(mpls: UInt64(try reader.read(4).joined(UInt32.self)))
      let entryEsPid = try reader.read(2).joined(UInt16.self)
      let skipDuration = try reader.read(4).joined(UInt32.self)
      let playItem = playItems[Int(playItemIndex)]
      if chapterType != 1 {
        continue
      }
      chapters.append(.init(unknownByte: markId, type: chapterType, playItemIndex: playItemIndex,
                            absoluteTimestamp: absoluteTimestamp, entryEsPid: entryEsPid, skipDuration: skipDuration,
                            relativeTimestamp: absoluteTimestamp - playItem.inTime + playItem.relativeInTime))
    }
    //    print(reader.isAtEnd)

    return .init(mplsURL: mplsURL, playlistStartIndex: playlistStartIndex, chapterStartIndex: chapterStartIndex, extensionDataStartIndex: extensionDataStartIndex,
                 playItemCount: playItemCount, subPathCount: subPathCount, chapterCount: chapterCount,
                 playItems: playItems, subPaths: subPaths, chapters: chapters, duration: duration)
  }

}

extension MplsStream {

  internal static func parse(from handle: inout DataHandle) throws -> Self {
    var length = try handle.readByte()
    var currentIndex = handle.readerOffset// >> 3
    let streamType = try StreamType(rawValue: handle.readByte()).unwrap("Invalid Stream Type")
    //        "unrecognized stream type %02x\n", s->stream_type)
    let pid: UInt16
    var subPathId: UInt8?
    var subClipId: UInt8?
    switch streamType {
    case .usedByPlayItem:
      pid = try handle.read(2).joined(UInt16.self)
    case .usedBySubPathType23456, .sameWith2:
      subPathId = try handle.readByte()
      subClipId = try handle.readByte()
      pid = try handle.read(2).joined(UInt16.self)
    case .usedBySubPathType7:
      subPathId = try handle.readByte()
      pid = try handle.read(2).joined(UInt16.self)
    case .reserved:
      fatalError()
    }
    try handle.seek(to: currentIndex + Int(length))
    length = try handle.readByte()
    currentIndex = handle.readerOffset

    let codec = try Codec(value: handle.readByte())

    let attribute: StreamAttribute

    func fixLanguage(_ str: String) -> String {
      switch str {
      case "deu":
        return "ger"
      case "zho":
        return "chi"
      default:
        return str
      }
    }

    if codec.isVideo {
      let combined = try handle.readByte()
      let format = combined >> 4
      let rate = combined & 0b00001111
      attribute = try .video(.init(format: .init(value: format), rate: .init(value: rate)))
    } else if codec.isAudio {
      let combined = try handle.readByte()
      let format = combined >> 4
      let rate = combined & 0b00001111
      let language = try handle.readString(3)
      attribute = try.audio(.init(format: .init(value: format), rate: .init(value: rate), language: fixLanguage(language)))
    } else if codec.isGraphics {
      let language = try handle.readString(3)
      attribute = .pgs(.init(language: fixLanguage(language)))
    } else if codec.isText {
      let charCode = try handle.readByte()
      let language = try handle.readString(3)
      attribute = try .textsubtitle(.init(charCode: .init(value: charCode), language: fixLanguage(language)))
    } else {
      fatalError()
    }
    try handle.seek(to: currentIndex + Int(length))
    return .init(streamType: streamType, codec: codec, pid: pid,
                 subpathId: subPathId, subclipId: subClipId,
                 attribute: attribute)
  }

}
