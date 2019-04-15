//
//  FFmpegInputFormat.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/14.
//

import Foundation
import CFFmpeg

public final class FFmpegInputFormat: CPointerWrapper, CustomStringConvertible {
    
    var _value: UnsafeMutablePointer<AVInputFormat>
    
    init(_ value: UnsafeMutablePointer<AVInputFormat>) {
        _value = value
    }
    
    public init?(shortName: String) {
        guard let p = av_find_input_format(shortName) else {
            return nil
        }
        _value = p
    }
    
    /// A comma separated list of short names for the format.
    public var name: String {
        return String(cString: _value.pointee.name)
    }
    
    /// Descriptive name for the format, meant to be more human-readable than name.
    public var longName: String {
        return String(cString: _value.pointee.long_name)
    }
    
    /// Flags used by `flags`.
    public struct Flag: OptionSet {
        /// Demuxer will use avio_open, no opened file should be provided by the caller.
        public static let noFile = Flag(rawValue: AVFMT_NOFILE)
        /// Needs '%d' in filename.
        public static let needNumber = Flag(rawValue: AVFMT_NEEDNUMBER)
        /// Show format stream IDs numbers.
        public static let showIDs = Flag(rawValue: AVFMT_SHOW_IDS)
        /// Use generic index building code.
        public static let genericIndex = Flag(rawValue: AVFMT_GENERIC_INDEX)
        /// Format allows timestamp discontinuities. Note, muxers always require valid (monotone) timestamps.
        public static let tsDiscont = Flag(rawValue: AVFMT_TS_DISCONT)
        /// Format does not allow to fall back on binary search via read_timestamp.
        public static let noBinSearch = Flag(rawValue: AVFMT_NOBINSEARCH)
        /// Format does not allow to fall back on generic search.
        public static let noGenSearch = Flag(rawValue: AVFMT_NOGENSEARCH)
        /// Format does not allow seeking by bytes.
        public static let noByteSeek = Flag(rawValue: AVFMT_NO_BYTE_SEEK)
        /// Seeking is based on PTS.
        public static let seekToPTS = Flag(rawValue: AVFMT_SEEK_TO_PTS)
        
        public let rawValue: Int32
        
        public init(rawValue: Int32) { self.rawValue = rawValue }
    }
    
    /// Can use flags: `AVFmt.noFile`, `AVFmt.needNumber`, `AVFmt.showIDs`, `AVFmt.genericIndex`,
    /// `AVFmt.tsDiscont`, `AVFmt.noBinSearch`, `AVFmt.noGenSearch`, `AVFmt.noByteSeek`,
    /// `AVFmt.seekToPTS`.
    public var flags: Flag {
        //        get { return AVFmt(rawValue: _value.pointee.flags) }
        //        set { _value.pointee.flags = newValue.rawValue }
        return .init(rawValue: _value.pointee.flags)
    }
    
    /// If extensions are defined, then no probe is done. You should usually not use extension format guessing because
    /// it is not reliable enough.
    public var extensions: String? {
        if let strBytes = _value.pointee.extensions {
            return String(cString: strBytes)
        }
        return nil
    }
    
    /// Comma-separated list of mime types.
    ///
    /// It is used check for matching mime types while probing.
    public var mimeType: String? {
        if let strBytes = _value.pointee.mime_type {
            return String(cString: strBytes)
        }
        return nil
    }
    
    public var description: String {
        return """
        name: \(name)
        longName: \(longName)
        extensions: \(extensions ?? "-")
        mimeType: \(mimeType ?? "-")
        """
    }
    
    public static let registeredDemuxers: [FFmpegInputFormat] = {
        var result = [FFmpegInputFormat]()
        var state: UnsafeMutableRawPointer?
        while let fmt = av_demuxer_iterate(&state) {
            result.append(.init(.init(mutating: fmt)))
        }
        return result
    }()
}
