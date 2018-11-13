//
//  CType.swift
//  SwiftFFmpeg
//
//  Created by sunlubo on 2018/7/4.
//

import CFFmpeg

public let AV_INPUT_BUFFER_PADDING_SIZE = Int(CFFmpeg.AV_INPUT_BUFFER_PADDING_SIZE)

public let AV_ERROR_MAX_STRING_SIZE = Int(CFFmpeg.AV_ERROR_MAX_STRING_SIZE)

// MARK: - AVMediaType

//public typealias AVMediaType = CFFmpeg.AVMediaType

/// Media Type

extension AVMediaType: CustomStringConvertible, Equatable {
    /// Usually treated as `data`
    public static let unknown = AVMEDIA_TYPE_UNKNOWN
    public static let video = AVMEDIA_TYPE_VIDEO
    public static let audio = AVMEDIA_TYPE_AUDIO
    /// Opaque data information usually continuous
    public static let data = AVMEDIA_TYPE_DATA
    public static let subtitle = AVMEDIA_TYPE_SUBTITLE
    /// Opaque data information usually sparse
    public static let attachment = AVMEDIA_TYPE_ATTACHMENT
    public static let nb = AVMEDIA_TYPE_NB

    public var description: String {
        if let strBytes = av_get_media_type_string(self) {
            return String(cString: strBytes)
        }
        return "unknown"
    }
}
