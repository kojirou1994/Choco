import IOModule
import Precondition
import MediaUtility
import Foundation
import IOStreams

public enum StreamType: UInt8 {
  case reserved = 0
  case usedByPlayItem = 1
  case usedBySubPathType23456 = 2
  case usedBySubPathType7 = 3
  case sameWith2 = 4
}

public enum MplsReadError: Error {
  case invalidMplsHeader(UInt32)
  case invalidVersionHeader(UInt32)
  case invalidCodec(UInt8)
  case invalidCharacterCode(UInt8)
  case invalidAudioFormat(UInt8)
  case invalidVideoFormat(UInt8)
  case invalidAudioRate(UInt8)
  case invalidVideoRate(UInt8)
  case invalidSubPathType(UInt8)
}

extension Read {
  mutating func readTimestamp() throws -> Timestamp {
    try Timestamp(mpls: readInteger())
  }
}

struct MplsMark {
  static let mplsHeader: UInt32 = 0x4d504c53 // "MPLS"
  static let mplsVersionAHeader: UInt32 = 0x30323030 // "0200"
  static let mplsVersionBHeader: UInt32 = 0x30313030 // "0100"
  static let mplsVersionCHeader: UInt32 = 0x30333030 // "0300"

  static let ChapterMark: [UInt8] = [0xff, 0xff, 0x00, 0x00, 0x00, 0x00]
  static let SearchM2TS: [UInt8] = [0x4d, 0x32, 0x54, 0x53]//"M2TS"
  static let VideoAttMark: [UInt8] = [0x05, 0x1b]
  static let PlayMarkType: UInt8 = 0x01
}

extension MplsPlaylist {

  public static func parse(mplsContents: Data) throws -> Self {
    var reader = MemoryInputStream(mplsContents)
    return try parse(&reader)
  }


