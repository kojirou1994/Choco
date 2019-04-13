//
//  MyWrapper.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/12.
//

import Foundation
import CFFmpeg

protocol CPointerWrapper: AnyObject {
    associatedtype Pointer
    var _value: UnsafeMutablePointer<Pointer> { get set }
    
    init(_ value: UnsafeMutablePointer<Pointer>)
}

public class FFmpegBuffer: CPointerWrapper {
    
    required init(_ value: UnsafeMutablePointer<AVBufferRef>) {
        _value = value
    }
    
    typealias Pointer = AVBufferRef
    
    var _value: UnsafeMutablePointer<AVBufferRef>
    
    /// Allocate an `AVBuffer` of the given size.
    public init?(size: Int32) {
        guard let p = av_buffer_alloc(size) else {
            return nil
        }
        _value = p
    }
    
    public var data: UnsafeMutablePointer<UInt8>? {
        return _value.pointee.data
    }
    
    /// Size of data in bytes.
    public var size: Int32 {
        return _value.pointee.size
    }
    
    public var refCount: Int32 {
        return av_buffer_get_ref_count(_value)
    }
    
    public func realloc(size: Int32) throws {
//        precondition(_value != nil, "buffer has been freed")
        var buf = Optional.some(_value)
        try throwIfFail(av_buffer_realloc(&buf, size))
        _value = buf!
    }
    
    public func isWritable() -> Bool {
//        precondition(_value != nil, "buffer has been freed")
        return av_buffer_is_writable(_value) > 0
    }
    
    public func makeWritable() throws {
//        precondition(_value != nil, "buffer has been freed")
        var buf = Optional.some(_value)
        try throwIfFail(av_buffer_make_writable(&buf))
        _value = buf!
    }
    
    public func ref() -> FFmpegBuffer? {
//        precondition(_value != nil, "buffer has been freed")
        guard let p = av_buffer_ref(_value) else {
            return nil
        }
        return .init(p)
    }
    
    public func unref() {
        var buf = Optional.some(_value)
        av_buffer_unref(&buf)
    }
    
}

public class FFmpegCodec: CPointerWrapper {
    
    typealias Pointer = AVCodec
    
    var _value: UnsafeMutablePointer<AVCodec>
    
    required init(_ value: UnsafeMutablePointer<Pointer>) {
        _value = value
    }
    
//    internal let codecPtr: UnsafeMutablePointer<AVCodec>
    
    public init?(decoderId: FFmpegCodecID) {
        guard let p = avcodec_find_decoder(decoderId.rawValue) else {
            return nil
        }
        _value = p
    }
    public init?(decoderName: String) {
        guard let p = avcodec_find_decoder_by_name(decoderName) else {
            return nil
        }
        _value = p
    }
    public init?(encoderId: FFmpegCodecID) {
        guard let p = avcodec_find_encoder(encoderId.rawValue) else {
            return nil
        }
        _value = p
    }
    public init?(encoderName: String) {
        guard let p = avcodec_find_encoder_by_name(encoderName) else {
            return nil
        }
        _value = p
    }
    
    /// The codec's name.
    public var name: String {
        return String(cString: _value.pointee.name)
    }
    
    /// The codec's descriptive name, meant to be more human readable than name.
    public var longName: String {
        return String(cString: _value.pointee.long_name)
    }
    
    /// The codec's media type.
    public var mediaType: FFmpegMediaType {
        return .init(rawValue: _value.pointee.type)
    }
    
    /// The codec's id.
    public var id: AVCodecID {
        return _value.pointee.id
    }
    
    /// Codec capabilities.
    public var capabilities: AVCodecCap {
        return AVCodecCap(rawValue: _value.pointee.capabilities)
    }
    
    /// Returns an array of the framerates supported by the codec.
    public var supportedFramerates: [AVRational] {
        var list = [AVRational]()
        var ptr = _value.pointee.supported_framerates
        let zero = AVRational(num: 0, den: 0)
        while let p = ptr, p.pointee != zero {
            list.append(p.pointee)
            ptr = p.advanced(by: 1)
        }
        return list
    }
    
    /// Returns an array of the pixel formats supported by the codec.
    public var pixFmts: [AVPixelFormat] {
        var list = [AVPixelFormat]()
        var ptr = _value.pointee.pix_fmts
        while let p = ptr, p.pointee != AV_PIX_FMT_NONE {
            list.append(p.pointee)
            ptr = p.advanced(by: 1)
        }
        return list
    }
    
    /// Returns an array of the audio samplerates supported by the codec.
    public var supportedSampleRates: [Int] {
        var list = [Int]()
        var ptr = _value.pointee.supported_samplerates
        while let p = ptr, p.pointee != 0 {
            list.append(Int(p.pointee))
            ptr = p.advanced(by: 1)
        }
        return list
    }
    
    /// Returns an array of the sample formats supported by the codec.
    public var sampleFmts: [AVSampleFormat] {
        var list = [AVSampleFormat]()
        var ptr = _value.pointee.sample_fmts
        while let p = ptr, p.pointee != AV_SAMPLE_FMT_NONE {
            list.append(p.pointee)
            ptr = p.advanced(by: 1)
        }
        return list
    }
    
    /// Returns an array of the channel layouts supported by the codec.
    public var channelLayouts: [FFmpegChannelLayout] {
        var list = [FFmpegChannelLayout]()
        var ptr = _value.pointee.channel_layouts
        while let p = ptr, p.pointee != 0 {
            list.append(FFmpegChannelLayout(rawValue: p.pointee))
            ptr = p.advanced(by: 1)
        }
        return list
    }
    
    /// Maximum value for lowres supported by the decoder.
    public var maxLowres: UInt8 {
        return _value.pointee.max_lowres
    }
    
    /// Returns a Boolean value indicating whether the codec is decoder.
    public var isDecoder: Bool {
        return av_codec_is_decoder(_value) != 0
    }
    
    /// Returns a Boolean value indicating whether the codec is encoder.
    public var isEncoder: Bool {
        return av_codec_is_encoder(_value) != 0
    }
}


public class FFmpegInputFormat: CPointerWrapper {

    var _value: UnsafeMutablePointer<AVInputFormat>
    
    required init(_ value: UnsafeMutablePointer<AVInputFormat>) {
        _value = value
    }
    
