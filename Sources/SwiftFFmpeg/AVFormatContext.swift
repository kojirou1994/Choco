//
//  AVFormatContext.swift
//  SwiftFFmpeg
//
//  Created by sunlubo on 2018/6/29.
//

import CFFmpeg

// MARK: - AVFmt

public struct AVFmt: OptionSet {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    /// Demuxer will use avio_open, no opened file should be provided by the caller.
    public static let noFile = AVFmt(rawValue: AVFMT_NOFILE)
    /// Needs '%d' in filename.
    public static let needNumber = AVFmt(rawValue: AVFMT_NEEDNUMBER)
    /// Show format stream IDs numbers.
    public static let showIDs = AVFmt(rawValue: AVFMT_SHOW_IDS)
    /// Format wants global header.
    public static let globalHeader = AVFmt(rawValue: AVFMT_GLOBALHEADER)
    /// Format does not need / have any timestamps.
    public static let noTimestamps = AVFmt(rawValue: AVFMT_NOTIMESTAMPS)
    /// Use generic index building code.
    public static let genericIndex = AVFmt(rawValue: AVFMT_GENERIC_INDEX)
    /// Format allows timestamp discontinuities. Note, muxers always require valid (monotone) timestamps.
    public static let tsDiscont = AVFmt(rawValue: AVFMT_TS_DISCONT)
    /// Format allows variable fps.
    public static let variableFPS = AVFmt(rawValue: AVFMT_VARIABLE_FPS)
    /// Format does not need width/height.
    public static let noDimensions = AVFmt(rawValue: AVFMT_NODIMENSIONS)
    /// Format does not require any streams.
    public static let noStreams = AVFmt(rawValue: AVFMT_NOSTREAMS)
    /// Format does not allow to fall back on binary search via read_timestamp.
    public static let noBinSearch = AVFmt(rawValue: AVFMT_NOBINSEARCH)
    /// Format does not allow to fall back on generic search.
    public static let noGenSearch = AVFmt(rawValue: AVFMT_NOGENSEARCH)
    /// Format does not allow seeking by bytes.
    public static let noByteSeek = AVFmt(rawValue: AVFMT_NO_BYTE_SEEK)
    /// Format allows flushing. If not set, the muxer will not receive a NULL packet in the write_packet function.
    public static let allowFlush = AVFmt(rawValue: AVFMT_ALLOW_FLUSH)
    /// Format does not require strictly increasing timestamps, but they must still be monotonic.
    public static let tsNonstrict = AVFmt(rawValue: AVFMT_TS_NONSTRICT)
    /// Format allows muxing negative timestamps. If not set the timestamp will be shifted in av_write_frame and
    /// av_interleaved_write_frame so they start from 0.
    /// The user or muxer can override this through AVFormatContext.avoid_negative_ts.
    public static let tsNegative = AVFmt(rawValue: AVFMT_TS_NEGATIVE)
    /// Seeking is based on PTS
    public static let seekToPTS = AVFmt(rawValue: AVFMT_SEEK_TO_PTS)
}

// MARK: - AVFmtFlag

