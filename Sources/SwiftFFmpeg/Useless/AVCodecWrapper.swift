//
//  Codec.swift
//  SwiftFFmpeg
//
//  Created by sunlubo on 2018/6/28.
//

import CFFmpeg
    
// MARK: - AVCodecCap

/// codec capabilities
public struct AVCodecCap: OptionSet {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    /// Audio encoder supports receiving a different number of samples in each call.
    public static let variableFrameSize = AVCodecCap(rawValue: AV_CODEC_CAP_VARIABLE_FRAME_SIZE)
}
