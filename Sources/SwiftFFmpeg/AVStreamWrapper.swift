//
//  AVStream.swift
//  SwiftFFmpeg
//
//  Created by sunlubo on 2018/6/29.
//

import CFFmpeg

// MARK: - AVDiscard

//public typealias AVDiscard = CFFmpeg.AVDiscard

//extension AVDiscard {
//    /// discard nothing
//    public static let none = AVDISCARD_NONE
//    /// discard useless packets like 0 size packets in avi
//    public static let `default` = AVDISCARD_DEFAULT
//    /// discard all non reference
//    public static let nonRef = AVDISCARD_NONREF
//    /// discard all bidirectional frames
//    public static let bidir = AVDISCARD_BIDIR
//    /// discard all non intra frames
//    public static let nonIntra = AVDISCARD_NONINTRA
//    /// discard all frames except keyframes
//    public static let nonKey = AVDISCARD_NONKEY
//    /// discard all
//    public static let all = AVDISCARD_ALL
//}

// MARK: - Audio

//internal typealias AVCodecParameters = CFFmpeg.AVCodecParameters

/// This class describes the properties of an encoded stream.
public final class AVCodecParametersWrapper {
    internal let parametersPtr: UnsafeMutablePointer<AVCodecParameters>
    internal var parameters: AVCodecParameters { return parametersPtr.pointee }

    internal init(parametersPtr: UnsafeMutablePointer<AVCodecParameters>) {
        self.parametersPtr = parametersPtr
    }

    /// General type of the encoded data.
    public var mediaType: AVMediaType {
        return parameters.codec_type
    }

    /// Specific type of the encoded data (the codec used).
    public var codecId: AVCodecID {
        return parameters.codec_id
    }

    /// Additional information about the codec (corresponds to the AVI FOURCC).
    public var codecTag: UInt32 {
        get { return parameters.codec_tag }
        set { parametersPtr.pointee.codec_tag = newValue }
    }

    /// The average bitrate of the encoded data (in bits per second).
    public var bitRate: Int {
        return Int(parameters.bit_rate)
    }
}

// MARK: - Video

extension AVCodecParametersWrapper {

    /// Pixel format.
    public var pixFmt: AVPixelFormat {
        return AVPixelFormat(parameters.format)
    }

    /// The width of the video frame in pixels.
    public var width: Int32 {
        return parameters.width
    }

    /// The height of the video frame in pixels.
    public var height: Int32 {
        return parameters.height
    }

    /// The aspect ratio (width / height) which a single pixel should have when displayed.
    ///
    /// When the aspect ratio is unknown / undefined, the numerator should be
    /// set to 0 (the denominator may have any value).
    public var sampleAspectRatio: AVRational {
        return parameters.sample_aspect_ratio
    }

    /// Number of delayed frames.
    public var videoDelay: Int32 {
        return parameters.video_delay
    }
}

// MARK: - Audio

extension AVCodecParametersWrapper {

    /// Sample format.
    public var sampleFmt: AVSampleFormat {
        return AVSampleFormat(parameters.format)
    }

    /// The channel layout bitmask. May be 0 if the channel layout is
    /// unknown or unspecified, otherwise the number of bits set must be equal to
    /// the channels field.
    public var channelLayout: AVChannelLayout {
        return AVChannelLayout(rawValue: parameters.channel_layout)
    }

    /// The number of audio channels.
    public var channelCount: Int32 {
        return parameters.channels
    }

    /// The number of audio samples per second.
    public var sampleRate: Int32 {
        return parameters.sample_rate
    }

    /// Audio frame size, if known. Required by some formats to be static.
    public var frameSize: Int32 {
        return parameters.frame_size
    }
}

// MARK: - AVStream

//internal typealias AVStream = CFFmpeg.AVStream

/// Stream structure.
public final class AVStreamWrapper {
    internal let streamPtr: UnsafeMutablePointer<AVStream>

    internal init(streamPtr: UnsafeMutablePointer<AVStream>) {
        self.streamPtr = streamPtr
    }

    public var id: Int32 {
        get { return streamPtr.pointee.id }
        set { streamPtr.pointee.id = newValue }
    }

    public var index: Int32 {
        return streamPtr.pointee.index
    }

    public var timebase: AVRational {
        get { return streamPtr.pointee.time_base }
        set { streamPtr.pointee.time_base = newValue }
    }

    public var startTime: Int64 {
        return streamPtr.pointee.start_time
    }

    public var duration: Int64 {
        return streamPtr.pointee.duration
    }

    public var frameCount: Int64 {
        return streamPtr.pointee.nb_frames
    }

    public var discard: AVDiscard {
        get { return streamPtr.pointee.discard }
        set { streamPtr.pointee.discard = newValue }
    }

    public var sampleAspectRatio: AVRational {
        return streamPtr.pointee.sample_aspect_ratio
    }
    
    public var metadata: AVDictionary {
        return AVDictionary.init(metadata: streamPtr.pointee.metadata)
    }

    public var averageFramerate: AVRational {
        return streamPtr.pointee.avg_frame_rate
    }

    public var realFramerate: AVRational {
        return streamPtr.pointee.r_frame_rate
    }

    public var codecpar: AVCodecParametersWrapper {
        return AVCodecParametersWrapper(parametersPtr: streamPtr.pointee.codecpar)
    }

    public var mediaType: AVMediaType {
        return codecpar.mediaType
    }

    public func setParameters(_ codecpar: AVCodecParametersWrapper) throws {
        try throwIfFail(avcodec_parameters_copy(streamPtr.pointee.codecpar, codecpar.parametersPtr))
    }

    public func copyParameters(from codecCtx: AVCodecContextWrapper) throws {
        try throwIfFail(avcodec_parameters_from_context(streamPtr.pointee.codecpar, codecCtx.ctxPtr))
    }
}
