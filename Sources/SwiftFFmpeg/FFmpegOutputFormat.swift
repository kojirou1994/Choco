//
//  FFmpegOutputFormat.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/14.
//

import Foundation
import CFFmpeg

public final class FFmpegOutputFormat: CPointerWrapper, CustomStringConvertible {
    
    var _value: UnsafeMutablePointer<AVOutputFormat>
    
    init(_ value: UnsafeMutablePointer<AVOutputFormat>) {
        _value = value
    }
    
    public var name: String {
        return String(cString: _value.pointee.name)
    }
    
    public var longName: String {
        return String(cString: _value.pointee.long_name)
    }
    
    public var extensions: String? {
        if let strBytes = _value.pointee.extensions {
            return String(cString: strBytes)
        }
        return nil
    }
    
    public var mimeType: String? {
        if let strBytes = _value.pointee.mime_type {
            return String(cString: strBytes)
        }
        return nil
    }
    
    public var audioCodec: FFmpegCodecID {
        return .init(rawValue: _value.pointee.audio_codec)
    }
    
    public var videoCodec: FFmpegCodecID {
        return .init(rawValue: _value.pointee.video_codec)
    }
    
    public var subtitleCodec: FFmpegCodecID {
        return .init(rawValue: _value.pointee.subtitle_codec)
    }
    
    public struct Flag: OptionSet {
        /// Muxer will use avio_open, no opened file should be provided by the caller.
        public static let noFile = Flag(rawValue: AVFMT_NOFILE)
        /// Needs '%d' in filename.
        public static let needNumber = Flag(rawValue: AVFMT_NEEDNUMBER)
        /// Format wants global header.
        public static let globalHeader = Flag(rawValue: AVFMT_GLOBALHEADER)
        /// Format does not need / have any timestamps.
        public static let noTimestamps = Flag(rawValue: AVFMT_NOTIMESTAMPS)
        /// Format allows variable fps.
        public static let variableFPS = Flag(rawValue: AVFMT_VARIABLE_FPS)
        /// Format does not need width/height.
        public static let noDimensions = Flag(rawValue: AVFMT_NODIMENSIONS)
        /// Format does not require any streams.
        public static let noStreams = Flag(rawValue: AVFMT_NOSTREAMS)
        /// Format allows flushing. If not set, the muxer will not receive a NULL packet in the `write_packet` function.
        public static let allowFlush = Flag(rawValue: AVFMT_ALLOW_FLUSH)
        /// Format does not require strictly increasing timestamps, but they must still be monotonic.
        public static let tsNonstrict = Flag(rawValue: AVFMT_TS_NONSTRICT)
        /// Format allows muxing negative timestamps. If not set the timestamp will be shifted in `writeFrame` and
        /// `interleavedWriteFrame` so they start from 0.
        /// The user or muxer can override this through AVFormatContext.avoid_negative_ts.
        public static let tsNegative = Flag(rawValue: AVFMT_TS_NEGATIVE)
        
        public let rawValue: Int32
        
        public init(rawValue: Int32) { self.rawValue = rawValue }
    }
    
    /// Can use flags: `AVFmt.noFile`, `AVFmt.needNumber`, `AVFmt.globalHeader`, `AVFmt.noTimestamps`,
    /// `AVFmt.variableFPS`, `AVFmt.noDimensions`, `AVFmt.noStreams`, `AVFmt.allowFlush`,
    /// `AVFmt.tsNonstrict`, `AVFmt.tsNegative`.
    public var flags: Flag {
//        get { return AVFmt(rawValue: _value.pointee.flags) }
//        set { _value.pointee.flags = newValue.rawValue }
        return .init(rawValue: _value.pointee.flags)
    }
    
    public var description: String {
        return """
        name: \(name)
        longName: \(longName)
        extensions: \(extensions ?? "-")
        mimeType: \(mimeType ?? "-")
        videoCodec: \(videoCodec)
        audioCodec: \(audioCodec)
        subtitleCodec: \(subtitleCodec)
        """
    }
    
    /// Get all registered muxers.
    public static var registeredMuxers: [FFmpegOutputFormat] {
        var result = [FFmpegOutputFormat]()
        var state: UnsafeMutableRawPointer?
        while let fmt = av_muxer_iterate(&state) {
            result.append(.init(.init(mutating: fmt)))
        }
        return result
    }
    
}
