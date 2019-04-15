//
//  FFmpegChromaLocation.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/14.
//

import Foundation
import CFFmpeg

public enum FFmpegChromaLocation: CustomStringConvertible {
    
    case unspecified
    case left
    case center
    case topleft
    case top
    case bottomleft
    case bottom
    case nb
    
    var rawValue: AVChromaLocation {
        switch self {
        case .unspecified: return AVCHROMA_LOC_UNSPECIFIED
        case .left: return AVCHROMA_LOC_LEFT
        case .center: return AVCHROMA_LOC_CENTER
        case .topleft: return AVCHROMA_LOC_TOPLEFT
        case .top: return AVCHROMA_LOC_TOP
        case .bottomleft: return AVCHROMA_LOC_BOTTOMLEFT
        case .bottom: return AVCHROMA_LOC_BOTTOM
        case .nb: return AVCHROMA_LOC_NB
        }
    }
    
    init(rawValue: AVChromaLocation) {
        switch rawValue {
        case AVCHROMA_LOC_UNSPECIFIED: self = .unspecified
        case AVCHROMA_LOC_LEFT: self = .left
        case AVCHROMA_LOC_CENTER: self = .center
        case AVCHROMA_LOC_TOPLEFT: self = .topleft
        case AVCHROMA_LOC_TOP: self = .top
        case AVCHROMA_LOC_BOTTOMLEFT: self = .bottomleft
        case AVCHROMA_LOC_BOTTOM: self = .bottom
        case AVCHROMA_LOC_NB: self = .nb
        default: fatalError()
        }
    }
    
    public var description: String {
        switch self {
        case .unspecified: return "unspecified"
        case .left: return "MPEG-2/4 4:2:0, H.264 default for 4:2:0"
        case .center: return "MPEG-1 4:2:0, JPEG 4:2:0, H.263 4:2:0"
        case .topleft: return "ITU-R 601, SMPTE 274M 296M S314M(DV 4:1:1), mpeg2 4:2:2"
        case .top: return "ITU-R 601, SMPTE 274M 296M S314M(DV 4:1:1), mpeg2 4:2:2"
        case .bottomleft: return "ITU-R 601, SMPTE 274M 296M S314M(DV 4:1:1), mpeg2 4:2:2"
        case .bottom: return "ITU-R 601, SMPTE 274M 296M S314M(DV 4:1:1), mpeg2 4:2:2"
        case .nb: return "Not part of ABI"
        }
        
    }
    
}
