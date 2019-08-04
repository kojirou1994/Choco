import Foundation

public struct MplsChapter: CustomStringConvertible {
    /// unknown
    let unknownByte: UInt8
    /// 00  Resume mark
    /// 01  Bookmark, indicates a playback entry point
    /// 02  Skip mark, indicates a skip point
    let type: UInt8
    /// index of the PlayItem in which the mark exists
    public let playItemIndex: UInt16
    /// 45Khz time tick from the in_time of the referenced PlayItem
    let absoluteTimestamp: Timestamp
    let entryEsPid: UInt16
    /// Duration to skip when skip mark
    let skipDuration: UInt32
    
    public var relativeTimestamp: Timestamp
    
    public var description: String {
        return """
        playItemIndex: \(playItemIndex)
        relativeTimestamp: \(relativeTimestamp.description)
        absoluteTimestamp: \(absoluteTimestamp.description)
        """
    }
}
