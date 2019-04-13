//
//  AVPacket.swift
//  SwiftFFmpeg
//
//  Created by sunlubo on 2018/6/29.
//

import CFFmpeg

// MARK: - AVPacketFlag

public struct AVPacketFlag: OptionSet {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    /// The packet contains a keyframe
    public static let key = AVPacketFlag(rawValue: AV_PKT_FLAG_KEY)
    /// The packet content is corrupted
    public static let corrupt = AVPacketFlag(rawValue: AV_PKT_FLAG_CORRUPT)
    /// Flag is used to discard packets which are required to maintain valid decoder state
    /// but are not required for output and should be dropped after decoding.
    public static let discard = AVPacketFlag(rawValue: AV_PKT_FLAG_DISCARD)
    /// The packet comes from a trusted source.
    ///
    /// Otherwise-unsafe constructs such as arbitrary pointers to data outside the packet may be followed.
    public static let trusted = AVPacketFlag(rawValue: AV_PKT_FLAG_TRUSTED)
    /// Flag is used to indicate packets that contain frames that can be discarded by the decoder.
    /// I.e. Non-reference frames.
    public static let disposable = AVPacketFlag(rawValue: AV_PKT_FLAG_DISPOSABLE)
}