public struct AVFmtFlag: OptionSet {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    /// Generate missing pts even if it requires parsing future frames.
    public static let genPTS = AVFmtFlag(rawValue: AVFMT_FLAG_GENPTS)
    /// Ignore index.
    public static let ignIdx = AVFmtFlag(rawValue: AVFMT_FLAG_IGNIDX)
    /// Do not block when reading packets from input.
    public static let nonBlock = AVFmtFlag(rawValue: AVFMT_FLAG_NONBLOCK)
    /// Ignore DTS on frames that contain both DTS & PTS.
    public static let ignDTS = AVFmtFlag(rawValue: AVFMT_FLAG_IGNDTS)
    /// Do not infer any values from other values, just return what is stored in the container.
    public static let noFillIn = AVFmtFlag(rawValue: AVFMT_FLAG_NOFILLIN)
    /// Do not use AVParsers, you also must set AVFMT_FLAG_NOFILLIN as the fillin code works on frames and
    /// no parsing -> no frames. Also seeking to frames can not work if parsing to find frame boundaries has been
    /// disabled.
    public static let noParse = AVFmtFlag(rawValue: AVFMT_FLAG_NOPARSE)
    /// Do not buffer frames when possible.
    public static let noBuffer = AVFmtFlag(rawValue: AVFMT_FLAG_NOBUFFER)
    /// The caller has supplied a custom AVIOContext, don't avio_close() it.
    public static let customIO = AVFmtFlag(rawValue: AVFMT_FLAG_CUSTOM_IO)
    /// Discard frames marked corrupted.
    public static let discardCorrupt = AVFmtFlag(rawValue: AVFMT_FLAG_DISCARD_CORRUPT)
    /// Flush the AVIOContext every packet.
    public static let flushPackets = AVFmtFlag(rawValue: AVFMT_FLAG_FLUSH_PACKETS)
    /// When muxing, try to avoid writing any random/volatile data to the output.
    /// This includes any random IDs, real-time timestamps/dates, muxer version, etc.
    ///
    /// This flag is mainly intended for testing.
    public static let bitExact = AVFmtFlag(rawValue: AVFMT_FLAG_BITEXACT)
    /// Deprecated, does nothing.
    @available(*, deprecated)
    public static let mp4aLATM = AVFmtFlag(rawValue: AVFMT_FLAG_MP4A_LATM)
    /// Try to interleave outputted packets by dts (using this flag can slow demuxing down).
    public static let sortDTS = AVFmtFlag(rawValue: AVFMT_FLAG_SORT_DTS)
    /// Enable use of private options by delaying codec open (this could be made default once all code is converted).
    public static let privOpt = AVFmtFlag(rawValue: AVFMT_FLAG_PRIV_OPT)
    /// Deprecated, does nothing.
    @available(*, deprecated)
    public static let keepSideData = AVFmtFlag(rawValue: AVFMT_FLAG_KEEP_SIDE_DATA)
    /// Enable fast, but inaccurate seeks for some formats.
    public static let fastSeek = AVFmtFlag(rawValue: AVFMT_FLAG_FAST_SEEK)
    /// Stop muxing when the shortest stream stops.
    public static let shortest = AVFmtFlag(rawValue: AVFMT_FLAG_SHORTEST)
    /// Add bitstream filters as requested by the muxer.
    public static let autoBSF = AVFmtFlag(rawValue: AVFMT_FLAG_AUTO_BSF)
}

// MARK: - AVInputFormat

//internal typealias AVInputFormat = CFFmpeg.AVInputFormat

public struct AVInputFormatWrapper {
    internal let fmt: UnsafeMutablePointer<AVInputFormat>

    internal init(fmt: UnsafeMutablePointer<AVInputFormat>) {
        self.fmt = fmt
    }

    /// Find `AVInputFormat` based on the short name of the input format.
    ///
    /// - Parameter name: name of the input format
    public init?(name: String) {
        guard let fmtPtr = av_find_input_format(name) else {
            return nil
        }
        self.init(fmt: fmtPtr)
    }

    /// A comma separated list of short names for the format.
    public var name: String {
        return String(cString: fmt.pointee.name)
    }

    /// Descriptive name for the format, meant to be more human-readable than name.
    public var longName: String {
        return String(cString: fmt.pointee.long_name)
    }

    /// Can use flags: `AVFmt.noFile`, `AVFmt.needNumber`, `AVFmt.showIDs`, `AVFmt.genericIndex`,
    /// `AVFmt.tsDiscont`, `AVFmt.noBinSearch`, `AVFmt.noGenSearch`, `AVFmt.noByteSeek`,
    /// `AVFmt.seekToPTS`.
    public var flags: AVFmt {
        get { return AVFmt(rawValue: fmt.pointee.flags) }
        set { fmt.pointee.flags = newValue.rawValue }
    }

