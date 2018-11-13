//
//  AVBuffer.swift
//  SwiftFFmpeg
//
//  Created by sunlubo on 2018/7/24.
//

import CFFmpeg

protocol FFmpegWrapper {
    associatedtype CType
    
    var _value: UnsafeMutablePointer<CType>? { get set }
    
}

/// A reference to a data buffer.
public final class AVBufferWrapper {
    
    internal var _avBuffer: UnsafeMutablePointer<AVBufferRef>?

    internal init(bufPtr: UnsafeMutablePointer<AVBufferRef>?) {
        self._avBuffer = bufPtr
    }

    /// Allocate an `AVBuffer` of the given size.
    public init?(size: Int32) {
        guard let bufPtr = av_buffer_alloc(Int32(size)) else {
            return nil
        }
        self._avBuffer = bufPtr
    }

    public var data: UnsafeMutablePointer<UInt8>? {
        return _avBuffer?.pointee.data
    }

    /// Size of data in bytes.
    public var size: Int32 {
        return _avBuffer?.pointee.size ?? 0
    }

    public var refCount: Int32 {
        if _avBuffer == nil {
            return 0
        }
        return av_buffer_get_ref_count(_avBuffer)
    }

    public func realloc(size: Int) throws {
        precondition(_avBuffer != nil, "buffer has been freed")
        try throwIfFail(av_buffer_realloc(&_avBuffer, Int32(size)))
    }

    public func isWritable() -> Bool {
        precondition(_avBuffer != nil, "buffer has been freed")
        return av_buffer_is_writable(_avBuffer) > 0
    }

    public func makeWritable() throws {
        precondition(_avBuffer != nil, "buffer has been freed")
        try throwIfFail(av_buffer_make_writable(&_avBuffer))
    }

    public func ref() -> AVBufferWrapper? {
        precondition(_avBuffer != nil, "buffer has been freed")
        return AVBufferWrapper(bufPtr: av_buffer_ref(_avBuffer))
    }

    public func unref() {
        av_buffer_unref(&_avBuffer)
    }

}
