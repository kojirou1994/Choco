//
//  AVUtilShim.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2018/9/8.
//

import Foundation

@usableFromInline
internal func MKTAG(_ a: Int32, _ b: Int32, _ c: Int32, _ d: Int32) -> Int32 {
    return ((a) | ((b) << 8) | ((c) << 16) | ((d) << 24))
}

@usableFromInline
internal func FFERRTAG(_ a: Int32, _ b: Int32, _ c: Int32, _ d: Int32) -> Int32 {
    return -MKTAG(a, b, c, d)
}

extension Character {
    
    @usableFromInline var unicodeValue: Int32 {
        return Int32(unicodeScalars.first!.value)
    }
    
}

@usableFromInline
internal func FFERRTAG(_ a: Int32, _ b: Character, _ c: Character, _ d: Character) -> Int32 {
    return FFERRTAG(a, b.unicodeValue, c.unicodeValue, d.unicodeValue)
}

@usableFromInline
internal func FFERRTAG(_ a: Character, _ b: Character, _ c: Character, _ d: Character) -> Int32 {
    return FFERRTAG(a.unicodeValue, b.unicodeValue, c.unicodeValue, d.unicodeValue)
}

let AVERROR_BSF_NOT_FOUND     =  FFERRTAG(0xF8,"B","S","F") ///< Bitstream filter not found
let AVERROR_BUG               =  FFERRTAG( "B","U","G","!") ///< Internal bug, also see AVERROR_BUG2
let AVERROR_BUFFER_TOO_SMALL  =  FFERRTAG( "B","U","F","S") ///< Buffer too small
let AVERROR_DECODER_NOT_FOUND =  FFERRTAG(0xF8,"D","E","C") ///< Decoder not found
let AVERROR_DEMUXER_NOT_FOUND =  FFERRTAG(0xF8,"D","E","M") ///< Demuxer not found
let AVERROR_ENCODER_NOT_FOUND =  FFERRTAG(0xF8,"E","N","C") ///< Encoder not found
let AVERROR_EOF               =  FFERRTAG( "E","O","F"," ") ///< End of file
let AVERROR_EXIT              =  FFERRTAG( "E","X","I","T") ///< Immediate exit was requested; the called function should not be restarted
let AVERROR_EXTERNAL          =  FFERRTAG( "E","X","T"," ") ///< Generic error in an external library
let AVERROR_FILTER_NOT_FOUND  =  FFERRTAG(0xF8,"F","I","L") ///< Filter not found
let AVERROR_INVALIDDATA       =  FFERRTAG( "I","N","D","A") ///< Invalid data found when processing input
let AVERROR_MUXER_NOT_FOUND   =  FFERRTAG(0xF8,"M","U","X") ///< Muxer not found
let AVERROR_OPTION_NOT_FOUND  =  FFERRTAG(0xF8,"O","P","T") ///< Option not found
let AVERROR_PATCHWELCOME      =  FFERRTAG( "P","A","W","E") ///< Not yet implemented in FFmpeg, patches welcome
let AVERROR_PROTOCOL_NOT_FOUND = FFERRTAG(0xF8,"P","R","O") ///< Protocol not found

let AVERROR_STREAM_NOT_FOUND  =  FFERRTAG(0xF8,"S","T","R") ///< Stream not found
/**
 * This is semantically identical to AVERROR_BUG
 * it has been introduced in Libav after our AVERROR_BUG and with a modified value.
 */