    /// If extensions are defined, then no probe is done. You should usually not use extension format guessing because
    /// it is not reliable enough.
    public var extensions: String? {
        if let strBytes = fmt.pointee.extensions {
            return String(cString: strBytes)
        }
        return nil
    }

    /// Comma-separated list of mime types.
    ///
    /// It is used check for matching mime types while probing.
    public var mimeType: String? {
        if let strBytes = fmt.pointee.mime_type {
            return String(cString: strBytes)
        }
        return nil
    }

    /// Get all registered demuxers.
    public static var all: [AVInputFormatWrapper] {
        var list = [AVInputFormatWrapper]()
        var state: UnsafeMutableRawPointer?
        while let fmt = av_demuxer_iterate(&state) {
            list.append(AVInputFormatWrapper(fmt: UnsafeMutablePointer(mutating: fmt)))
        }
        return list
    }
}

// MARK: - AVOutputFormat
//internal typealias AVOutputFormat = CFFmpeg.AVOutputFormat

public struct AVOutputFormatWrapper {
    internal let fmtPtr: UnsafeMutablePointer<AVOutputFormat>
    internal var fmt: AVOutputFormat { return fmtPtr.pointee }

    internal init(fmtPtr: UnsafeMutablePointer<AVOutputFormat>) {
        self.fmtPtr = fmtPtr
    }

    /// A comma separated list of short names for the format.
    public var name: String {
        return String(cString: fmt.name)
    }

    /// Descriptive name for the format, meant to be more human-readable than name.
    public var longName: String {
        return String(cString: fmt.long_name)
    }

    /// If extensions are defined, then no probe is done. You should usually not use extension format guessing because
    /// it is not reliable enough.
    public var extensions: String? {
        if let strBytes = fmt.extensions {
            return String(cString: strBytes)
        }
        return nil
    }

    /// Comma-separated list of mime types.
    ///
    /// It is used check for matching mime types while probing.
    public var mimeType: String? {
        if let strBytes = fmt.mime_type {
            return String(cString: strBytes)
        }
        return nil
    }

    /// default audio codec
    public var audioCodec: AVCodecID {
        return fmt.audio_codec
    }

    /// default video codec
    public var videoCodec: AVCodecID {
        return fmt.video_codec
    }

    /// default subtitle codec
    public var subtitleCodec: AVCodecID {
        return fmt.subtitle_codec
    }

    /// Can use flags: `AVFmt.noFile`, `AVFmt.needNumber`, `AVFmt.globalHeader`, `AVFmt.noTimestamps`,
    /// `AVFmt.variableFPS`, `AVFmt.noDimensions`, `AVFmt.noStreams`, `AVFmt.allowFlush`,
    /// `AVFmt.tsNonstrict`, `AVFmt.tsNegative`.
    public var flags: AVFmt {
        get { return AVFmt(rawValue: fmt.flags) }
        set { fmtPtr.pointee.flags = newValue.rawValue }
    }

    /// Get all registered muxers.
    public static var all: [AVOutputFormatWrapper] {
        var list = [AVOutputFormatWrapper]()
        var state: UnsafeMutableRawPointer?
        while let fmt = av_muxer_iterate(&state) {
            list.append(AVOutputFormatWrapper(fmtPtr: UnsafeMutablePointer(mutating: fmt)))
        }
        return list
    }
}

public struct AVDictionary {
    
    private var metadata: OpaquePointer?
    
    internal init(metadata: OpaquePointer?) {
        self.metadata = metadata
    }
    
