//
//  VideoUtil.swift
//  SwiftFFmpeg
//
//  Created by sunlubo on 2018/8/2.
//

import CFFmpeg
// MARK: - AVPictureType

//public typealias AVPictureType = CFFmpeg.AVPictureType

/// AVPicture types, pixel formats and basic image planes manipulation.
extension AVPictureType: CustomStringConvertible {
    /// Undefined
    public static let NONE = AV_PICTURE_TYPE_NONE
    /// Intra
    public static let I = AV_PICTURE_TYPE_I
    /// Predicted
    public static let P = AV_PICTURE_TYPE_P
    /// Bi-dir predicted
    public static let B = AV_PICTURE_TYPE_B
    /// S(GMC)-VOP MPEG-4
    public static let S = AV_PICTURE_TYPE_S
    /// Switching Intra
    public static let SI = AV_PICTURE_TYPE_SI
    /// Switching Predicted
    public static let SP = AV_PICTURE_TYPE_SP
    /// BI type
    public static let BI = AV_PICTURE_TYPE_BI

    public var description: String {
        let char = av_get_picture_type_char(self)
        let scalar = Unicode.Scalar(Int(char))!
        return String(Character(scalar))
    }
}

struct AVPixelFormatWrapper: CustomStringConvertible {

    let _value: AVPixelFormat
    
    public init(name: String) {
        _value = av_get_pix_fmt(name)
    }

    public var name: String {
        if let strBytes = av_get_pix_fmt_name(_value) {
            return String(cString: strBytes)
        }
        return "unknown"
    }

    /// The number of planes in the pixel format.
    public var planeCount: Int {
        let count = Int(av_pix_fmt_count_planes(_value))
        return count >= 0 ? count : 0
    }

    public var description: String {
        return name
    }
}
