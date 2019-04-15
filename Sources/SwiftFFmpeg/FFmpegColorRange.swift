//
//  FFmpegColorRange.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/14.
//

import Foundation
import CFFmpeg

public enum FFmpegColorRange: CustomStringConvertible {
    
    /// Undefined
    case unspecified
    case mpeg
    case jpeg
    case nb
    
    var rawValue: AVColorRange {
        switch self {
        case .unspecified: return AVCOL_RANGE_UNSPECIFIED
        case .mpeg: return AVCOL_RANGE_MPEG
        case .jpeg: return AVCOL_RANGE_JPEG
        case .nb: return AVCOL_RANGE_NB
        }
    }
    
    init(rawValue: AVColorRange) {
        switch rawValue {
        case AVCOL_RANGE_UNSPECIFIED: self = .unspecified
        case AVCOL_RANGE_MPEG: self = .mpeg
        case AVCOL_RANGE_JPEG: self = .jpeg
        case AVCOL_RANGE_NB: self = .nb
        default: fatalError()
        }
    }
    
    public var description: String {
        switch self {
        case .jpeg: return "the normal     2^n-1   'JPEG' YUV ranges"
        case .mpeg: return "the normal 219*2^(n-8) 'MPEG' YUV ranges"
        case .nb: return "Not part of ABI"
        case .unspecified: return "UNSPECIFIED"
        }
        
    }
    
}
