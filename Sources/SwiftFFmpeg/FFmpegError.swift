//
//  FFmpegError.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/12.
//

import Foundation
import CFFmpeg

private let AVERROR = swift_AVERROR
private let AVUNERROR = swift_AVUNERROR

public let AV_INPUT_BUFFER_PADDING_SIZE = Int(CFFmpeg.AV_INPUT_BUFFER_PADDING_SIZE)

public let AV_ERROR_MAX_STRING_SIZE = Int(CFFmpeg.AV_ERROR_MAX_STRING_SIZE)

public struct FFmpegError: Error, Equatable, CustomStringConvertible/*, ExpressibleByIntegerLiteral*/ {
    
    //    public typealias IntegerLiteralType = Int32
    
    public let code: Int32
    
    //    public init(integerLiteral value: Int32) {
    //        self.code = value
    //    }
    
    public init(code: Int32) {
        self.code = code
    }
    
    public var description: String {
        //        let buf = UnsafeMutablePointer<Int8>.allocate(capacity: AV_ERROR_MAX_STRING_SIZE)
        //        buf.initialize(to: 0)
        //        defer {
        //            buf.deinitialize(count: AV_ERROR_MAX_STRING_SIZE)
        //            buf.deallocate()
        //        }
        var buf = [Int8].init(repeating: 0, count: AV_ERROR_MAX_STRING_SIZE)
        return String(cString: av_make_error_string(&buf, AV_ERROR_MAX_STRING_SIZE, code))
    }
    
}

extension FFmpegError {
    public static let EAGAIN = FFmpegError(code: AVERROR(Foundation.EAGAIN))
    public static let EOF = FFmpegError(code: AVERROR_EOF)
    /*
     /// Resource temporarily unavailable
     
     /// Invalid argument
     public static let EINVAL = FFmpegError(code: AVERROR(Foundation.EINVAL))
     /// Cannot allocate memory
     public static let ENOMEM = FFmpegError(code: AVERROR(Foundation.ENOMEM))
     
     /// Bitstream filter not found
     //    public static let BSF_NOT_FOUND: FFmpegError = FFmpegError(AVERROR_BSF_NOT_FOUND)
     //        = FFmpegError(code: AVERROR_BSF_NOT_FOUND)
     /// Internal bug, also see AVERROR_BUG2
     public static let BUG = FFmpegError(code: AVERROR_BUG)
     /// Buffer too small
     public static let BUFFER_TOO_SMALL = FFmpegError(code: AVERROR_BUFFER_TOO_SMALL)
     /// Decoder not found
     public static let DECODER_NOT_FOUND = FFmpegError(code: AVERROR_DECODER_NOT_FOUND)
     /// Demuxer not found
     public static let DEMUXER_NOT_FOUND = FFmpegError(code: AVERROR_DEMUXER_NOT_FOUND)
     /// Encoder not found
     public static let ENCODER_NOT_FOUND = FFmpegError(code: AVERROR_ENCODER_NOT_FOUND)
     /// End of file
     
     /// Immediate exit was requested; the called function should not be restarted
     public static let EXIT = FFmpegError(code: AVERROR_EXIT)
     /// Generic error in an external library
     public static let EXTERNAL = FFmpegError(code: AVERROR_EXTERNAL)
     /// Filter not found
     public static let FILTER_NOT_FOUND = FFmpegError(code: AVERROR_FILTER_NOT_FOUND)
     /// Invalid data found when processing input
     public static let INVALIDDATA = FFmpegError(code: AVERROR_INVALIDDATA)
     /// Muxer not found
     public static let MUXER_NOT_FOUND = FFmpegError(code: AVERROR_MUXER_NOT_FOUND)
     /// Option not found
     public static let OPTION_NOT_FOUND = FFmpegError(code: AVERROR_OPTION_NOT_FOUND)
     /// Not yet implemented in FFmpeg, patches welcome
     public static let PATCHWELCOME = FFmpegError(code: AVERROR_PATCHWELCOME)
     /// Protocol not found
     public static let PROTOCOL_NOT_FOUND = FFmpegError(code: AVERROR_PROTOCOL_NOT_FOUND)
     /// Stream not found
     public static let STREAM_NOT_FOUND = FFmpegError(code: AVERROR_STREAM_NOT_FOUND)
     /// This is semantically identical to AVERROR_BUG. It has been introduced in Libav after our `AVERROR_BUG` and
     /// with a modified value.
     public static let BUG2 = FFmpegError(code: AVERROR_BUG2)
     /// Unknown error, typically from an external library
     public static let UNKNOWN = FFmpegError(code: AVERROR_UNKNOWN)
     ///  Requested feature is flagged experimental. Set strict_std_compliance if you really want to use it.
     public static let EXPERIMENTAL = FFmpegError(code: AVERROR_EXPERIMENTAL)
     /// Input changed between calls. Reconfiguration is required. (can be OR-ed with AVERROR_OUTPUT_CHANGED)
     public static let INPUT_CHANGED = FFmpegError(code: AVERROR_INPUT_CHANGED)
     /// Output changed between calls. Reconfiguration is required. (can be OR-ed with AVERROR_INPUT_CHANGED)
     public static let OUTPUT_CHANGED = FFmpegError(code: AVERROR_OUTPUT_CHANGED)
     
     /* HTTP & RTSP errors */
     public static let HTTP_BAD_REQUEST = FFmpegError(code: AVERROR_HTTP_BAD_REQUEST)
     public static let HTTP_UNAUTHORIZED = FFmpegError(code: AVERROR_HTTP_UNAUTHORIZED)
     public static let HTTP_FORBIDDEN = FFmpegError(code: AVERROR_HTTP_FORBIDDEN)
     public static let HTTP_NOT_FOUND = FFmpegError(code: AVERROR_HTTP_NOT_FOUND)
     public static let HTTP_OTHER_4XX = FFmpegError(code: AVERROR_HTTP_OTHER_4XX)
     public static let HTTP_SERVER_ERROR = FFmpegError(code: AVERROR_HTTP_SERVER_ERROR)
     */
}

internal func throwIfFail(_ code: Int32) throws {
    if code < 0 {
        throw FFmpegError(code: code)
    }
}