    /// Find `AVInputFormat` based on the short name of the input format.
    ///
    /// - Parameter name: name of the input format
    public init?(name: String) {
        guard let p = av_find_input_format(name) else {
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
    
    /// Can use flags: `AVFmt.noFile`, `AVFmt.needNumber`, `AVFmt.showIDs`, `AVFmt.genericIndex`,
    /// `AVFmt.tsDiscont`, `AVFmt.noBinSearch`, `AVFmt.noGenSearch`, `AVFmt.noByteSeek`,
    /// `AVFmt.seekToPTS`.
    public var flags: AVFmt {
        get { return AVFmt(rawValue: _value.pointee.flags) }
//        set { _value.pointee.flags = newValue.rawValue }
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
    
    /// Get all registered demuxers.
    public static let all: [FFmpegInputFormat] = {
        var list = [FFmpegInputFormat]()
        var state: UnsafeMutableRawPointer?
        while let fmt = av_demuxer_iterate(&state) {
            list.append(.init(.init(mutating: fmt)))
        }
        return list
    }()
}

public final class FFmpegIOContext: CPointerWrapper {
    
    var _value: UnsafeMutablePointer<AVIOContext>
    
    private var needClose = true
    
    internal init(_ value: UnsafeMutablePointer<AVIOContext>) {
        self._value = value
        self.needClose = false
    }
    
    /// Create and initialize a `AVIOContext` for accessing the resource indicated by url.
    ///
    /// - Parameters:
    ///   - url: resource to access
    ///   - flags: flags which control how the resource indicated by url is to be opened
    /// - Throws: AVError
    public init(url: String, flags: AVIOFlag) throws {
        var pb: UnsafeMutablePointer<AVIOContext>?
        try throwIfFail(avio_open(&pb, url, flags.rawValue))
        _value = pb!
    }
    
    deinit {
        if needClose {
            var pb: UnsafeMutablePointer<AVIOContext>? = _value
            avio_closep(&pb)
        }
    }
}

public final class FFmpegPacket: CPointerWrapper {
    
    var _value: UnsafeMutablePointer<AVPacket>
    //    internal var packet: AVPacket { return _value.pointee }
    
    init(_ value: UnsafeMutablePointer<AVPacket>) {
        _value = value
    }
    
    /// Allocate an `AVPacket` and set its fields to default values.
    ///
    /// - Note: This only allocates the `AVPacket` itself, not the data buffers.
    ///   Those must be allocated through other means such as av_new_packet.
    public init?() {
        guard let p = av_packet_alloc() else {
            return nil
            //            fatalError("av_packet_alloc")
        }
        _value = p
    }
    
    /// A reference to the reference-counted buffer where the packet data is stored.
    /// May be `nil`, then the packet data is not reference-counted.
    public var buf: FFmpegBuffer? {
        get {
            if let bufPtr = _value.pointee.buf {
                return FFmpegBuffer(bufPtr)
            }
            return nil
        }
        set { _value.pointee.buf = newValue?._value }
    }
    
    /// Presentation timestamp in `AVStream.timebase` units; the time at which the decompressed packet
    /// will be presented to the user.
    ///
    /// Can be `noPTS` if it is not stored in the file.
    public var pts: Int64 {
        get { return _value.pointee.pts }
        //        set { _value.pointee.pts = newValue }
    }
    
    /// Decompression timestamp in `AVStream.timebase` units; the time at which the packet is decompressed.
    ///
    /// Can be `noPTS` if it is not stored in the file.
    public var dts: Int64 {
        get { return _value.pointee.dts }
        //        set { _value.pointee.dts = newValue }
    }
    
    public var data: UnsafeMutablePointer<UInt8>? {
        get { return _value.pointee.data }
        //        set { _value.pointee.data = newValue }
    }
    
    public var size: Int32 {
        get { return _value.pointee.size }
        //        set { _value.pointee.size = newValue }
    }
    
    public var streamIndex: Int32 {
        get { return _value.pointee.stream_index }
        //        set { _value.pointee.stream_index = newValue }
    }
    
    public var flags: AVPacketFlag {
        get { return AVPacketFlag(rawValue: _value.pointee.flags) }
        //        set { _value.pointee.flags = newValue.rawValue }
    }
    
    /// Duration of this packet in `AVStream.timebase` units, 0 if unknown.
    /// Equals `next_pts - this_pts` in presentation order.
    public var duration: Int64 {
        get { return _value.pointee.duration }
        set { _value.pointee.duration = newValue }
    }
    
    /// Byte position in stream, -1 if unknown.
    public var pos: Int64 {
        get { return _value.pointee.pos }
        set { _value.pointee.pos = newValue }
    }
    
    /// Setup a new reference to the data described by a given packet.
    ///
    /// If src is reference-counted, setup dst as a new reference to the buffer in src.
    /// Otherwise allocate a new buffer in dst and copy the data from src into it.
    ///
    /// All the other fields are copied from src.
    ///
    /// - Throws: AVerror
    public func ref(dst: FFmpegPacket) throws {
        try throwIfFail(av_packet_ref(dst._value, _value))
    }
    
    /// Wipe the packet.
    ///
    /// Unreference the buffer referenced by the packet and reset the remaining packet fields to their default values.
    public func unref() {
        av_packet_unref(_value)
    }
    
    /// Create a new packet that references the same data as src.
    ///
    /// This is a shortcut for `av_packet_alloc() + av_packet_ref()`.
    ///
    /// - Returns: newly created AVPacket on success, NULL on error.
    public func clone() -> FFmpegPacket? {
        if let ptr = av_packet_clone(_value) {
            return FFmpegPacket(ptr)
        }
        return nil
    }
    
    /// Create a writable reference for the data described by a given packet, avoiding data copy if possible.
    ///
    /// - Throws: AVError
    public func makeWritable() throws {
        try throwIfFail(av_packet_make_writable(_value))
    }
    
    /// Convert valid timing fields (timestamps / durations) in a packet from one timebase to another.
    /// Timestamps with unknown values (`noPTS`) will be ignored.
    ///
    /// - Parameters:
    ///   - src: source timebase, in which the timing fields in pkt are expressed.
    ///   - dst: destination timebase, to which the timing fields will be converted.
    public func rescaleTs(from src: AVRational, to dst: AVRational) {
        av_packet_rescale_ts(_value, src, dst)
    }
    
    deinit {
        var ptr: UnsafeMutablePointer<AVPacket>? = _value
        av_packet_free(&ptr)
    }
}


public final class FFmpegFrame: CPointerWrapper {
    
    init(_ value: UnsafeMutablePointer<AVFrame>) {
        _value = value
    }
    
    //    public var mediaType: AVMediaType = .unknown
    
    var _value: UnsafeMutablePointer<AVFrame>
    
    /// Creates an `AVFrame` and set its fields to default values.
    ///
    /// - Note: This only allocates the `AVFrame` itself, not the data buffers.
    ///   Those must be allocated through other means, e.g. with `allocBuffer` or manually.
    public init?() {
        guard let p = av_frame_alloc() else {
            return nil
        }
        _value = p
    }
    
    /// Pointer to the picture/channel planes.
    //    public var data: [UnsafeMutablePointer<UInt8>?] {
    //        get {
    //            return [
    //                _value.pointee.data.0, _value.pointee.data.1, _value.pointee.data.2, _value.pointee.data.3,
    //                _value.pointee.data.4, _value.pointee.data.5, _value.pointee.data.6, _value.pointee.data.7
    //            ]
    //        }
    //        set {
    //            var list = newValue
    //            while list.count < AV_NUM_DATA_POINTERS {
    //                list.append(nil)
    //            }
    //            _value.pointee.data = (
    //                list[0], list[1], list[2], list[3],
    //                list[4], list[5], list[6], list[7]
    //            )
    //        }
    //    }
    
    /// For video, size in bytes of each picture line.
    /// For audio, size in bytes of each plane.
    ///
    /// For audio, only linesize[0] may be set.
    /// For planar audio, each channel plane must be the same size.
    ///
    /// For video the linesizes should be multiples of the CPUs alignment preference, this is 16 or 32
    /// for modern desktop CPUs. Some code requires such alignment other code can be slower without correct
    /// alignment, for yet other it makes no difference.
    ///
    /// - Note: The linesize may be larger than the size of usable data -- there may be extra padding present
    ///   for performance reasons.
    public var linesize: [Int] {
        get {
            let list = [
                _value.pointee.linesize.0, _value.pointee.linesize.1, _value.pointee.linesize.2, _value.pointee.linesize.3,
                _value.pointee.linesize.4, _value.pointee.linesize.5, _value.pointee.linesize.6, _value.pointee.linesize.7
            ]
            return list.map({ Int($0) })
        }
        set {
            var list = newValue.map({ Int32($0) })
            while list.count < AV_NUM_DATA_POINTERS {
                list.append(0)
            }
            _value.pointee.linesize = (
                list[0], list[1], list[2], list[3],
                list[4], list[5], list[6], list[7]
            )
        }
    }
    
    /// Presentation timestamp in timebase units (time when frame should be shown to user).
    public var pts: Int64 {
        get { return _value.pointee.pts }
        set { _value.pointee.pts = newValue }
    }
    
    /// DTS copied from the AVPacket that triggered returning this frame. (if frame threading isn't used)
    /// This is also the Presentation time of this `AVFrame` calculated from only `AVPacket.dts` values
    /// without pts values.
    public var pkt_dts: Int64 {
        return _value.pointee.pkt_dts
    }
    
    /// Picture number in bitstream order.
    public var codedPictureNumber: Int32 {
        return _value.pointee.coded_picture_number
    }
    
    /// Picture number in display order.
    public var displayPictureNumber: Int32 {
        return _value.pointee.display_picture_number
    }
    
    /// `AVBuffer` references backing the data for this frame.
    ///
    /// If all elements of this array are `nil`, then this frame is not reference counted.
    /// This array must be filled contiguously -- if `buf[i]` is non-nil then `buf[j]` must
    /// also be non-nil for all `j < i`.
    ///
    /// There may be at most one `AVBuffer` per data plane, so for video this array always
    /// contains all the references. For planar audio with more than `AV_NUM_DATA_POINTERS`
    /// channels, there may be more buffers than can fit in this array. Then the extra
    /// `AVBuffer` are stored in the `extendedBuf` array.
    public var buf: [FFmpegBuffer?] {
        let list = [
            _value.pointee.buf.0, _value.pointee.buf.1, _value.pointee.buf.2, _value.pointee.buf.3,
            _value.pointee.buf.4, _value.pointee.buf.5, _value.pointee.buf.6, _value.pointee.buf.7
        ]
        return list.map({ $0 != nil ? FFmpegBuffer($0!) : nil })
    }
    
    /// For planar audio which requires more than `AV_NUM_DATA_POINTERS` `AVBuffer`,
    /// this array will hold all the references which cannot fit into `AVFrame.buf`.
    ///
    /// Note that this is different from `AVFrame.extended_data`, which always contains all the pointers.
    /// This array only contains the extra pointers, which cannot fit into `AVFrame.buf`.
    public var extendedBuf: [FFmpegBuffer] {
        var list = [FFmpegBuffer]()
        let count = Int(extendedBufCount)
        list.reserveCapacity(count)
        for i in 0..<count {
            list.append(FFmpegBuffer(_value.pointee.extended_buf[i]!))
        }
        return list
    }
    
    /// The number of elements in `extendedBuf`.
    public var extendedBufCount: Int32 {
        return _value.pointee.nb_extended_buf
    }
    
    /// Reordered pos from the last `AVPacket` that has been input into the decoder.
    ///
    /// - encoding: Unused.
    /// - decoding: Set by libavcodec, read by user.
    public var pktPos: Int64 {
        return _value.pointee.pkt_pos
    }
    
    /// Duration of the corresponding packet, expressed in `AVStream.timebase` units, 0 if unknown.
    ///
    /// - encoding: Unused.
    /// - decoding: Set by libavcodec, read by user.
    public var pktDuration: Int64 {
        return _value.pointee.pkt_duration
    }
    
    /// Size of the corresponding packet containing the compressed frame. It is set to a negative value if unknown.
    ///
    /// - encoding: Unused.
    /// - decoding: Set by libavcodec, read by user.
    public var pktSize: Int32 {
        return _value.pointee.pkt_size
    }
    
    /// The metadata of the frame.
    ///
    /// - encoding: Set by user.
    /// - decoding: Set by libavcodec.
    public var metadata: FFmpegDictionary {
        get {
            return .init(metadata: _value.pointee.metadata)
        }
//        set {
//            var ptr = _value.pointee.metadata
//            for (k, v) in newValue {
//                av_dict_set(&ptr, k, v, AVOptionSearchFlag.children.rawValue)
//            }
//            _value.pointee.metadata = ptr
//        }
    }
    
    /// Set up a new reference to the data described by the source frame.
    ///
    /// Copy frame properties from src to dst and create a new reference for each `AVBuffer` from src.
    /// If src is not reference counted, new buffers are allocated and the data is copied.
    ///
    /// - Warning: dst MUST have been either unreferenced with av_frame_unref(dst),
    ///           or newly allocated with av_frame_alloc() before calling this
    ///           function, or undefined behavior will occur.
    /// - Throws: AVError
    public func ref(dst: FFmpegFrame) throws {
        try throwIfFail(av_frame_ref(dst._value, _value))
    }
    
    /// Unreference all the buffers referenced by frame and reset the frame fields.
    public func unref() {
        av_frame_unref(_value)
    }
    
    /// Create a new frame that references the same data as src.
    ///
    /// This is a shortcut for `av_frame_alloc() + av_frame_ref()`.
    ///
    /// - Returns: newly created `AVFrame` on success, nil on error.
    public func clone() -> FFmpegFrame? {
        if let ptr = av_frame_clone(_value) {
            return FFmpegFrame(ptr)
        }
        return nil
    }
    
    /// Allocate new buffer(s) for audio or video data.
    ///
    /// The following fields must be set on frame before calling this function:
    ///   - `pixFmt` for video, `sampleFmt` for audio
    ///   - `width` and `height` for video
    ///   - `sampleCount` and `channelLayout` for audio
    ///
    /// This function will fill `AVFrame.data` and `AVFrame.buf` arrays and, if necessary, allocate and fill
    /// `AVFrame.extendedData` and `AVFrame.extendedBuf`. For planar formats, one buffer will be allocated for
    ///  each plane.
    ///
    /// - Warning: If frame already has been allocated, calling this function will leak memory.
    ///   In addition, undefined behavior can occur in certain cases.
    ///
    /// - Parameter align: Required buffer size alignment. If equal to 0, alignment will be chosen automatically
    ///   for the current CPU. It is highly recommended to pass 0 here unless you know what you are doing.
    /// - Throws: AVError
    public func allocBuffer(align: Int32 = 0) throws {
        try throwIfFail(av_frame_get_buffer(_value, align))
    }
    
    /// Check if the frame data is writable.
    ///
    /// - Returns: True if the frame data is writable (which is true if and only if each of the underlying buffers has
    ///   only one reference, namely the one stored in this frame).
    public func isWritable() -> Bool {
        return av_frame_is_writable(_value) > 0
    }
    
    /// Ensure that the frame data is writable, avoiding data copy if possible.
    ///
    /// Do nothing if the frame is writable, allocate new buffers and copy the data if it is not.
    ///
    /// - Throws: AVError
    public func makeWritable() throws {
        try throwIfFail(av_frame_make_writable(_value))
    }
    
    deinit {
        var ptr: UnsafeMutablePointer<AVFrame>? = _value
        av_frame_free(&ptr)
    }
}

// MARK: - Video

extension FFmpegFrame {
    
    /// Pixel format.
    public var pixFmt: AVPixelFormat {
        get { return AVPixelFormat(_value.pointee.format) }
        //        set { _value.pointee.format = newValue.rawValue }
    }
    
    /// Picture width.
    public var width: Int32 {
        get { return _value.pointee.width }
        //        set { _value.pointee.width = newValue }
    }
    
    /// Picture height.
    public var height: Int32 {
        get { return _value.pointee.height }
        //        set { _value.pointee.height = newValue }
    }
    
    /// A Boolean value indicating whether this frame is key frame.
    public var isKeyFrame: Bool {
        return _value.pointee.key_frame == 1
    }
    
    /// The picture type of the frame.
    public var pictType: FFmpegPictureType {
        return .init(rawValue: _value.pointee.pict_type)
    }
    
    /// The sample aspect ratio for the video frame, 0/1 if unknown/unspecified.
    public var sampleAspectRatio: AVRational {
        get { return _value.pointee.sample_aspect_ratio }
        //        set { _value.pointee.sample_aspect_ratio = newValue }
    }
}

// MARK: - Audio

extension FFmpegFrame {
    
    /// Sample format.
    public var sampleFmt: FFmpegSampleFormat {
        get { return .init(rawValue: _value.pointee.format) }
        //        set { _value.pointee.format = newValue.rawValue }
    }
    
    /// The sample rate of the audio data.
    public var sampleRate: Int32 {
        get { return _value.pointee.sample_rate }
        //        set { _value.pointee.sample_rate = newValue }
    }
    
    /// The channel layout of the audio data.
    public var channelLayout: FFmpegChannelLayout {
        get { return FFmpegChannelLayout(rawValue: _value.pointee.channel_layout) }
        //        set { _value.pointee.channel_layout = newValue.rawValue }
    }
    
    /// The number of audio samples (per channel) described by this frame.
    public var sampleCount: Int32 {
        get { return _value.pointee.nb_samples }
        //        set { _value.pointee.nb_samples = newValue }
    }
    
    /// The number of audio channels.
    ///
    /// - encoding: Unused.
    /// - decoding: Read by user.
    public var channelCount: Int32 {
        get { return _value.pointee.channels }
        //        set { _value.pointee.channels = newValue }
    }
}

public final class FFmpegCodecContext: CPointerWrapper {
    var _value: UnsafeMutablePointer<AVCodecContext>
    
    init(_ value: UnsafeMutablePointer<AVCodecContext>) {
        _value = value
        freeWhenDone = false
    }
    
    private let freeWhenDone: Bool
    
    //    public let codec: AVCodecWrapper
    
    /// Creates an `AVCodecContext` from the given codec.
    ///
    /// - Parameter codec: codec
    public init?(codec: FFmpegCodec) {
        guard let p = avcodec_alloc_context3(codec._value) else {
            return nil
        }
        //        self.codec = codec
        self._value = p
        freeWhenDone = true
    }
    
    /// The codec's media type.
    public var mediaType: FFmpegMediaType {
        return .init(rawValue: _value.pointee.codec_type)
    }
    
    public var codec: FFmpegCodec {
        get {
            return .init(.init(mutating: _value.pointee.codec))
        }
    }
    
    /// The codec's id.
    public var codecId: FFmpegCodecID {
        get { return .init(rawValue: _value.pointee.codec_id) }
        set { _value.pointee.codec_id = newValue.rawValue }
    }
    
    /**
     * profile
     * - encoding: Set by user.
     * - decoding: Set by libavcodec.
     */
    public var profile : Int32 {
        get {
            return _value.pointee.profile
        }
        set {
            _value.pointee.profile = newValue
        }
    }
    
    public var profileName: String? {
        if let profileName = avcodec_profile_name(_value.pointee.codec_id, profile) {
            return String.init(cString: profileName)
        } else {
            return nil
        }
    }
    
    /// The codec's tag.
    public var codecTag: UInt32 {
        get { return _value.pointee.codec_tag }
        set { _value.pointee.codec_tag = newValue }
    }
    
    public var bitRate: Int64 {
        get { return _value.pointee.bit_rate }
        set { _value.pointee.bit_rate = newValue }
    }
    
    //    public var flags: AVCodecFlag {
    //        get { return AVCodecFlag(rawValue: _value.pointee.flags) }
    //        set { _value.pointee.flags = newValue.rawValue }
    //    }
    //
    //    public var flags2: AVCodecFlag2 {
    //        get { return AVCodecFlag2(rawValue: _value.pointee.flags2) }
    //        set { _value.pointee.flags2 = newValue.rawValue }
    //    }
    
    public var timebase: AVRational {
        get { return _value.pointee.time_base }
        set { _value.pointee.time_base = newValue }
    }
    
    public var frameNumber: Int32 {
        return _value.pointee.frame_number
    }
    
    /// Returns a Boolean value indicating whether the codec is open.
    public var isOpen: Bool {
        return avcodec_is_open(_value) > 0
    }
    
    public func set(_ parameter: FFmpegCodecParameters) throws {
        try throwIfFail(avcodec_parameters_to_context(_value, parameter._value))
    }
    
    //    public func openCodec(options: [String: String]? = nil) throws {
    //        var pm: OpaquePointer?
    //        defer { av_dict_free(&pm) }
    //        if let options = options {
    //            for (k, v) in options {
    //                av_dict_set(&pm, k, v, 0)
    //            }
    //        }
    //
    //        try throwIfFail(avcodec_open2(_value, codec, &pm))
    //
    //        dumpUnrecognizedOptions(pm)
    //    }
    
    public func sendPacket(_ packet: FFmpegPacket?) throws {
        try throwIfFail(avcodec_send_packet(_value, packet?._value))
    }
    
    public func receiveFrame(_ frame: FFmpegFrame) throws {
        try throwIfFail(avcodec_receive_frame(_value, frame._value))
    }
    
    public func sendFrame(_ frame: FFmpegFrame?) throws {
        try throwIfFail(avcodec_send_frame(_value, frame?._value))
    }
    
    public func receivePacket(_ packet: FFmpegPacket) throws {
        try throwIfFail(avcodec_receive_packet(_value, packet._value))
    }
    
    public var str: String {
        var str = [CChar].init(repeating: 0, count: 256)
        avcodec_string(&str, 256, self._value, 0)
        return String.init(cString: &str)
    }
    
    deinit {
        if freeWhenDone {
            var ps: UnsafeMutablePointer<AVCodecContext>? = _value
            avcodec_free_context(&ps)
        }
    }
}

// MARK: - Video

extension FFmpegCodecContext {
    
    /// picture width
    ///
    /// - decoding: Must be set by user.
    /// - encoding: May be set by the user before opening the decoder if known e.g. from the container.
    ///   Some decoders will require the dimensions to be set by the caller. During decoding, the decoder may
    ///   overwrite those values as required while parsing the data.
    public var width: Int32 {
        get { return _value.pointee.width }
        set { _value.pointee.width = newValue }
    }
    
    /// picture height
    ///
    /// - decoding: Must be set by user.
    /// - encoding: May be set by the user before opening the decoder if known e.g. from the container.
    ///   Some decoders will require the dimensions to be set by the caller. During decoding, the decoder may
    ///   overwrite those values as required while parsing the data.
    public var height: Int32 {
        get { return _value.pointee.height }
        set { _value.pointee.height = newValue }
    }
    
    /// Bitstream width, may be different from `width` e.g. when
    /// the decoded frame is cropped before being output or lowres is enabled.
    ///
    /// - decoding: Unused.
    /// - encoding: May be set by the user before opening the decoder if known e.g. from the container.
    ///   During decoding, the decoder may overwrite those values as required while parsing the data.
    public var codedWidth: Int32 {
        get { return _value.pointee.coded_width }
        set { _value.pointee.coded_width = newValue }
    }
    
    /// Bitstream height, may be different from `height` e.g. when
    /// the decoded frame is cropped before being output or lowres is enabled.
    ///
    /// - decoding: Unused.
    /// - encoding: May be set by the user before opening the decoder if known e.g. from the container.
    ///   During decoding, the decoder may overwrite those values as required while parsing the data.
    public var codedHeight: Int {
        get { return Int(_value.pointee.coded_height) }
        set { _value.pointee.coded_height = Int32(newValue) }
    }
    
    /// The number of pictures in a group of pictures, or 0 for intra_only.
    ///
    /// - decoding: Set by user.
    /// - encoding: Unused.
    public var gopSize: Int32 {
        get { return _value.pointee.gop_size }
        set { _value.pointee.gop_size = newValue }
    }
    
    /// Pixel format.
    ///
    /// - decoding: Set by user.
    /// - encoding: Set by user if known, overridden by codec while parsing the data.
    public var pixFmt: FFmpegPixelFormat {
        get { return .init(rawValue: _value.pointee.pix_fmt) }
        set { _value.pointee.pix_fmt = newValue.rawValue }
    }
    
    /// Maximum number of B-frames between non-B-frames.
    ///
    /// - decoding: Set by user.
    /// - encoding: Unused.
    public var maxBFrames: Int32 {
        get { return _value.pointee.max_b_frames }
        set { _value.pointee.max_b_frames = newValue }
    }
    
    /// Macroblock decision mode.
    ///
    /// - decoding: Set by user.
    /// - encoding: Unused.
    public var mbDecision: Int32 {
        get { return _value.pointee.mb_decision }
        set { _value.pointee.mb_decision = newValue }
    }
    
    /// Sample aspect ratio (0 if unknown).
    ///
    /// That is the width of a pixel divided by the height of the pixel.
    /// Numerator and denominator must be relatively prime and smaller than 256 for some video standards.
    ///
    /// - decoding: Set by user.
    /// - encoding: Set by codec.
    public var sampleAspectRatio: AVRational {
        get { return _value.pointee.sample_aspect_ratio }
        set { _value.pointee.sample_aspect_ratio = newValue }
    }
    
    /// low resolution decoding, 1-> 1/2 size, 2->1/4 size
    ///
    /// - decoding: Set by user.
    /// - encoding: Unused.
    public var lowres: Int32 {
        return _value.pointee.lowres
    }
    
    /// Framerate.
    ///
    /// - decoding: For codecs that store a framerate value in the compressed bitstream, the decoder may export it here.
    ///   {0, 1} when unknown.
    /// - encoding: May be used to signal the framerate of CFR content to an encoder.
    public var framerate: AVRational {
        get { return _value.pointee.framerate }
        set { _value.pointee.framerate = newValue }
    }
}

// MARK: - Audio

extension FFmpegCodecContext {
    
    /// Samples per second.
    public var sampleRate: Int32 {
        get { return _value.pointee.sample_rate }
        set { _value.pointee.sample_rate = newValue }
    }
    
    /// Number of audio channels.
    public var channelCount: Int32 {
        get { return _value.pointee.channels }
        set { _value.pointee.channels = newValue }
    }
    
    /// Audio sample format.
    public var sampleFmt: FFmpegSampleFormat {
        get { return .init(rawValue: _value.pointee.sample_fmt)  }
        set { _value.pointee.sample_fmt = newValue.rawValue }
    }
    
    /// Number of samples per channel in an audio frame.
    public var frameSize: Int32 {
        return _value.pointee.frame_size
    }
    
    /// Audio channel layout.
    ///
    /// - decoding: Set by user.
    /// - encoding: Set by user, may be overwritten by codec.
    public var channelLayout: FFmpegChannelLayout {
        get { return FFmpegChannelLayout(rawValue: _value.pointee.channel_layout) }
        set { _value.pointee.channel_layout = newValue.rawValue }
    }
}

public final class FFmpegCodecParserContext {
    
    var _value: UnsafeMutablePointer<AVCodecParserContext>
    
    private let codecContext: FFmpegCodecContext
    
    public init(codecContext: FFmpegCodecContext) {
        self.codecContext = codecContext
        self._value = av_parser_init(Int32(codecContext.codec.id.rawValue))
    }
    
    public func parse(
        data: UnsafePointer<UInt8>,
        size: Int,
        packet: FFmpegPacket,
        pts: Int64 = AV_NOPTS_VALUE,
        dts: Int64 = AV_NOPTS_VALUE,
        pos: Int64 = 0
        ) -> Int {
        var poutbuf: UnsafeMutablePointer<UInt8>?
        var poutbufSize: Int32 = 0
        let ret = av_parser_parse2(_value, codecContext._value, &poutbuf, &poutbufSize, data, Int32(size), pts, dts, pos)
        packet._value.pointee.data = poutbuf
        packet._value.pointee.size = poutbufSize
        return Int(ret)
    }
    
    deinit {
        av_parser_close(_value)
    }
}

public final class FFmpegOutputFormat: CPointerWrapper {
    
    var _value: UnsafeMutablePointer<AVOutputFormat>
    
    init(_ value: UnsafeMutablePointer<AVOutputFormat>) {
        _value = value
    }
    
    /// A comma separated list of short names for the format.
    public var name: String {
        return String(cString: _value.pointee.name)
    }
    
    /// Descriptive name for the format, meant to be more human-readable than name.
    public var longName: String {
        return String(cString: _value.pointee.long_name)
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
    
    /// default audio codec
    public var audioCodec: FFmpegCodecID {
        return .init(rawValue: _value.pointee.audio_codec)
    }
    
    /// default video codec
    public var videoCodec: FFmpegCodecID {
        return .init(rawValue: _value.pointee.video_codec)
    }
    
    /// default subtitle codec
    public var subtitleCodec: FFmpegCodecID {
        return .init(rawValue: _value.pointee.subtitle_codec)
    }
    
    /// Can use flags: `AVFmt.noFile`, `AVFmt.needNumber`, `AVFmt.globalHeader`, `AVFmt.noTimestamps`,
    /// `AVFmt.variableFPS`, `AVFmt.noDimensions`, `AVFmt.noStreams`, `AVFmt.allowFlush`,
    /// `AVFmt.tsNonstrict`, `AVFmt.tsNegative`.
    public var flags: AVFmt {
        get { return AVFmt(rawValue: _value.pointee.flags) }
        set { _value.pointee.flags = newValue.rawValue }
    }
    
    /// Get all registered muxers.
    public static var all: [FFmpegOutputFormat] {
        var list = [FFmpegOutputFormat]()
        var state: UnsafeMutableRawPointer?
        while let fmt = av_muxer_iterate(&state) {
            list.append(FFmpegOutputFormat(UnsafeMutablePointer(mutating: fmt)))
        }
        return list
    }
}

/// Format I/O context.
public final class FFmpegFormatContext: CPointerWrapper {
    var _value: UnsafeMutablePointer<AVFormatContext>
    
    init(_ value: UnsafeMutablePointer<AVFormatContext>) {
        _value = value
        isOpen = false
    }
    
    private var isOpen: Bool
    private var ioContext: FFmpegIOContext?
    
    /// Allocate an `AVFormatContext`.
    public init?() {
        _value = avformat_alloc_context()
        isOpen = false
    }
    
    /// Input or output URL.
    public var url: String? {
        if let strBytes = _value.pointee.url {
            return String(cString: strBytes)
        }
        return nil
    }
    
    /// The input container format.
    public var iformat: FFmpegInputFormat? {
        get {
            if let fmtPtr = _value.pointee.iformat {
                return FFmpegInputFormat(fmtPtr)
            }
            return nil
        }
        set { _value.pointee.iformat = newValue?._value }
    }
    
    /// The output container format.
    public var oformat: FFmpegOutputFormat? {
        get {
            if let fmtPtr = _value.pointee.oformat {
                return FFmpegOutputFormat(fmtPtr)
            }
            return nil
        }
        set { _value.pointee.oformat = newValue?._value }
    }
    
    /// I/O context.
    ///
    /// - demuxing: either set by the user before avformat_open_input() (then the user must close it manually)
    ///   or set by avformat_open_input().
    /// - muxing: set by the user before avformat_write_header(). The caller must take care of closing / freeing
    ///   the IO context.
    internal var pb: FFmpegIOContext? {
        get {
            if let ctxPtr = _value.pointee.pb {
                return FFmpegIOContext(ctxPtr)
            }
            return nil
        }
        set {
            ioContext = newValue
            return _value.pointee.pb = newValue?._value
        }
    }
    
    /// Number of streams.
    public var streamCount: UInt32 {
        return _value.pointee.nb_streams
    }
    
    /// A list of all streams in the file.
    public var streams: [FFmpegStream] {
        var list = [FFmpegStream]()
        for i in 0..<Int(streamCount) {
            let stream = _value.pointee.streams.advanced(by: i).pointee!
            list.append(FFmpegStream(stream))
        }
        return list
    }
    
    public var videoStream: FFmpegStream? {
        return streams.first { $0.mediaType == .video }
    }
    
    public var audioStream: FFmpegStream? {
        return streams.first { $0.mediaType == .audio }
    }
    
    public var subtitleStream: FFmpegStream? {
        return streams.first { $0.mediaType == .subtitle }
    }
    
    /// Position of the first frame of the component, in AV_TIME_BASE fractional seconds.
    /// Never set this value directly: It is deduced from the AVStream values.
    ///
    /// Demuxing only, set by libavformat.
    public var startTime: Int64 {
        return _value.pointee.start_time
    }
    
    /// Duration of the stream, in AV_TIME_BASE fractional seconds. Only set this value if you know
    /// none of the individual stream durations and also do not set any of them.
    /// This is deduced from the AVStream values if not set.
    ///
    /// Demuxing only, set by libavformat.
    public var duration: Int64 {
        return _value.pointee.duration
    }
    
    /// Flags modifying the (de)muxer behaviour. A combination of AVFMT_FLAG_*.
    ///
    /// Set by the user before `openInput` / `writeHeader`.
    public var flags: AVFmtFlag {
        get { return AVFmtFlag(rawValue: _value.pointee.flags) }
        set { _value.pointee.flags = newValue.rawValue }
    }
    
    /// Metadata that applies to the whole file.
    public var metadata: [String : String] {
        return FFmpegDictionary.parse(metadata: _value.pointee.metadata)
    }
    
    /// Custom interrupt callbacks for the I/O layer.
    ///
    /// - demuxing: set by the user before avformat_open_input().
    /// - muxing: set by the user before avformat_write_header() (mainly useful for AVFMT_NOFILE formats).
    ///   The callback should also be passed to avio_open2() if it's used to open the file.
    public var interruptCallback: AVIOInterruptCB {
        get { return _value.pointee.interrupt_callback }
        set { _value.pointee.interrupt_callback = newValue }
    }
    
    //    public func streamIndex(for mediaType: AVMediaTypeWrapper) -> Int? {
    //        if let index = streams.firstIndex(where: { $0.codecpar.mediaType == mediaType }) {
    //            return index
    //        }
    //        return nil
    //    }
    
    /// Print detailed information about the input or output format, such as duration, bitrate, streams, container,
    /// programs, metadata, side data, codec and time base.
    ///
    /// - Parameters isOutput: Select whether the specified context is an input(0) or output(1).
    public func dumpFormat(isOutput: Bool) {
        av_dump_format(_value, 0, url, isOutput ? 1 : 0)
    }
    
    deinit {
        if isOpen {
            var ps: UnsafeMutablePointer<AVFormatContext>? = _value
            avformat_close_input(&ps)
        } else {
            avformat_free_context(_value)
        }
    }
}

// MARK: - Demuxing

extension FFmpegFormatContext {
    
    /// Open an input stream and read the header. The codecs are not opened.
    ///
    /// - Parameters:
    ///   - url: URL of the stream to open.
    ///   - format: If non-nil, this parameter forces a specific input format. Otherwise the format is autodetected.
    ///   - options: A dictionary filled with `AVFormatContext` and demuxer-private options.
    /// - Throws: AVError
    public convenience init(url: String, format: FFmpegInputFormat? = nil, options: [String: String]? = nil) throws {
        var pm: OpaquePointer?
        defer { av_dict_free(&pm) }
        if let options = options {
            for (k, v) in options {
                av_dict_set(&pm, k, v, 0)
            }
        }
        
        var ctxPtr: UnsafeMutablePointer<AVFormatContext>?
        try throwIfFail(avformat_open_input(&ctxPtr, url, format?._value, &pm))
        self.init(ctxPtr!)
        self.isOpen = true
        
        dumpUnrecognizedOptions(pm)
    }
    
    /// Open an input stream and read the header.
    ///
    /// - Parameter url: URL of the stream to open.
    public func openInput(_ url: String) throws {
        var ps: UnsafeMutablePointer<AVFormatContext>? = _value
        try throwIfFail(avformat_open_input(&ps, url, nil, nil))
        isOpen = true
    }
    
    /// Read packets of a media file to get stream information.
    public func findStreamInfo() throws {
        try throwIfFail(avformat_find_stream_info(_value, nil))
    }
    
    /// Find the "best" stream in the file.
    ///
    /// - Parameter type: stream type: video, audio, subtitles, etc.
    /// - Returns: stream number
    /// - Throws: AVError
    public func findBestStream(type: FFmpegMediaType) throws -> Int {
        let ret = av_find_best_stream(_value, type.rawValue, -1, -1, nil, 0)
        try throwIfFail(ret)
        return Int(ret)
    }
    
    /// Guess the sample aspect ratio of a frame, based on both the stream and the frame aspect ratio.
    ///
    /// Since the frame aspect ratio is set by the codec but the stream aspect ratio is set by the demuxer,
    /// these two may not be equal. This function tries to return the value that you should use if you would
    /// like to display the frame.
    ///
    /// Basic logic is to use the stream aspect ratio if it is set to something sane otherwise use the frame
    /// aspect ratio. This way a container setting, which is usually easy to modify can override the coded value
    /// in the frames.
    ///
    /// - Parameters:
    ///   - stream: the stream which the frame is part of
    ///   - frame: the frame with the aspect ratio to be determined
    /// - Returns: the guessed (valid) sample_aspect_ratio, 0/1 if no idea
    public func guessSampleAspectRatio(stream: FFmpegStream?, frame: FFmpegFrame?) -> AVRational {
        return av_guess_sample_aspect_ratio(_value, stream?._value, frame?._value)
    }
    
    /// Return the next frame of a stream.
    ///
    /// This function returns what is stored in the file, and does not validate that what is there are valid frames
    /// for the decoder. It will split what is stored in the file into frames and return one for each call. It will
    /// not omit invalid data between valid frames so as to give the decoder the maximum information possible for
    /// decoding.
    ///
    /// - Parameter packet: packet
    /// - Throws: AVError
    public func readFrame(into packet: FFmpegPacket) throws {
        try throwIfFail(av_read_frame(_value, packet._value))
    }
    
    /// Seek to the keyframe at timestamp.
    /// 'timestamp' in 'stream_index'.
    ///
    /// - Parameters:
    ///   - streamIndex: If stream_index is (-1), a default stream is selected, and timestamp is automatically
    ///     converted from AV_TIME_BASE units to the stream specific time_base.
    ///   - timestamp: Timestamp in AVStream.time_base units or, if no stream is specified, in AV_TIME_BASE units.
    ///   - flags: flags which select direction and seeking mode
    /// - Throws: AVError
    public func seekFrame(streamIndex: Int, timestamp: Int64, flags: Int) throws {
        try throwIfFail(av_seek_frame(_value, Int32(streamIndex), timestamp, Int32(flags)))
    }
    
    /// Discard all internally buffered data. This can be useful when dealing with
    /// discontinuities in the byte stream. Generally works only with formats that
    /// can resync. This includes headerless formats like MPEG-TS/TS but should also
    /// work with NUT, Ogg and in a limited way AVI for example.
    ///
    /// The set of streams, the detected duration, stream parameters and codecs do
    /// not change when calling this function. If you want a complete reset, it's
    /// better to open a new AVFormatContext.
    ///
    /// This does not flush the AVIOContext (s->pb). If necessary, call
    /// avio_flush(s->pb) before calling this function.
    ///
    /// - Throws: AVError
    public func flush() throws {
        try throwIfFail(avformat_flush(_value))
    }
    
    /// Start playing a network-based stream (e.g. RTSP stream) at the current position.
    ///
    /// - Throws: AVError
    public func readPlay() throws {
        try throwIfFail(av_read_play(_value))
    }
    
    /// Pause a network-based stream (e.g. RTSP stream).
    ///
    /// Use av_read_play() to resume it.
    ///
    /// - Throws: AVError
    public func readPause() throws {
        try throwIfFail(av_read_pause(_value))
    }
}

// MARK: - Muxing

extension FFmpegFormatContext {
    
    /// Allocate an `AVFormatContext` for an output format.
    ///
    /// - Parameters:
    ///   - format: format to use for allocating the context, if `nil` formatName and filename are used instead
    ///   - formatName: the name of output format to use for allocating the context, if `nil` filename is used instead
    ///   - filename: the name of the filename to use for allocating the context, may be `nil`
    /// - Throws: AVError
    public convenience init(format: FFmpegOutputFormat?, formatName: String? = nil, filename: String? = nil) throws {
        var ctxPtr: UnsafeMutablePointer<AVFormatContext>?
        try throwIfFail(avformat_alloc_output_context2(&ctxPtr, format?._value, formatName, filename))
        self.init(ctxPtr!)
    }
    
    /// Create and initialize a AVIOContext for accessing the resource indicated by url.
    ///
    /// - Parameters:
    ///   - url: resource to access
    ///   - flags: flags which control how the resource indicated by url is to be opened
    /// - Throws: AVError
    public func openIO(url: String, flags: AVIOFlag) throws {
        pb = try FFmpegIOContext(url: url, flags: flags)
    }
    
    /// Add a new stream to a media file.
    ///
    /// - Parameter codec: If non-nil, the AVCodecContext corresponding to the new stream will be initialized to use
    ///   this codec. This is needed for e.g. codec-specific defaults to be set, so codec should be provided if it is
    ///   known.
    /// - Returns: newly created stream or `nil` on error.
    public func addStream(codec: FFmpegCodec? = nil) -> FFmpegStream? {
        if let streamPtr = avformat_new_stream(_value, codec?._value) {
            return FFmpegStream(streamPtr)
        }
        return nil
    }
    
    /// Allocate the stream private data and write the stream header to an output media file.
    ///
    /// - Parameter options: An AVDictionary filled with AVFormatContext and muxer-private options.
    /// - Throws: AVError
    public func writeHeader(options: [String: String]? = nil) throws {
        var pm: OpaquePointer?
        defer { av_dict_free(&pm) }
        if let options = options {
            for (k, v) in options {
                av_dict_set(&pm, k, v, 0)
            }
        }
        
        try throwIfFail(avformat_write_header(_value, &pm))
        
        dumpUnrecognizedOptions(pm)
    }
    
    /// Write a packet to an output media file.
    ///
    /// - Parameter pkt: The packet containing the data to be written.
    /// - Throws: AVError
    public func writeFrame(pkt: FFmpegPacket?) throws {
        try throwIfFail(av_write_frame(_value, pkt?._value))
    }
    
    /// Write a packet to an output media file ensuring correct interleaving.
    ///
    /// - Parameter pkt: The packet containing the data to be written.
    /// - Throws: AVError
    public func interleavedWriteFrame(pkt: FFmpegPacket?) throws {
        try throwIfFail(av_interleaved_write_frame(_value, pkt?._value))
    }
    
    /// Write the stream trailer to an output media file and free the file private data.
    ///
    /// May only be called after a successful call to `writeHeader(options:)`.
    ///
    /// - Throws: AVError
    public func writeTrailer() throws {
        try throwIfFail(av_write_trailer(_value))
    }
}

public final class FFmpegCodecParameters: CPointerWrapper {
    
    typealias Pointer = AVCodecParameters
    
    internal var _value: UnsafeMutablePointer<AVCodecParameters>
    
    internal init(_ value: UnsafeMutablePointer<AVCodecParameters>) {
        self._value = value
    }
    
    /// General type of the encoded data.
    public var mediaType: FFmpegMediaType {
        return .init(rawValue: _value.pointee.codec_type)
    }
    
    /// Specific type of the encoded data (the codec used).
    public var codecId: FFmpegCodecID {
        return .init(rawValue: _value.pointee.codec_id) 
    }
    
    /// Additional information about the codec (corresponds to the AVI FOURCC).
    public var codecTag: UInt32 {
        get { return _value.pointee.codec_tag }
        //        set { _value.pointee.codec_tag = newValue }
    }
    
    /// The average bitrate of the encoded data (in bits per second).
    public var bitRate: Int64 {
        return _value.pointee.bit_rate
    }
}

// MARK: - Video

extension FFmpegCodecParameters {
    
    
    /// - video: the pixel format, the value corresponds to enum AVPixelFormat. - audio: the sample format, the value corresponds to enum AVSampleFormat.
    public var pixelFormat: FFmpegPixelFormat {
        return .init(value: _value.pointee.format)
    }
    
    /// The width of the video frame in pixels.
    public var width: Int32 {
        return _value.pointee.width
    }
    
    /// The height of the video frame in pixels.
    public var height: Int32 {
        return _value.pointee.height
    }
    
    /// The aspect ratio (width / height) which a single pixel should have when displayed.
    ///
    /// When the aspect ratio is unknown / undefined, the numerator should be
    /// set to 0 (the denominator may have any value).
    public var sampleAspectRatio: AVRational {
        return _value.pointee.sample_aspect_ratio
    }
    
    /// Number of delayed frames.
    public var videoDelay: Int32 {
        return _value.pointee.video_delay
    }
}

// MARK: - Audio

extension FFmpegCodecParameters {
    
    /// Sample format.
    public var sampleFormat: FFmpegSampleFormat {
        return .init(rawValue: _value.pointee.format)
    }
    
    /// The channel layout bitmask. May be 0 if the channel layout is
    /// unknown or unspecified, otherwise the number of bits set must be equal to
    /// the channels field.
    public var channelLayout: FFmpegChannelLayout {
        return FFmpegChannelLayout(rawValue: _value.pointee.channel_layout)
    }
    
    /// The number of audio channels.
    public var channelCount: Int32 {
        return _value.pointee.channels
    }
    
    /// The number of audio samples per second.
    public var sampleRate: Int32 {
        return _value.pointee.sample_rate
    }
    
    /// Audio frame size, if known. Required by some formats to be static.
    public var frameSize: Int32 {
        return _value.pointee.frame_size
    }
}

/// Stream structure.
public final class FFmpegStream: CPointerWrapper {
    
    internal var _value: UnsafeMutablePointer<AVStream>
    
    internal init(_ value: UnsafeMutablePointer<AVStream>) {
        _value = value
    }
    
    public var id: Int32 {
        get { return _value.pointee.id }
        set { _value.pointee.id = newValue }
    }
    
    public var index: Int32 {
        return _value.pointee.index
    }
    
    public var timebase: AVRational {
        get { return _value.pointee.time_base }
        set { _value.pointee.time_base = newValue }
    }
    
    public var startTime: Int64 {
        return _value.pointee.start_time
    }
    
    public var duration: Int64 {
        return _value.pointee.duration
    }
    
    public var frameCount: Int64 {
        return _value.pointee.nb_frames
    }
    
    public var discard: AVDiscard {
        get { return _value.pointee.discard }
        set { _value.pointee.discard = newValue }
    }
    
    public var sampleAspectRatio: AVRational {
        return _value.pointee.sample_aspect_ratio
    }
    
    public var metadata: FFmpegDictionary {
        return .init(metadata: _value.pointee.metadata)
    }
    
    public var averageFramerate: AVRational {
        return _value.pointee.avg_frame_rate
    }
    
    public var realFramerate: AVRational {
        return _value.pointee.r_frame_rate
    }
    
    public var codecParameters: FFmpegCodecParameters {
        return FFmpegCodecParameters(_value.pointee.codecpar)
    }
    
    public var mediaType: FFmpegMediaType {
        return codecParameters.mediaType
    }
    
    public func set(codecParameters: FFmpegCodecParameters) throws {
        try throwIfFail(avcodec_parameters_copy(_value.pointee.codecpar, codecParameters._value))
    }
    
    public func copyParameters(from codecCtx: FFmpegCodecContext) throws {
        try throwIfFail(avcodec_parameters_from_context(_value.pointee.codecpar, codecCtx._value))
    }
}
