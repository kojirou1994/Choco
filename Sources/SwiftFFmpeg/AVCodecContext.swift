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
public struct AVCodecFlag: OptionSet {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    /// Place global headers in extradata instead of every keyframe.
    public static let globalHeader = AVCodecFlag(rawValue: AV_CODEC_FLAG_GLOBAL_HEADER)
}

// MARK: - AVCodecFlag2

public struct AVCodecFlag2: OptionSet {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    /// Allow non spec compliant speedup tricks.
    public static let fast = AVCodecFlag2(rawValue: AV_CODEC_FLAG2_FAST)
    /// Skip bitstream encoding.
    public static let noOutput = AVCodecFlag2(rawValue: AV_CODEC_FLAG2_NO_OUTPUT)
    /// Place global headers at every keyframe instead of in extradata.
    public static let localHeader = AVCodecFlag2(rawValue: AV_CODEC_FLAG2_LOCAL_HEADER)
    /// timecode is in drop frame format.
    @available(*, deprecated)
    public static let dropFrameTimecode = AVCodecFlag2(rawValue: AV_CODEC_FLAG2_DROP_FRAME_TIMECODE)
    /// Input bitstream might be truncated at a packet boundaries instead of only at frame boundaries.
    public static let chunks = AVCodecFlag2(rawValue: AV_CODEC_FLAG2_CHUNKS)
    /// Discard cropping information from SPS.
    public static let ignoreCrop = AVCodecFlag2(rawValue: AV_CODEC_FLAG2_IGNORE_CROP)
    /// Show all frames before the first keyframe.
    public static let showAll = AVCodecFlag2(rawValue: AV_CODEC_FLAG2_SHOW_ALL)
    /// Export motion vectors through frame side data.
    public static let exportMVS = AVCodecFlag2(rawValue: AV_CODEC_FLAG2_EXPORT_MVS)
    /// Do not skip samples and export skip information as frame side data.
    public static let skipManual = AVCodecFlag2(rawValue: AV_CODEC_FLAG2_SKIP_MANUAL)
    /// Do not reset ASS ReadOrder field on flush (subtitles decoding).
    public static let roFlushNoop = AVCodecFlag2(rawValue: AV_CODEC_FLAG2_RO_FLUSH_NOOP)
}

// MARK: - AVCodecContext

//internal typealias CAVCodecContext = CFFmpeg.AVCodecContext

public final class AVCodecContextWrapper {
    public let codec: AVCodecWrapper

    internal let ctxPtr: UnsafeMutablePointer<AVCodecContext>
    internal var ctx: AVCodecContext { return ctxPtr.pointee }

    /// Creates an `AVCodecContext` from the given codec.
    ///
    /// - Parameter codec: codec
    public init?(codec: AVCodecWrapper) {
        guard let ctxPtr = avcodec_alloc_context3(codec.codecPtr) else {
            return nil
        }
        self.codec = codec
        self.ctxPtr = ctxPtr
    }

    /// The codec's media type.
    public var mediaType: AVMediaType {
        return ctx.codec_type
    }

    /// The codec's id.
    public var codecId: AVCodecID {
        get { return ctx.codec_id }
        set { ctxPtr.pointee.codec_id = newValue }
    }
    
    /**
     * profile
     * - encoding: Set by user.
     * - decoding: Set by libavcodec.
     */
    public var profile : Int32 {
        get {
            return ctx.profile
        }
    }
    
    public var profileName: String? {
        if let profileName = avcodec_profile_name(codecId, profile) {
            return String.init(cString: profileName)
        } else {
            return nil
        }
    }
    
//    public var profileName2: String? {
//        if let profileName = av_get_profile_name(codec, <#T##profile: Int32##Int32#>) avcodec_profile_name(codecId, profile) {
//            return String.init(cString: profileName)
//        } else {
//            return nil
//        }
//    }