let AVERROR_BUG2              =  FFERRTAG( "B","U","G"," ")
let AVERROR_UNKNOWN           =  FFERRTAG( "U","N","K","N") ///< Unknown error, typically from an external library
let AVERROR_EXPERIMENTAL: Int32      = (-0x2bb2afa8) ///< Requested feature is flagged experimental. Set strict_std_compliance if you really want to use it.
let AVERROR_INPUT_CHANGED: Int32     = (-0x636e6701) ///< Input changed between calls. Reconfiguration is required. (can be OR-ed with AVERROR_OUTPUT_CHANGED)
let AVERROR_OUTPUT_CHANGED: Int32    = (-0x636e6702) ///< Output changed between calls. Reconfiguration is required. (can be OR-ed with AVERROR_INPUT_CHANGED)
/* HTTP & RTSP errors */
let AVERROR_HTTP_BAD_REQUEST  =  FFERRTAG(0xF8,"4","0","0")
let AVERROR_HTTP_UNAUTHORIZED =  FFERRTAG(0xF8,"4","0","1")
let AVERROR_HTTP_FORBIDDEN    =  FFERRTAG(0xF8,"4","0","3")
let AVERROR_HTTP_NOT_FOUND    =  FFERRTAG(0xF8,"4","0","4")
let AVERROR_HTTP_OTHER_4XX    =  FFERRTAG(0xF8,"4","X","X")
let AVERROR_HTTP_SERVER_ERROR =  FFERRTAG(0xF8,"5","X","X")

let AV_CH_FRONT_LEFT             : UInt64 = 0x00000001
let AV_CH_FRONT_RIGHT            : UInt64 = 0x00000002
let AV_CH_FRONT_CENTER           : UInt64 = 0x00000004
let AV_CH_LOW_FREQUENCY          : UInt64 = 0x00000008
let AV_CH_BACK_LEFT              : UInt64 = 0x00000010
let AV_CH_BACK_RIGHT             : UInt64 = 0x00000020
let AV_CH_FRONT_LEFT_OF_CENTER   : UInt64 = 0x00000040
let AV_CH_FRONT_RIGHT_OF_CENTER  : UInt64 = 0x00000080
let AV_CH_BACK_CENTER            : UInt64 = 0x00000100
let AV_CH_SIDE_LEFT              : UInt64 = 0x00000200
let AV_CH_SIDE_RIGHT             : UInt64 = 0x00000400
let AV_CH_TOP_CENTER             : UInt64 = 0x00000800
let AV_CH_TOP_FRONT_LEFT         : UInt64 = 0x00001000
let AV_CH_TOP_FRONT_CENTER       : UInt64 = 0x00002000
let AV_CH_TOP_FRONT_RIGHT        : UInt64 = 0x00004000
let AV_CH_TOP_BACK_LEFT          : UInt64 = 0x00008000
let AV_CH_TOP_BACK_CENTER        : UInt64 = 0x00010000
let AV_CH_TOP_BACK_RIGHT         : UInt64 = 0x00020000
let AV_CH_STEREO_LEFT            : UInt64 = 0x20000000  ///< Stereo downmix.
let AV_CH_STEREO_RIGHT           : UInt64 = 0x40000000  ///< See AV_CH_STEREO_LEFT.
let AV_CH_WIDE_LEFT              : UInt64 = 0x0000000080000000
let AV_CH_WIDE_RIGHT             : UInt64 = 0x0000000100000000
let AV_CH_SURROUND_DIRECT_LEFT   : UInt64 = 0x0000000200000000
let AV_CH_SURROUND_DIRECT_RIGHT  : UInt64 = 0x0000000400000000
let AV_CH_LOW_FREQUENCY_2        : UInt64 = 0x0000000800000000

let AV_CH_LAYOUT_NATIVE          : UInt64 = 0x8000000000000000

