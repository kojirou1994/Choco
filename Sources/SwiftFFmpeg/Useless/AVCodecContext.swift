//
//  AVCodecContext.swift
//  SwiftFFmpeg
//
//  Created by sunlubo on 2018/6/29.
//

import CFFmpeg

// MARK: - AVCodecFlag

/// encoding support
///
/// These flags can be passed in AVCodecContext.flags before initialization.
//public struct AVCodecFlag: OptionSet {
//    public let rawValue: Int32
//
//    public init(rawValue: Int32) {
//        self.rawValue = rawValue
//    }
//
//    /// Place global headers in extradata instead of every keyframe.
//    public static let globalHeader = AVCodecFlag(rawValue: AV_CODEC_FLAG_GLOBAL_HEADER)
//}
//
//// MARK: - AVCodecFlag2
//
//public struct AVCodecFlag2: OptionSet {
//    public let rawValue: Int32
//
//    public init(rawValue: Int32) {
//        self.rawValue = rawValue
//    }
//
//    /// Allow non spec compliant speedup tricks.
//    public static let fast = AVCodecFlag2(rawValue: AV_CODEC_FLAG2_FAST)
//    /// Skip bitstream encoding.
//    public static let noOutput = AVCodecFlag2(rawValue: AV_CODEC_FLAG2_NO_OUTPUT)
//    /// Place global headers at every keyframe instead of in extradata.
//    public static let localHeader = AVCodecFlag2(rawValue: AV_CODEC_FLAG2_LOCAL_HEADER)
//    /// timecode is in drop frame format.
//    @available(*, deprecated)
//    public static let dropFrameTimecode = AVCodecFlag2(rawValue: AV_CODEC_FLAG2_DROP_FRAME_TIMECODE)
//    /// Input bitstream might be truncated at a packet boundaries instead of only at frame boundaries.
//    public static let chunks = AVCodecFlag2(rawValue: AV_CODEC_FLAG2_CHUNKS)
//    /// Discard cropping information from SPS.
//    public static let ignoreCrop = AVCodecFlag2(rawValue: AV_CODEC_FLAG2_IGNORE_CROP)
//    /// Show all frames before the first keyframe.
//    public static let showAll = AVCodecFlag2(rawValue: AV_CODEC_FLAG2_SHOW_ALL)
//    /// Export motion vectors through frame side data.
//    public static let exportMVS = AVCodecFlag2(rawValue: AV_CODEC_FLAG2_EXPORT_MVS)
//    /// Do not skip samples and export skip information as frame side data.
//    public static let skipManual = AVCodecFlag2(rawValue: AV_CODEC_FLAG2_SKIP_MANUAL)
//    /// Do not reset ASS ReadOrder field on flush (subtitles decoding).
//    public static let roFlushNoop = AVCodecFlag2(rawValue: AV_CODEC_FLAG2_RO_FLUSH_NOOP)
//}

// MARK: - AVCodecContext

