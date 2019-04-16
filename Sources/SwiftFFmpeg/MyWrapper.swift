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
    var _value: UnsafeMutablePointer<Pointer> { get }
    
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

public final class FFmpegCodec: CPointerWrapper {
    
    let _value: UnsafeMutablePointer<AVCodec>
    
    init(_ value: UnsafeMutablePointer<AVCodec>) {
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
    public var id: FFmpegCodecID {
        return .init(rawValue: _value.pointee.id)
    }
    
    /// Codec capabilities.
    public var capabilities: Capability {
        return .init(rawValue: _value.pointee.capabilities)
    }
    
    /// Returns an array of the framerates supported by the codec.
    public var supportedFramerates: [AVRational] {
        return readArray(pointer: _value.pointee.supported_framerates, stop: { ($0.den, $0.num) == (0, 0) },
                         transform: { $0 })
    }
    
    /// Returns an array of the pixel formats supported by the codec.
    public var pixelFormats: [FFmpegPixelFormat] {
        return readArray(pointer: _value.pointee.pix_fmts, stop: { $0.rawValue == -1 },
                         transform: { FFmpegPixelFormat.init(rawValue: $0) })
    }
    
    /// Returns an array of the audio samplerates supported by the codec.
    public var supportedSampleRates: [Int32] {
        return readArray(pointer: _value.pointee.supported_samplerates, stop: { $0 == 0 }, transform: {$0})
    }
    
    
    
    /// Returns an array of the sample formats supported by the codec.
    public var sampleFormats: [FFmpegSampleFormat] {
        return readArray(pointer: _value.pointee.sample_fmts, stop: { $0.rawValue == -1 }, transform: {FFmpegSampleFormat.init(rawValue: $0)})
    }
    
    
    /// array of support channel layouts, or NULL if unknown. array is terminated by 0
    public var channelLayouts: [FFmpegChannelLayout] {
        return readArray(pointer: _value.pointee.channel_layouts, stop: { $0 == 0 },
                         transform: { FFmpegChannelLayout(rawValue: $0) })
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

extension FFmpegCodec: CustomStringConvertible {
    public var description: String {
        return """
        name: \(name)
        longName: \(longName)
        mediaType: \(mediaType)
        id: \(id)
        capabilities: \(capabilities)
        supportedFramerates: \(supportedFramerates)
        pixelFormats: \(pixelFormats)
        supportedSampleRates: \(supportedSampleRates)
        sampleFormats: \(sampleFormats)
        channelLayouts: \(channelLayouts)
        maxLowres: \(maxLowres)
        isDecoder: \(isDecoder)
        isEncoder: \(isEncoder)
        """
    }
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
        }
        _value = p
    }
    
    /// A reference to the reference-counted buffer where the packet data is stored.
    /// May be `nil`, then the packet data is not reference-counted.
    public var buffer: FFmpegBuffer? {
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
        set { _value.pointee.pts = newValue }
    }
    
    /// Decompression timestamp in `AVStream.timebase` units; the time at which the packet is decompressed.
    ///
    /// Can be `noPTS` if it is not stored in the file.
    public var dts: Int64 {
        get { return _value.pointee.dts }
        set { _value.pointee.dts = newValue }
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
        set { _value.pointee.stream_index = newValue }
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
    public var position: Int64 {
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
    
    public func moveRef(from packet: FFmpegPacket) {
        av_packet_move_ref(_value, packet._value)
    }
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
    
    public var extendedData: UnsafeMutableBufferPointer<UnsafeMutablePointer<UInt8>?> {
        get {
            let count = pixFmt != .none ? 4 : channelCount
            return UnsafeMutableBufferPointer(start: _value.pointee.extended_data, count: Int(count))
        }
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
    public var pixFmt: FFmpegPixelFormat {
        get { return .init(value: _value.pointee.format) }
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
    
    public func openCodec(options: [String: String] = [:]) throws {
        var dic = FFmpegDictionary.init(dictionary: options)
        var metadata = dic.metadata
        try throwIfFail(avcodec_open2(_value, codec._value, &metadata))

        dumpUnrecognizedOptions(metadata)
//        dic.free()
    }
    
    public func send(packet: FFmpegPacket) throws {
        try throwIfFail(avcodec_send_packet(_value, packet._value))
    }
    
    public func receive(frame: FFmpegFrame) throws {
        try throwIfFail(avcodec_receive_frame(_value, frame._value))
    }
    
    public func send(frame: FFmpegFrame) throws {
        try throwIfFail(avcodec_send_frame(_value, frame._value))
    }
    
    public func receive(packet: FFmpegPacket) throws {
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
        self._value = av_parser_init(Int32(codecContext.codec.id.rawValue.rawValue))
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





/// Stream structure.
public final class FFmpegStream: CPointerWrapper {
    
    internal var _value: UnsafeMutablePointer<AVStream>
    
    internal init(_ value: UnsafeMutablePointer<AVStream>) {
        _value = value
    }
    
    #warning("change to FFmpegFormatContext extension like addStream(codec: FFmpegCodec?)")
    public init?(formatContext: FFmpegFormatContext, codec: FFmpegCodec?) {
        guard let p = avformat_new_stream(formatContext._value, codec?._value) else {
            return nil
        }
        _value = p
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
        return codecParameters.codecType
    }
    
    public func set(codecParameters: FFmpegCodecParameters) throws {
        try throwIfFail(avcodec_parameters_copy(_value.pointee.codecpar, codecParameters._value))
    }
    
    public func copyParameters(from codecCtx: FFmpegCodecContext) throws {
        try throwIfFail(avcodec_parameters_from_context(_value.pointee.codecpar, codecCtx._value))
    }
}