    public static func parse(metadata: OpaquePointer?) -> [String: String] {
        var dict = [String: String]()
        var previousEntry: UnsafeMutablePointer<AVDictionaryEntry>?
        while let nextEntry = av_dict_get(metadata, "", previousEntry, AV_DICT_IGNORE_SUFFIX) {
            dict[String(cString: nextEntry.pointee.key)] = String(cString: nextEntry.pointee.value)
            previousEntry = nextEntry
        }
        return dict
    }
    
    public var dictionary: [String: String] {
        return AVDictionary.parse(metadata: metadata)
    }
    
    public subscript(key: String) -> String? {
        get {
            if let value = av_dict_get(metadata, key, nil, 0) {
                return String.init(cString: value.pointee.value)
            } else {
                return nil
            }
        }
        set {
            av_dict_set(&metadata, key, newValue, 0)
        }
    }
}

// MARK: - AVFormatContext

//internal typealias AVFormatContext = CFFmpeg.AVFormatContext

/// Format I/O context.
public final class AVFormatContextWrapper {
    internal let avformatContext: UnsafeMutablePointer<AVFormatContext>

    private var isOpen = false
    private var ioCtx: AVIOContextWrapper?

    internal init(avformatContext: UnsafeMutablePointer<AVFormatContext>) {
        self.avformatContext = avformatContext
    }

    /// Allocate an `AVFormatContext`.
    public init() {
        self.avformatContext = avformat_alloc_context()
    }

    /// Input or output URL.
    public var url: String? {
        if let strBytes = avformatContext.pointee.url {
            return String(cString: strBytes)
        }
        return nil
    }

    /// The input container format.
    public var iformat: AVInputFormatWrapper? {
        get {
            if let fmtPtr = avformatContext.pointee.iformat {
                return AVInputFormatWrapper(fmt: fmtPtr)
            }
            return nil
        }
        set { avformatContext.pointee.iformat = newValue?.fmt }
    }

    /// The output container format.
    public var oformat: AVOutputFormatWrapper? {
        get {
            if let fmtPtr = avformatContext.pointee.oformat {
                return AVOutputFormatWrapper(fmtPtr: fmtPtr)
            }
            return nil
        }
        set { avformatContext.pointee.oformat = newValue?.fmtPtr }
    }

    /// I/O context.
    ///
    /// - demuxing: either set by the user before avformat_open_input() (then the user must close it manually)
    ///   or set by avformat_open_input().
    /// - muxing: set by the user before avformat_write_header(). The caller must take care of closing / freeing
    ///   the IO context.
    internal var pb: AVIOContextWrapper? {
        get {
            if let ctxPtr = avformatContext.pointee.pb {
                return AVIOContextWrapper(ctxPtr: ctxPtr)
            }
            return nil
        }
        set {
            ioCtx = newValue
            return avformatContext.pointee.pb = newValue?.ctxPtr
        }
    }

    /// Number of streams.
    public var streamCount: UInt32 {
        return avformatContext.pointee.nb_streams
    }

    /// A list of all streams in the file.
    public var streams: [AVStreamWrapper] {
        var list = [AVStreamWrapper]()
        for i in 0..<Int(streamCount) {
            let stream = avformatContext.pointee.streams.advanced(by: i).pointee!
            list.append(AVStreamWrapper(streamPtr: stream))
        }
        return list
    }

    public var videoStream: AVStreamWrapper? {
        return streams.first { $0.mediaType == .video }
    }

    public var audioStream: AVStreamWrapper? {
        return streams.first { $0.mediaType == .audio }
    }

    public var subtitleStream: AVStreamWrapper? {
        return streams.first { $0.mediaType == .subtitle }
    }

    /// Position of the first frame of the component, in AV_TIME_BASE fractional seconds.
    /// Never set this value directly: It is deduced from the AVStream values.
    ///
    /// Demuxing only, set by libavformat.
    public var startTime: Int64 {
        return avformatContext.pointee.start_time
    }