    /// The codec's tag.
    public var codecTag: UInt32 {
        get { return ctx.codec_tag }
        set { ctxPtr.pointee.codec_tag = newValue }
    }

    public var bitRate: Int64 {
        get { return ctx.bit_rate }
        set { ctxPtr.pointee.bit_rate = newValue }
    }

    public var flags: AVCodecFlag {
        get { return AVCodecFlag(rawValue: ctx.flags) }
        set { ctxPtr.pointee.flags = newValue.rawValue }
    }

    public var flags2: AVCodecFlag2 {
        get { return AVCodecFlag2(rawValue: ctx.flags2) }
        set { ctxPtr.pointee.flags2 = newValue.rawValue }
    }

    public var timebase: AVRational {
        get { return ctx.time_base }
        set { ctxPtr.pointee.time_base = newValue }
    }

    public var frameNumber: Int32 {
        return ctx.frame_number
    }

    /// Returns a Boolean value indicating whether the codec is open.
    public var isOpen: Bool {
        return avcodec_is_open(ctxPtr) > 0
    }

    public func setParameters(_ params: AVCodecParametersWrapper) throws {
        try throwIfFail(avcodec_parameters_to_context(ctxPtr, params.parametersPtr))
    }

    public func openCodec(options: [String: String]? = nil) throws {
        var pm: OpaquePointer?
        defer { av_dict_free(&pm) }
        if let options = options {
            for (k, v) in options {
                av_dict_set(&pm, k, v, 0)
            }
        }

        try throwIfFail(avcodec_open2(ctxPtr, codec.codecPtr, &pm))

        dumpUnrecognizedOptions(pm)
    }

    public func sendPacket(_ packet: AVPacketWrapper?) throws {
        try throwIfFail(avcodec_send_packet(ctxPtr, packet?.packetPtr))
    }

    public func receiveFrame(_ frame: AVFrameWrapper) throws {
        try throwIfFail(avcodec_receive_frame(ctxPtr, frame.framePtr))
    }

    public func sendFrame(_ frame: AVFrameWrapper?) throws {
        try throwIfFail(avcodec_send_frame(ctxPtr, frame?.framePtr))
    }

    public func receivePacket(_ packet: AVPacketWrapper) throws {
        try throwIfFail(avcodec_receive_packet(ctxPtr, packet.packetPtr))
    }
    
    public var str: String {
        var str = [CChar].init(repeating: 0, count: 256)
        avcodec_string(&str, 256, self.ctxPtr, 0)
        return String.init(cString: &str)
    }
    
    deinit {
        var ps: UnsafeMutablePointer<AVCodecContext>? = ctxPtr
        avcodec_free_context(&ps)
    }
}

// MARK: - Video

extension AVCodecContextWrapper {

    /// picture width
    ///
    /// - decoding: Must be set by user.
    /// - encoding: May be set by the user before opening the decoder if known e.g. from the container.
    ///   Some decoders will require the dimensions to be set by the caller. During decoding, the decoder may
    ///   overwrite those values as required while parsing the data.
    public var width: Int32 {
        get { return ctx.width }
        set { ctxPtr.pointee.width = newValue }
    }

    /// picture height
    ///
    /// - decoding: Must be set by user.
    /// - encoding: May be set by the user before opening the decoder if known e.g. from the container.
    ///   Some decoders will require the dimensions to be set by the caller. During decoding, the decoder may
    ///   overwrite those values as required while parsing the data.
    public var height: Int32 {
        get { return ctx.height }
        set { ctxPtr.pointee.height = newValue }
    }

    /// Bitstream width, may be different from `width` e.g. when
    /// the decoded frame is cropped before being output or lowres is enabled.
    ///
    /// - decoding: Unused.
    /// - encoding: May be set by the user before opening the decoder if known e.g. from the container.
    ///   During decoding, the decoder may overwrite those values as required while parsing the data.
    public var codedWidth: Int32 {
        get { return ctx.coded_width }
        set { ctxPtr.pointee.coded_width = newValue }
    }

