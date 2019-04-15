//
//  FFmpegChannel.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/14.
//

import Foundation
import CFFmpeg

public struct FFmpegChannel: Equatable, CustomStringConvertible {
    
    let rawValue: UInt64
    
    init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
    
    public var name: String {
        return String(cString: av_get_channel_name(rawValue))
    }
    
    public var description: String {
        return name
    }
    
    public static let frontLeft = FFmpegChannel(rawValue: UInt64(AV_CH_FRONT_LEFT))
    public static let frontRight = FFmpegChannel(rawValue: UInt64(AV_CH_FRONT_RIGHT))
    public static let frontCenter = FFmpegChannel(rawValue: UInt64(AV_CH_FRONT_CENTER))
    public static let lowFrequency = FFmpegChannel(rawValue: UInt64(AV_CH_LOW_FREQUENCY))
    public static let backLeft = FFmpegChannel(rawValue: UInt64(AV_CH_BACK_LEFT))
    public static let backRight = FFmpegChannel(rawValue: UInt64(AV_CH_BACK_RIGHT))
    public static let frontLeftOfCenter = FFmpegChannel(rawValue: UInt64(AV_CH_FRONT_LEFT_OF_CENTER))
    public static let frontRightOfCenter = FFmpegChannel(rawValue: UInt64(AV_CH_FRONT_RIGHT_OF_CENTER))
    public static let backCenter = FFmpegChannel(rawValue: UInt64(AV_CH_BACK_CENTER))
    public static let sideLeft = FFmpegChannel(rawValue: UInt64(AV_CH_SIDE_LEFT))
    public static let sideRight = FFmpegChannel(rawValue: UInt64(AV_CH_SIDE_RIGHT))
    public static let topCenter = FFmpegChannel(rawValue: UInt64(AV_CH_TOP_CENTER))
    public static let topFrontLeft = FFmpegChannel(rawValue: UInt64(AV_CH_TOP_FRONT_LEFT))
    public static let topFrontCenter = FFmpegChannel(rawValue: UInt64(AV_CH_TOP_FRONT_CENTER))
    public static let topFrontRight = FFmpegChannel(rawValue: UInt64(AV_CH_TOP_FRONT_RIGHT))
    public static let topBackLeft = FFmpegChannel(rawValue: UInt64(AV_CH_TOP_BACK_LEFT))
    public static let topBackCenter = FFmpegChannel(rawValue: UInt64(AV_CH_TOP_BACK_CENTER))
    public static let topBackRight = FFmpegChannel(rawValue: UInt64(AV_CH_TOP_BACK_RIGHT))
    /// Stereo downmix.
    public static let stereoLeft = FFmpegChannel(rawValue: UInt64(AV_CH_STEREO_LEFT))
    /// See AV_CH_STEREO_LEFT.
    public static let stereoRight = FFmpegChannel(rawValue: UInt64(AV_CH_STEREO_RIGHT))
    public static let wideLeft = FFmpegChannel(rawValue: AV_CH_WIDE_LEFT)
    public static let wideRight = FFmpegChannel(rawValue: AV_CH_WIDE_RIGHT)
    public static let surroundDirectLeft = FFmpegChannel(rawValue: AV_CH_SURROUND_DIRECT_LEFT)
    public static let surroundDirectRight = FFmpegChannel(rawValue: AV_CH_SURROUND_DIRECT_RIGHT)
    public static let lowFrequency2 = FFmpegChannel(rawValue: AV_CH_LOW_FREQUENCY_2)
}
