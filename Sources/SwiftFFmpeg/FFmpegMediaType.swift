//
//  FFmpegMediaType.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/14.
//

import Foundation
import CFFmpeg

public enum FFmpegMediaType: CustomStringConvertible, Equatable {
    
    /// Usually treated as `data`
    case unknown
    case video
    case audio
    /// Opaque data information usually continuous
    case data
    case subtitle
    /// Opaque data information usually sparse
    case attachment
    case nb
    
    init(rawValue value: AVMediaType) {
        switch value {
        case AVMEDIA_TYPE_UNKNOWN: self = .unknown
        case AVMEDIA_TYPE_VIDEO: self = .video
        case AVMEDIA_TYPE_AUDIO: self = .audio
        case AVMEDIA_TYPE_DATA: self = .data
        case AVMEDIA_TYPE_SUBTITLE: self = .subtitle
        case AVMEDIA_TYPE_ATTACHMENT: self = .attachment
        case AVMEDIA_TYPE_NB: self = .nb
        default: fatalError()
        }
    }
    
    var rawValue: AVMediaType {
        switch self {
        case .attachment: return AVMEDIA_TYPE_ATTACHMENT
        case .audio: return AVMEDIA_TYPE_AUDIO
        case .data: return AVMEDIA_TYPE_DATA
        case .nb: return AVMEDIA_TYPE_NB
        case .subtitle: return AVMEDIA_TYPE_SUBTITLE
        case .unknown: return AVMEDIA_TYPE_UNKNOWN
        case .video: return AVMEDIA_TYPE_VIDEO
        }
    }
    
    public var description: String {
        if let strBytes = av_get_media_type_string(rawValue) {
            return String(cString: strBytes)
        }
        return "unknown"
    }
}
