//
//  FFmpegFieldOrder.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/14.
//

import Foundation
import CFFmpeg

public enum FFmpegFieldOrder: CustomStringConvertible {
    
    case unknown
    case progressive
    case tt
    case bb
    case tb
    case bt
    
    var rawValue: AVFieldOrder {
        switch self {
        case .bb: return AV_FIELD_BB
        case .bt: return AV_FIELD_BT
        case .progressive: return AV_FIELD_PROGRESSIVE
        case .tb: return AV_FIELD_TB
        case .tt: return AV_FIELD_TT
        case .unknown: return AV_FIELD_UNKNOWN
            
        }
    }
    
    init(rawValue: AVFieldOrder) {
        switch rawValue {
        case AV_FIELD_UNKNOWN: self = .unknown
        case AV_FIELD_PROGRESSIVE: self = .progressive
        case AV_FIELD_TT: self = .tt
        case AV_FIELD_BB: self = .bb
        case AV_FIELD_TB: self = .tb
        case AV_FIELD_BT: self = .bt
        default: fatalError()
        }
    }
    
    public var description: String {
        switch self {
        case .bb: return "Bottom coded first, bottom displayed first"
        case .bt: return "Bottom coded first, top displayed first"
        case .progressive: return "progressive"
        case .tb: return "Top coded first, bottom displayed first"
        case .tt: return "Top coded_first, top displayed first"
        case .unknown: return "unknown"
        }
        
    }
    
}
