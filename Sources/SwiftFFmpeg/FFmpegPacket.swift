//
//  FFmpegPacket.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/18.
//

import Foundation
import CFFmpeg

public final class FFmpegPacket: CPointerWrapper {
    
    internal let _value: UnsafeMutablePointer<AVPacket>
    
    internal init(_ value: UnsafeMutablePointer<AVPacket>) {
        _value = value
    }
    
    public init() throws {
        guard let p = av_packet_alloc() else {
            throw FFmpegAllocateError("av_packet_alloc")
        }
        _value = p
    }
    
    internal var buffer: FFmpegBuffer? {
        get {
            if let bufPtr = _value.pointee.buf {
                return FFmpegBuffer(bufPtr)
            }
            return nil
        }
        set { _value.pointee.buf = newValue?._value }
    }
    
    public var pts: Int64 {
        get { return _value.pointee.pts }
        set { _value.pointee.pts = newValue }
    }
    
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
    
    public func ref(dst: FFmpegPacket) throws {
        try throwFFmpegError(av_packet_ref(dst._value, _value))
    }
    
    public func unref() {
        av_packet_unref(_value)
    }
    
    public func moveRef(from packet: FFmpegPacket) {
        av_packet_move_ref(_value, packet._value)
    }
    
    public func clone() throws -> FFmpegPacket {
        guard let p = av_packet_clone(_value) else {
            throw FFmpegAllocateError("av_packet_clone")
        }
        return FFmpegPacket(p)
    }
    
    public func makeWritable() throws {
        try throwFFmpegError(av_packet_make_writable(_value))
    }
    
    public func rescaleTimestamp(from src: FFmpegRational, to dst: FFmpegRational) {
        av_packet_rescale_ts(_value, src.rawValue, dst.rawValue)
    }
    
    deinit {
        var ptr: UnsafeMutablePointer<AVPacket>? = _value
        av_packet_free(&ptr)
    }
}