    /// Duration of the stream, in AV_TIME_BASE fractional seconds. Only set this value if you know
    /// none of the individual stream durations and also do not set any of them.
    /// This is deduced from the AVStream values if not set.
    ///
    /// Demuxing only, set by libavformat.
    public var duration: Int64 {
        return avformatContext.pointee.duration
    }

    /// Flags modifying the (de)muxer behaviour. A combination of AVFMT_FLAG_*.
    ///
    /// Set by the user before `openInput` / `writeHeader`.
    public var flags: AVFmtFlag {
        get { return AVFmtFlag(rawValue: avformatContext.pointee.flags) }
        set { avformatContext.pointee.flags = newValue.rawValue }
    }

    /// Metadata that applies to the whole file.
    public var metadata: AVDictionary {
        return AVDictionary.init(metadata: avformatContext.pointee.metadata)
    }

    /// Custom interrupt callbacks for the I/O layer.
    ///
    /// - demuxing: set by the user before avformat_open_input().
    /// - muxing: set by the user before avformat_write_header() (mainly useful for AVFMT_NOFILE formats).
    ///   The callback should also be passed to avio_open2() if it's used to open the file.
    public var interruptCallback: AVIOInterruptCB {
        get { return avformatContext.pointee.interrupt_callback }
        set { avformatContext.pointee.interrupt_callback = newValue }
    }

    public func streamIndex(for mediaType: AVMediaType) -> Int? {
        if let index = streams.firstIndex(where: { $0.codecpar.mediaType == mediaType }) {
            return index
        }
        return nil
    }

    /// Print detailed information about the input or output format, such as duration, bitrate, streams, container,
    /// programs, metadata, side data, codec and time base.
    ///
    /// - Parameters isOutput: Select whether the specified context is an input(0) or output(1).
    public func dumpFormat(isOutput: Bool) {
        av_dump_format(avformatContext, 0, url, isOutput ? 1 : 0)
    }

    deinit {
        if isOpen {
            var ps: UnsafeMutablePointer<AVFormatContext>? = avformatContext
            avformat_close_input(&ps)
        } else {
            avformat_free_context(avformatContext)
        }
    }
}

// MARK: - Demuxing

extension AVFormatContextWrapper {

    /// Open an input stream and read the header. The codecs are not opened.
    ///
    /// - Parameters:
    ///   - url: URL of the stream to open.
    ///   - format: If non-nil, this parameter forces a specific input format. Otherwise the format is autodetected.
    ///   - options: A dictionary filled with `AVFormatContext` and demuxer-private options.
    /// - Throws: AVError
    public convenience init(url: String, format: AVInputFormatWrapper? = nil, options: [String: String]? = nil) throws {
        var pm: OpaquePointer?
        defer { av_dict_free(&pm) }
        if let options = options {
            for (k, v) in options {
                av_dict_set(&pm, k, v, 0)
            }
        }

        var ctxPtr: UnsafeMutablePointer<AVFormatContext>?
        try throwIfFail(avformat_open_input(&ctxPtr, url, format?.fmt, &pm))
        self.init(avformatContext: ctxPtr!)
        self.isOpen = true

        dumpUnrecognizedOptions(pm)
    }

    /// Open an input stream and read the header.
    ///
    /// - Parameter url: URL of the stream to open.
    public func openInput(_ url: String) throws {
        var ps: UnsafeMutablePointer<AVFormatContext>? = avformatContext
        try throwIfFail(avformat_open_input(&ps, url, nil, nil))
        isOpen = true
    }

    /// Read packets of a media file to get stream information.
    public func findStreamInfo() throws {
        try throwIfFail(avformat_find_stream_info(avformatContext, nil))
    }

