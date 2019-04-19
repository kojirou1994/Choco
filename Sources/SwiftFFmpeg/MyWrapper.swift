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

public final class FFmpegBuffer: CPointerWrapper {
    
    var _value: UnsafeMutablePointer<AVBufferRef>
    
    init(_ value: UnsafeMutablePointer<AVBufferRef>) {
        _value = value
    }
    
    public init(size: Int32) throws {
        guard let p = av_buffer_alloc(size) else {
            throw FFmpegAllocateError("av_buffer_alloc")
        }
        _value = p
    }
    
    internal var data: UnsafeMutablePointer<UInt8>? {
        return _value.pointee.data
    }
    
    internal var size: Int32 {
        return _value.pointee.size
    }
    
    internal var refCount: Int32 {
        return av_buffer_get_ref_count(_value)
    }
    
    internal func realloc(size: Int32) throws {
//        precondition(_value != nil, "buffer has been freed")
        var buf = Optional.some(_value)
        try throwFFmpegError(av_buffer_realloc(&buf, size))
        _value = buf!
    }
    
    internal func isWritable() -> Bool {
//        precondition(_value != nil, "buffer has been freed")
        return av_buffer_is_writable(_value) > 0
    }
    
    internal func makeWritable() throws {
//        precondition(_value != nil, "buffer has been freed")
        var buf = Optional.some(_value)
        try throwFFmpegError(av_buffer_make_writable(&buf))
        _value = buf!
    }
    
    internal func ref() -> FFmpegBuffer? {
//        precondition(_value != nil, "buffer has been freed")
        guard let p = av_buffer_ref(_value) else {
            return nil
        }
        return .init(p)
    }
    
    internal func unref() {
        var buf = Optional.some(_value)
        av_buffer_unref(&buf)
    }
    
}

public final class FFmpegIOContext: CPointerWrapper {
    
    var _value: UnsafeMutablePointer<AVIOContext>
    
    private var needClose = true
    
    internal init(_ value: UnsafeMutablePointer<AVIOContext>) {
        self._value = value
        self.needClose = false
    }

    public init(url: String, flags: AVIOFlag) throws {
        var pb: UnsafeMutablePointer<AVIOContext>?
        try throwFFmpegError(avio_open(&pb, url, flags.rawValue))
        _value = pb!
    }
    
    deinit {
        if needClose {
            var pb: UnsafeMutablePointer<AVIOContext>? = _value
            avio_closep(&pb)
        }
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
