//
//  FFmpegChannelLayout.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/15.
//

import Foundation
import CFFmpeg

public struct FFmpegChannelLayout: Equatable, CustomStringConvertible {
    public let rawValue: UInt64
    
    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
    
    /// Return a channel layout id that matches name, or 0 if no match is found.
    ///
    /// - Parameter name: Name can be one or several of the following notations, separated by '+' or '|':
    ///   - the name of an usual channel layout (mono, stereo, 4.0, quad, 5.0, 5.0(side), 5.1, 5.1(side), 7.1,
    ///     7.1(wide), downmix);
    ///   - the name of a single channel (FL, FR, FC, LFE, BL, BR, FLC, FRC, BC, SL, SR, TC, TFL, TFC, TFR, TBL,
    ///     TBC, TBR, DL, DR);
    ///   - a number of channels, in decimal, followed by 'c', yielding the default channel layout for that number
    ////    of channels (@see av_get_default_channel_layout);
    ///   - a channel layout mask, in hexadecimal starting with "0x" (see the AV_CH_* macros).
    ///
    ///     Example: "stereo+FC" = "2c+FC" = "2c+1c" = "0x7"
    public init(name: String) {
        self.init(rawValue: av_get_channel_layout(name))
    }
    
    /// Return the number of channels in the channel layout.
    public var channelCount: Int {
        return Int(av_get_channel_layout_nb_channels(rawValue))
    }
    
    public var description: String {
        let buf = UnsafeMutablePointer<Int8>.allocate(capacity: 256)
        buf.initialize(to: 0)
        defer { buf.deallocate() }
        av_get_channel_layout_string(buf, 256, Int32(channelCount), rawValue)
        return String(cString: buf)
    }
    
    /// Get the index of a channel in channel_layout.
    ///
    /// - Parameter channel: a channel layout describing exactly one channel which must be present in channel_layout.
    /// - Returns: index of channel in channel_layout on success, nil on error.
    public func index(for channel: FFmpegChannel) throws -> Int {
        let i = av_get_channel_layout_channel_index(rawValue, channel.rawValue)
        try throwIfFail(i)
        return Int(i)
    }
    
    /// Get default channel layout for a given number of channels.
    ///
    /// - Parameter count: number of channels
    /// - Returns: AVChannelLayout
    public static func `default`(forChannelCount count: Int32) -> FFmpegChannelLayout {
        return FFmpegChannelLayout(rawValue: UInt64(av_get_default_channel_layout(count)))
    }
    
    public static let CHL_NONE = FFmpegChannelLayout(rawValue: 0)
    /// Channel mask value used for AVCodecContext.request_channel_layout
    /// to indicate that the user requests the channel order of the decoder output
    /// to be the native codec channel order.
    public static let CHL_NATIVE = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_NATIVE)
    public static let CHL_MONO = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_MONO)
    public static let CHL_STEREO = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_STEREO)
    public static let CHL_2POINT1 = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_2POINT1)
    public static let CHL_2_1 = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_2_1)
    public static let CHL_SURROUND = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_SURROUND)
    public static let CHL_3POINT1 = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_3POINT1)
    public static let CHL_4POINT0 = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_4POINT0)
    public static let CHL_4POINT1 = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_4POINT1)
    public static let CHL_2_2 = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_2_2)
    public static let CHL_QUAD = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_QUAD)
    public static let CHL_5POINT0 = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_5POINT0)
    public static let CHL_5POINT1 = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_5POINT1)
    public static let CHL_5POINT0_BACK = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_5POINT0_BACK)
    public static let CHL_5POINT1_BACK = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_5POINT1_BACK)
    public static let CHL_6POINT0 = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_6POINT0)
    public static let CHL_6POINT0_FRONT = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_6POINT0_FRONT)
    public static let CHL_HEXAGONAL = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_HEXAGONAL)
    public static let CHL_6POINT1 = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_6POINT1)
    public static let CHL_6POINT1_BACK = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_6POINT1_BACK)
    public static let CHL_6POINT1_FRONT = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_6POINT1_FRONT)
    public static let CHL_7POINT0 = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_7POINT0)
    public static let CHL_7POINT0_FRONT = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_7POINT0_FRONT)
    public static let CHL_7POINT1 = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_7POINT1)
    public static let CHL_7POINT1_WIDE = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_7POINT1_WIDE)
    public static let CHL_7POINT1_WIDE_BACK = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_7POINT1_WIDE_BACK)
    public static let CHL_OCTAGONAL = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_OCTAGONAL)
    public static let CHL_HEXADECAGONAL = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_HEXADECAGONAL)
    public static let CHL_STEREO_DOWNMIX = FFmpegChannelLayout(rawValue: AV_CH_LAYOUT_STEREO_DOWNMIX)
}