    /// Find the "best" stream in the file.
    ///
    /// - Parameter type: stream type: video, audio, subtitles, etc.
    /// - Returns: stream number
    /// - Throws: AVError
    public func findBestStream(type: AVMediaType) throws -> Int {
        let ret = av_find_best_stream(avformatContext, type, -1, -1, nil, 0)
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
    public func guessSampleAspectRatio(stream: AVStreamWrapper?, frame: AVFrameWrapper?) -> AVRational {
        return av_guess_sample_aspect_ratio(avformatContext, stream?.streamPtr, frame?.framePtr)
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
    public func readFrame(into packet: AVPacketWrapper) throws {
        try throwIfFail(av_read_frame(avformatContext, packet.packetPtr))
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
        try throwIfFail(av_seek_frame(avformatContext, Int32(streamIndex), timestamp, Int32(flags)))
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
        try throwIfFail(avformat_flush(avformatContext))
    }

    /// Start playing a network-based stream (e.g. RTSP stream) at the current position.
    ///
    /// - Throws: AVError
    public func readPlay() throws {
        try throwIfFail(av_read_play(avformatContext))
    }

    /// Pause a network-based stream (e.g. RTSP stream).
    ///
    /// Use av_read_play() to resume it.
    ///
    /// - Throws: AVError
    public func readPause() throws {
        try throwIfFail(av_read_pause(avformatContext))
    }
}

// MARK: - Muxing

extension AVFormatContextWrapper {

    /// Allocate an `AVFormatContext` for an output format.
    ///
    /// - Parameters:
    ///   - format: format to use for allocating the context, if `nil` formatName and filename are used instead
    ///   - formatName: the name of output format to use for allocating the context, if `nil` filename is used instead
    ///   - filename: the name of the filename to use for allocating the context, may be `nil`
    /// - Throws: AVError
    public convenience init(format: AVOutputFormatWrapper?, formatName: String? = nil, filename: String? = nil) throws {
        var ctxPtr: UnsafeMutablePointer<AVFormatContext>?
        try throwIfFail(avformat_alloc_output_context2(&ctxPtr, format?.fmtPtr, formatName, filename))
        self.init(avformatContext: ctxPtr!)
    }

    /// Create and initialize a AVIOContext for accessing the resource indicated by url.
    ///
    /// - Parameters:
    ///   - url: resource to access
    ///   - flags: flags which control how the resource indicated by url is to be opened
    /// - Throws: AVError
    public func openIO(url: String, flags: AVIOFlag) throws {
        pb = try AVIOContextWrapper(url: url, flags: flags)
    }

    /// Add a new stream to a media file.
    ///
    /// - Parameter codec: If non-nil, the AVCodecContext corresponding to the new stream will be initialized to use
    ///   this codec. This is needed for e.g. codec-specific defaults to be set, so codec should be provided if it is
    ///   known.
    /// - Returns: newly created stream or `nil` on error.
    public func addStream(codec: AVCodecWrapper? = nil) -> AVStreamWrapper? {
        if let streamPtr = avformat_new_stream(avformatContext, codec?.codecPtr) {
            return AVStreamWrapper(streamPtr: streamPtr)
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

        try throwIfFail(avformat_write_header(avformatContext, &pm))

        dumpUnrecognizedOptions(pm)
    }

    /// Write a packet to an output media file.
    ///
    /// - Parameter pkt: The packet containing the data to be written.
    /// - Throws: AVError
    public func writeFrame(pkt: AVPacketWrapper?) throws {
        try throwIfFail(av_write_frame(avformatContext, pkt?.packetPtr))
    }

    /// Write a packet to an output media file ensuring correct interleaving.
    ///
    /// - Parameter pkt: The packet containing the data to be written.
    /// - Throws: AVError
    public func interleavedWriteFrame(pkt: AVPacketWrapper?) throws {
        try throwIfFail(av_interleaved_write_frame(avformatContext, pkt?.packetPtr))
    }

    /// Write the stream trailer to an output media file and free the file private data.
    ///
    /// May only be called after a successful call to `writeHeader(options:)`.
    ///
    /// - Throws: AVError
    public func writeTrailer() throws {
        try throwIfFail(av_write_trailer(avformatContext))
    }
}
