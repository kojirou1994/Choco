//
//  FFmpegFormatContext.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/16.
//

import Foundation
import CFFmpeg
/// Format I/O context.
public final class FFmpegFormatContext: CPointerWrapper {
    var _value: UnsafeMutablePointer<AVFormatContext>
    
    init(_ value: UnsafeMutablePointer<AVFormatContext>) {
        _value = value
        //        isOpen = false
    }
    
    //    private var isOpen: Bool
    //    private var ioContext: FFmpegIOContext?
    
    /// Allocate an `AVFormatContext`.
    private init() {
        _value = avformat_alloc_context()
        //        isOpen = false
    }
    
    /// Input or output URL.
    public var url: String? {
        if let strBytes = _value.pointee.url {
            return String(cString: strBytes)
        }
        return nil
    }
    
    /// The input container format.
    public var inputFormat: FFmpegInputFormat? {
        get {
            if let fmtPtr = _value.pointee.iformat {
                return FFmpegInputFormat(fmtPtr)
            }
            return nil
        }
        set { _value.pointee.iformat = newValue?._value }
    }
    
    /// The output container format.
    public var outputFormat: FFmpegOutputFormat? {
        get {
            if let fmtPtr = _value.pointee.oformat {
                return FFmpegOutputFormat(fmtPtr)
            }
            return nil
        }
        set { _value.pointee.oformat = newValue?._value }
    }
    
    public var pb: FFmpegIOContext? {
        get {
            if let ctxPtr = _value.pointee.pb {
                return FFmpegIOContext(ctxPtr)
            }
            return nil
        }
        //        set {
        ////            ioContext = newValue
        //            return _value.pointee.pb = newValue?._value
        //        }
    }
    
    public func openOutput(filename: String) throws {
        try throwIfFail(avio_open(&_value.pointee.pb, filename, AVIO_FLAG_WRITE))
    }
    
    public func closeOutput() throws {
        try throwIfFail(avio_closep(&_value.pointee.pb))
    }
    
    public func closeInput() {
        var p: UnsafeMutablePointer<AVFormatContext>? = _value
        avformat_close_input(&p)
    }
    
    /// Number of streams.
    public var streamCount: UInt32 {
        return _value.pointee.nb_streams
    }
    
    /// A list of all streams in the file.
    public var streams: [FFmpegStream] {
        var list = [FFmpegStream]()
        for i in 0..<Int(streamCount) {
            let stream = _value.pointee.streams[i]!
            list.append(FFmpegStream(stream))
        }
        return list
    }
    
    public func stream(at index: Int) -> FFmpegStream {
        return .init(_value.pointee.streams[index]!)
    }
    
    //    public var videoStream: FFmpegStream? {
    //        return streams.first { $0.mediaType == .video }
    //    }
    //
    //    public var audioStream: FFmpegStream? {
    //        return streams.first { $0.mediaType == .audio }
    //    }
    //
    //    public var subtitleStream: FFmpegStream? {
    //        return streams.first { $0.mediaType == .subtitle }
    //    }
    
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
    public var metadata: FFmpegDictionary {
        get {
            return FFmpegDictionary(metadata: _value.pointee.metadata)
        }
        set {
            _value.pointee.metadata = newValue.metadata
        }
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
    
    public init(url: String, format: FFmpegInputFormat? = nil, options: [String: String]? = nil) throws {
        var opt: OpaquePointer?
        var p: UnsafeMutablePointer<AVFormatContext>?
        if let options = options, !options.isEmpty {
            opt = FFmpegDictionary.init(dictionary: options).metadata
        }
        try throwIfFail(avformat_open_input(&p, url, format?._value, &opt))
        self._value = p!
        
        dumpUnrecognizedOptions(opt)
    }
    
    deinit {
        print("closing file")
        var p: UnsafeMutablePointer<AVFormatContext>? = _value
        
        //        avformat_close_input(&ps)
        avformat_free_context(_value)
        //        if isOpen {
        //        } else {
        //            avformat_free_context(_value)
        //        }
    }
}

// MARK: - Demuxing

extension FFmpegFormatContext {
    
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
    
    public func flush() throws {
        try throwIfFail(avformat_flush(_value))
    }
    
    public func readPlay() throws {
        try throwIfFail(av_read_play(_value))
    }
    
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
    public static func outputContext(outputFormat: FFmpegOutputFormat?, formatName: String?, filename: String?) throws  -> FFmpegFormatContext {
        var p: UnsafeMutablePointer<AVFormatContext>?
        try throwIfFail(avformat_alloc_output_context2(&p, outputFormat?._value, formatName, filename))
        return .init(p!)
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
    public func writeHeader(options: [String: String] = [ : ]) throws {
        var meta = FFmpegDictionary.init(dictionary: options).metadata
        
        try throwIfFail(avformat_write_header(_value, &meta))
        
        dumpUnrecognizedOptions(meta)
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