  public static func parse<T>(_ reader: inout T) throws -> Self where T: Read, T: Seek {

    // MARK: parse header
    do {
      let mplsHeader = try reader.readInteger() as UInt32
      guard mplsHeader == MplsMark.mplsHeader else {
        throw MplsReadError.invalidMplsHeader(mplsHeader)
      }
    }
    do {
      let versionHeader = try reader.readInteger() as UInt32
      guard versionHeader == MplsMark.mplsVersionAHeader ||
              versionHeader == MplsMark.mplsVersionBHeader ||
              versionHeader == MplsMark.mplsVersionCHeader else {
        throw MplsReadError.invalidVersionHeader(versionHeader)
      }
    }
    // MARK: parse indexes
    let playlistStartIndex = try reader.readInteger() as UInt32
    let chapterStartIndex = try reader.readInteger() as UInt32
    let extensionDataStartIndex = try reader.readInteger() as UInt32

    // go to playlist start index
    try reader.seek(toOffset: numericCast(playlistStartIndex), from: .start)

    // MARK: parse play items
    try reader.skip(4) // playlistLength
    // reserved
    try reader.skip(2)

    let playItemCount = try reader.readInteger() as UInt16
    let subPathCount = try reader.readInteger() as UInt16
    var duration = Timestamp.init(ns: 0)

    var playItems = [MplsPlayItem]()
    for _ in 0..<playItemCount {
      // PlayItem Length
      let playItemLength = try reader.readInteger() as UInt16
      let currentIndex = try reader.currentOffset()

      // Primary Clip identifer
      let clipId = try reader.readString(byteCount: 5)
      // skip the redundant "M2TS" CodecIdentifier
      let codecId = try reader.readString(byteCount: 4)
      precondition(codecId == "M2TS", "codec id is not M2TS")
      /// reserved 11 bits + isMultiAngle 1 bit + connectionCondition 4 bits
      let combined = try reader.readInteger() as UInt16
      let isMultiAngle = (combined << 11) >> 15 == 1
      let connectionCondition = UInt8.init(truncatingIfNeeded: (combined << 12) >> 12)
//      precondition([0x01, 0x05, 0x06].contains(connectionCondition), "invalid connection condition")
      let stcId = try reader.readByte()
      let inTime = try reader.readTimestamp()
      let outTime = try reader.readTimestamp()

      try reader.skip(8) // uoMaskTable
      /// random_access_flag  1 bit + reserved 7bits
      _ = try (reader.readByte() & 0b10000000) != 0 // randomAccessFlag
      let stillMode = try reader.readByte()
      if stillMode == 1 {
        try reader.skip(2) // stillTime
      } else {
        //reserved
        try reader.skip(2)
      }
      let multiAngle: MultiAngle
      if isMultiAngle {
        let numAngles = try reader.readByte()
        // reserved 6 bits + isDifferentAudio 1 bit + isSeamlessAngleChange 1 bit
        let combined = try reader.readByte()
        let isDifferentAudio = (combined & 0b00000010) != 0
        let isSeamlessAngleChange = (combined & 0b00000001) != 0
        var angles = [MultiAngleData.Angle]()
        for _ in 1..<numAngles {
          let clipId = try reader.readString(byteCount: 5)
          let clipCodecId = try reader.readString(byteCount: 4)
          precondition(clipCodecId == "M2TS", "clip codec id is not M2TS")
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
        video.append(try .parse(&reader))
      }

      var audio = [MplsStream]()
      audio.reserveCapacity(Int(numPrimaryAudio))
      for _ in 0..<numPrimaryAudio {
        audio.append(try .parse(&reader))
      }

      var pg = [MplsStream]()
      pg.reserveCapacity(Int(numPg))
      for _ in 0..<numPg {
        pg.append(try .parse(&reader))
      }

      try reader.seek(toOffset: currentIndex + Int64(playItemLength), from: .start)

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
      _ = try reader.readInteger() as UInt32 // length
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
        let clpiFilename = try reader.readString(byteCount: 5)
        let codecId = try reader.readString(byteCount: 4)
        try reader.skip(3)
        let two = try reader.readByte()
        let connectionCondition = (two & 0b0001_1110) >> 1
        let isMultiClipEntries = (two & 0b0000_0001) == 1
        let refToStcId = try reader.readByte()
        let inTime = try reader.readTimestamp()
        let outTime = try reader.readTimestamp()
        let syncPlayItemId = try reader.readInteger() as UInt16
        let syncStartPtsOfPlayItem = try reader.readTimestamp()
        var clips = [SubPlayItemClip]()
        if isMultiClipEntries {
          let numClips = try reader.readByte()
          try reader.skip(1)
          for _ in 1..<numClips {
            let clpiFilename = try reader.readString(byteCount: 5)
            let codecId = try reader.readString(byteCount: 4)
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
    try reader.seek(toOffset: Int64(chapterStartIndex), from: .start)
    try reader.skip(4) //chapterLength
    let chapterCount = try reader.readInteger() as UInt16

    var chapters = [MplsChapter]()

    for _ in 0..<chapterCount {
      let markId = try reader.readByte()
      let chapterType = try reader.readByte()
      let playItemIndex = try reader.readInteger() as UInt16
      let absoluteTimestamp = try reader.readTimestamp()
      let entryEsPid = try reader.readInteger() as UInt16
      let skipDuration = try reader.readInteger() as UInt32
      let playItem = playItems[Int(playItemIndex)]
      if chapterType != 1 {
        continue
      }
      guard absoluteTimestamp >= playItem.inTime,
            absoluteTimestamp <= playItem.outTime else {
              print("invalid timestamp found, chapters is disabled!")
              chapters = []
              break
            }
      chapters.append(.init(unknownByte: markId, type: chapterType, playItemIndex: playItemIndex,
                            absoluteTimestamp: absoluteTimestamp, entryEsPid: entryEsPid, skipDuration: skipDuration,
                            relativeTimestamp: absoluteTimestamp - playItem.inTime + playItem.relativeInTime))
    }
    //    print(reader.isAtEnd)

    return .init(playlistStartIndex: playlistStartIndex, chapterStartIndex: chapterStartIndex, extensionDataStartIndex: extensionDataStartIndex,
                 playItemCount: playItemCount, subPathCount: subPathCount, chapterCount: chapterCount,
                 playItems: playItems, subPaths: subPaths, chapters: chapters, duration: duration)
  }

}

extension MplsStream {

  internal static func parse<T>(_ handle: inout T) throws -> Self where T: Read, T: Seek {
    var length = try handle.readByte()
    var currentIndex = try handle.currentOffset()// >> 3
    let streamType = try StreamType(rawValue: handle.readByte()).unwrap("Invalid Stream Type")
    //        "unrecognized stream type %02x\n", s->stream_type)
    let pid: UInt16
    var subPathId: UInt8?
    var subClipId: UInt8?
    switch streamType {
    case .usedByPlayItem:
      pid = try handle.readInteger() as UInt16
    case .usedBySubPathType23456, .sameWith2:
      subPathId = try handle.readByte()
      subClipId = try handle.readByte()
      pid = try handle.readInteger() as UInt16
    case .usedBySubPathType7:
      subPathId = try handle.readByte()
      pid = try handle.readInteger() as UInt16
    case .reserved:
      fatalError("\(#function), \(#fileID), \(#line)")
    }
    try handle.seek(toOffset: currentIndex + Int64(length), from: .start)
    length = try handle.readByte()
    currentIndex = try handle.currentOffset()

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
      let language = try handle.readString(byteCount: 3)
      attribute = try.audio(.init(format: .init(value: format), rate: .init(value: rate), language: fixLanguage(language)))
    } else if codec.isGraphics {
      let language = try handle.readString(byteCount: 3)
      attribute = .pgs(.init(language: fixLanguage(language)))
    } else if codec.isText {
      let charCode = try handle.readByte()
      let language = try handle.readString(byteCount: 3)
      attribute = try .textsubtitle(.init(charCode: .init(value: charCode), language: fixLanguage(language)))
    } else {
      fatalError("\(#function), \(#fileID), \(#line)")
    }
    try handle.seek(toOffset: currentIndex + Int64(length), from: .start)
    return .init(streamType: streamType, codec: codec, pid: pid,
                 subpathId: subPathId, subclipId: subClipId,
                 attribute: attribute)
  }

}