let AV_CH_LAYOUT_MONO            = AV_CH_FRONT_CENTER
let AV_CH_LAYOUT_STEREO          = AV_CH_FRONT_LEFT|AV_CH_FRONT_RIGHT
let AV_CH_LAYOUT_2POINT1         = AV_CH_LAYOUT_STEREO|AV_CH_LOW_FREQUENCY
let AV_CH_LAYOUT_2_1             = AV_CH_LAYOUT_STEREO|AV_CH_BACK_CENTER
let AV_CH_LAYOUT_SURROUND        = AV_CH_LAYOUT_STEREO|AV_CH_FRONT_CENTER
let AV_CH_LAYOUT_3POINT1         = AV_CH_LAYOUT_SURROUND|AV_CH_LOW_FREQUENCY
let AV_CH_LAYOUT_4POINT0         = AV_CH_LAYOUT_SURROUND|AV_CH_BACK_CENTER
let AV_CH_LAYOUT_4POINT1         = AV_CH_LAYOUT_4POINT0|AV_CH_LOW_FREQUENCY
let AV_CH_LAYOUT_2_2             = AV_CH_LAYOUT_STEREO|AV_CH_SIDE_LEFT|AV_CH_SIDE_RIGHT
let AV_CH_LAYOUT_QUAD            = AV_CH_LAYOUT_STEREO|AV_CH_BACK_LEFT|AV_CH_BACK_RIGHT
let AV_CH_LAYOUT_5POINT0         = AV_CH_LAYOUT_SURROUND|AV_CH_SIDE_LEFT|AV_CH_SIDE_RIGHT
let AV_CH_LAYOUT_5POINT1         = AV_CH_LAYOUT_5POINT0|AV_CH_LOW_FREQUENCY
let AV_CH_LAYOUT_5POINT0_BACK    = AV_CH_LAYOUT_SURROUND|AV_CH_BACK_LEFT|AV_CH_BACK_RIGHT
let AV_CH_LAYOUT_5POINT1_BACK    = AV_CH_LAYOUT_5POINT0_BACK|AV_CH_LOW_FREQUENCY
let AV_CH_LAYOUT_6POINT0         = AV_CH_LAYOUT_5POINT0|AV_CH_BACK_CENTER
let AV_CH_LAYOUT_6POINT0_FRONT   = AV_CH_LAYOUT_2_2|AV_CH_FRONT_LEFT_OF_CENTER|AV_CH_FRONT_RIGHT_OF_CENTER
let AV_CH_LAYOUT_HEXAGONAL       = AV_CH_LAYOUT_5POINT0_BACK|AV_CH_BACK_CENTER
let AV_CH_LAYOUT_6POINT1         = AV_CH_LAYOUT_5POINT1|AV_CH_BACK_CENTER
let AV_CH_LAYOUT_6POINT1_BACK    = AV_CH_LAYOUT_5POINT1_BACK|AV_CH_BACK_CENTER
let AV_CH_LAYOUT_6POINT1_FRONT   = AV_CH_LAYOUT_6POINT0_FRONT|AV_CH_LOW_FREQUENCY
let AV_CH_LAYOUT_7POINT0         = AV_CH_LAYOUT_5POINT0|AV_CH_BACK_LEFT|AV_CH_BACK_RIGHT
let AV_CH_LAYOUT_7POINT0_FRONT   = AV_CH_LAYOUT_5POINT0|AV_CH_FRONT_LEFT_OF_CENTER|AV_CH_FRONT_RIGHT_OF_CENTER
let AV_CH_LAYOUT_7POINT1         = AV_CH_LAYOUT_5POINT1|AV_CH_BACK_LEFT|AV_CH_BACK_RIGHT
let AV_CH_LAYOUT_7POINT1_WIDE    = AV_CH_LAYOUT_5POINT1|AV_CH_FRONT_LEFT_OF_CENTER|AV_CH_FRONT_RIGHT_OF_CENTER
let AV_CH_LAYOUT_7POINT1_WIDE_BACK = AV_CH_LAYOUT_5POINT1_BACK|AV_CH_FRONT_LEFT_OF_CENTER|AV_CH_FRONT_RIGHT_OF_CENTER
let t = AV_CH_LOW_FREQUENCY_2
let AV_CH_LAYOUT_OCTAGONAL       = AV_CH_LAYOUT_5POINT0|AV_CH_BACK_LEFT|AV_CH_BACK_CENTER|AV_CH_BACK_RIGHT
public let AV_CH_LAYOUT_HEXADECAGONAL   = AV_CH_LAYOUT_OCTAGONAL|AV_CH_TOP_BACK_LEFT|AV_CH_TOP_BACK_RIGHT|AV_CH_TOP_BACK_CENTER|AV_CH_TOP_FRONT_CENTER|AV_CH_TOP_FRONT_LEFT|AV_CH_TOP_FRONT_RIGHT | AV_CH_WIDE_LEFT|AV_CH_WIDE_RIGHT
let AV_CH_LAYOUT_STEREO_DOWNMIX  = AV_CH_STEREO_LEFT|AV_CH_STEREO_RIGHT


public let AV_NOPTS_VALUE     =     Int64.min
