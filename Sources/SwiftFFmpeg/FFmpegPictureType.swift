//
//  FFmpegPictureType.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/14.
//

import Foundation
import CFFmpeg

public enum FFmpegPictureType: CustomStringConvertible {
    
    /// Undefined
    case none
    case i
    case p
    case b
    case s
    case si
    case sp
    case bi
    
    var rawValue: AVPictureType {
        switch self {
        case .b: return AV_PICTURE_TYPE_B
        case .bi: return AV_PICTURE_TYPE_BI
        case .i: return AV_PICTURE_TYPE_I
        case .none: return AV_PICTURE_TYPE_NONE
        case .p: return AV_PICTURE_TYPE_P
        case .si: return AV_PICTURE_TYPE_SI
        case .sp: return AV_PICTURE_TYPE_SP
        case .s: return AV_PICTURE_TYPE_S
        }
    }
    
    init(rawValue: AVPictureType) {
        switch rawValue {
        case AV_PICTURE_TYPE_NONE: self = .none
        case AV_PICTURE_TYPE_I: self = .i
        case AV_PICTURE_TYPE_B: self = .b
        case AV_PICTURE_TYPE_P: self = .p
        case AV_PICTURE_TYPE_S: self = .s
        case AV_PICTURE_TYPE_SI: self = .si
        case AV_PICTURE_TYPE_SP: self = .sp
        case AV_PICTURE_TYPE_BI: self = .bi
        default: fatalError()
        }
    }
    
    public var description: String {
        return String(Character(Unicode.Scalar(UInt8(bitPattern: av_get_picture_type_char(rawValue)))))
    }
    
}
