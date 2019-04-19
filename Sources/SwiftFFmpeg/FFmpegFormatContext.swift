//
//  FFmpegFormatContext.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/16.
//

import Foundation
import CFFmpeg

public class FFmpegFormatContext: CPointerWrapper {
    var _value: UnsafeMutablePointer<AVFormatContext>
    
    required init(_ value: UnsafeMutablePointer<AVFormatContext>) {
        _value = value
    }
    
    public var url: String? {
        if let strBytes = _value.pointee.url {
            return String(cString: strBytes)
        }
        return nil
    }
    
    public var streamCount: UInt32 {
        return _value.pointee.nb_streams
    }
    
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
    
    public var startTime: Int64 {
        return _value.pointee.start_time
    }

    public var duration: Int64 {
        return _value.pointee.duration
    }

    public var flags: AVFmtFlag {
        get { return AVFmtFlag(rawValue: _value.pointee.flags) }
        set { _value.pointee.flags = newValue.rawValue }
    }
    
    public var metadata: FFmpegDictionary {
        get {
            return FFmpegDictionary(metadata: _value.pointee.metadata)
        }
        set {
            _value.pointee.metadata = newValue.metadata
        }
    }

    public var interruptCallback: AVIOInterruptCB {
        get { return _value.pointee.interrupt_callback }
        set { _value.pointee.interrupt_callback = newValue }
    }
    
}

public final class FFmpegInputFormatContext: FFmpegFormatContext {
    
    public init(url: String, format: FFmpegInputFormat? = nil, options: [String: String]? = nil) throws {
        var opt: OpaquePointer?
        var p: UnsafeMutablePointer<AVFormatContext>?
        if let options = options {
            opt = FFmpegDictionary.init(dictionary: options).metadata
        }
        try throwFFmpegError(avformat_open_input(&p, url, format?._value, &opt))
        super.init(p!)
        
        readUnrecognizedOptions(opt)
    }
    
    required init(_ value: UnsafeMutablePointer<AVFormatContext>) {
        super.init(value)
    }
    
    deinit {
        var p: UnsafeMutablePointer<AVFormatContext>? = _value
        avformat_close_input(&p)
    }
    
    public var inputFormat: FFmpegInputFormat? {
        get {
            if let fmtPtr = _value.pointee.iformat {
                return FFmpegInputFormat(fmtPtr)
            }
            return nil
        }
        set { _value.pointee.iformat = newValue?._value }
    }
    
    public func closeInput() {
        var p: UnsafeMutablePointer<AVFormatContext>? = _value
        avformat_close_input(&p)
    }
    
    public func dumpFormat() {
        av_dump_format(_value, 0, url, 0)
    }
    
    public func findStreamInfo() throws {
        try throwFFmpegError(avformat_find_stream_info(_value, nil))
    }
    
    public func findBestStream(type: FFmpegMediaType) throws -> Int {
        let ret = av_find_best_stream(_value, type.rawValue, -1, -1, nil, 0)
        try throwFFmpegError(ret)
        return Int(ret)
    }
    
    public func guessSampleAspectRatio(stream: FFmpegStream?, frame: FFmpegFrame?) -> FFmpegRational {
        return .init(rawValue: av_guess_sample_aspect_ratio(_value, stream?._value, frame?._value))
    }
    
    public func readFrame(into packet: FFmpegPacket) throws {
        try throwFFmpegError(av_read_frame(_value, packet._value))
    }
    
    public func readFrame(cb: (Result<FFmpegPacket, FFmpegError>, inout Bool) throws -> Void) rethrows {
        var packet = try! FFmpegPacket.init()
        var stop = false
        while true {
            let result: Result<FFmpegPacket, FFmpegError>
            
            do {
                try readFrame(into: packet)
                result = .success(packet)
            } catch let error as FFmpegError {
                result = .failure(error)
            } catch {
                fatalError("should be ffmpegerror: \(error)")
            }
            
            try cb(result, &stop)
            if stop {
                break
            }
        }
        if !isKnownUniquelyReferenced(&packet) {
            print("packet is not KnownUniquelyReferenced")
        }
    }
    
    public func seekFrame(streamIndex: Int, timestamp: Int64, flags: Int) throws {
        try throwFFmpegError(av_seek_frame(_value, Int32(streamIndex), timestamp, Int32(flags)))
    }
    
    public func flush() throws {
        try throwFFmpegError(avformat_flush(_value))
    }
    
    public func readPlay() throws {
        try throwFFmpegError(av_read_play(_value))
    }
    
    public func readPause() throws {
        try throwFFmpegError(av_read_pause(_value))
    }
    
}

public final class FFmpegOutputFormatContext: FFmpegFormatContext {
    
    public var outputFormat: FFmpegOutputFormat {
        get {
            if let fmtPtr = _value.pointee.oformat {
                return FFmpegOutputFormat(fmtPtr)
            }
//            return nil
            fatalError()
        }
//        set { _value.pointee.oformat = newValue?._value }
    }
    
    public func openOutput(filename: String) throws {
        try throwFFmpegError(avio_open(&_value.pointee.pb, filename, AVIO_FLAG_WRITE))
    }
    
    public func closeOutput() throws {
        try throwFFmpegError(avio_closep(&_value.pointee.pb))
    }
    
    public func dumpFormat() {
        av_dump_format(_value, 0, url, 1)
    }
    
    public init(outputFormat: FFmpegOutputFormat?, formatName: String?, filename: String?) throws {
        var p: UnsafeMutablePointer<AVFormatContext>?
        try throwFFmpegError(avformat_alloc_output_context2(&p, outputFormat?._value, formatName, filename))
        super.init(p!)
    }
    
    required init(_ value: UnsafeMutablePointer<AVFormatContext>) {
        super.init(value)
    }
    
    deinit {
        avformat_free_context(_value)
    }
    
    public func addStream(codec: FFmpegCodec?) throws -> FFmpegStream {
        guard let streamPtr = avformat_new_stream(_value, codec?._value) else {
            throw FFmpegAllocateError("avformat_new_stream")
        }
        return FFmpegStream(streamPtr)
    }

    public func writeHeader(options: [String: String] = [ : ]) throws {
        var meta = FFmpegDictionary.init(dictionary: options).metadata
        
        try throwFFmpegError(avformat_write_header(_value, &meta))
        
        readUnrecognizedOptions(meta)
    }
    
    public func writeFrame(pkt: FFmpegPacket?) throws {
        try throwFFmpegError(av_write_frame(_value, pkt?._value))
    }
    
    public func interleavedWriteFrame(pkt: FFmpegPacket?) throws {
        try throwFFmpegError(av_interleaved_write_frame(_value, pkt?._value))
    }
    
    public func writeTrailer() throws {
        try throwFFmpegError(av_write_trailer(_value))
    }
    
}

    
    /// Allocate an `AVFormatContext`.
//    private init() {
//        _value = avformat_alloc_context()
//        //        isOpen = false
//    }
    
    /// Input or output URL.

    
    /// The input container format.

    
    /// The output container format.

    
//    public var pb: FFmpegIOContext? {
//        get {
//            if let ctxPtr = _value.pointee.pb {
//                return FFmpegIOContext(ctxPtr)
//            }
//            return nil
//        }
//        //        set {
//        ////            ioContext = newValue
//        //            return _value.pointee.pb = newValue?._value
//        //        }
//    }


    

    
    /// Number of streams.

    
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

    
    /// Metadata that applies to the whole file.

    
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

    

    

//}