    /// Bitstream height, may be different from `height` e.g. when
    /// the decoded frame is cropped before being output or lowres is enabled.
    ///
    /// - decoding: Unused.
    /// - encoding: May be set by the user before opening the decoder if known e.g. from the container.
    ///   During decoding, the decoder may overwrite those values as required while parsing the data.
    public var codedHeight: Int {
        get { return Int(ctx.coded_height) }
        set { ctxPtr.pointee.coded_height = Int32(newValue) }
    }

    /// The number of pictures in a group of pictures, or 0 for intra_only.
    ///
    /// - decoding: Set by user.
    /// - encoding: Unused.
    public var gopSize: Int {
        get { return Int(ctx.gop_size) }
        set { ctxPtr.pointee.gop_size = Int32(newValue) }
    }

    /// Pixel format.
    ///
    /// - decoding: Set by user.
    /// - encoding: Set by user if known, overridden by codec while parsing the data.
    public var pixFmt: AVPixelFormat {
        get { return ctx.pix_fmt }
        set { ctxPtr.pointee.pix_fmt = newValue }
    }

    /// Maximum number of B-frames between non-B-frames.
    ///
    /// - decoding: Set by user.
    /// - encoding: Unused.
    public var maxBFrames: Int {
        get { return Int(ctx.max_b_frames) }
        set { ctxPtr.pointee.max_b_frames = Int32(newValue) }
    }

    /// Macroblock decision mode.
    ///
    /// - decoding: Set by user.
    /// - encoding: Unused.
    public var mbDecision: Int {
        get { return Int(ctx.mb_decision) }
        set { ctxPtr.pointee.mb_decision = Int32(newValue) }
    }

    /// Sample aspect ratio (0 if unknown).
    ///
    /// That is the width of a pixel divided by the height of the pixel.
    /// Numerator and denominator must be relatively prime and smaller than 256 for some video standards.
    ///
    /// - decoding: Set by user.
    /// - encoding: Set by codec.
    public var sampleAspectRatio: AVRational {
        get { return ctx.sample_aspect_ratio }
        set { ctxPtr.pointee.sample_aspect_ratio = newValue }
    }

    /// low resolution decoding, 1-> 1/2 size, 2->1/4 size
    ///
    /// - decoding: Set by user.
    /// - encoding: Unused.
    public var lowres: Int32 {
        return ctx.lowres
    }

    /// Framerate.
    ///
    /// - decoding: For codecs that store a framerate value in the compressed bitstream, the decoder may export it here.
    ///   {0, 1} when unknown.
    /// - encoding: May be used to signal the framerate of CFR content to an encoder.
    public var framerate: AVRational {
        get { return ctx.framerate }
        set { ctxPtr.pointee.framerate = newValue }
    }
}

// MARK: - Audio

extension AVCodecContextWrapper {

    /// Samples per second.
    public var sampleRate: Int {
        get { return Int(ctx.sample_rate) }
        set { ctxPtr.pointee.sample_rate = Int32(newValue) }
    }

    /// Number of audio channels.
    public var channelCount: Int {
        get { return Int(ctx.channels) }
        set { ctxPtr.pointee.channels = Int32(newValue) }
    }

    /// Audio sample format.
    public var sampleFmt: AVSampleFormat {
        get { return ctx.sample_fmt }
        set { ctxPtr.pointee.sample_fmt = newValue }
    }

    /// Number of samples per channel in an audio frame.
    public var frameSize: Int {
        return Int(ctx.frame_size)
    }

    /// Audio channel layout.
    ///
    /// - decoding: Set by user.
    /// - encoding: Set by user, may be overwritten by codec.
    public var channelLayout: AVChannelLayout {
        get { return AVChannelLayout(rawValue: ctx.channel_layout) }
        set { ctxPtr.pointee.channel_layout = newValue.rawValue }
    }
}
