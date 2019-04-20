//
//  FFmpegFrame.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/17.
//

import Foundation
import CFFmpeg

public final class FFmpegFrame: CPointerWrapper {
    
    internal init(_ value: UnsafeMutablePointer<AVFrame>) {
        _value = value
    }
    
    //    public var mediaType: AVMediaType = .unknown
    
    internal let _value: UnsafeMutablePointer<AVFrame>

    public init() throws {
        guard let p = av_frame_alloc() else {
            throw FFmpegAllocateError("av_frame_alloc")
        }
        _value = p
    }
    
    public var extendedData: UnsafeMutableBufferPointer<UnsafeMutablePointer<UInt8>?> {
        get {
            let count = pixelFormat != .none ? 4 : channelCount
            return UnsafeMutableBufferPointer(start: _value.pointee.extended_data, count: Int(count))
        }
    }
    
    public var data: (UnsafeMutablePointer<UInt8>?, UnsafeMutablePointer<UInt8>?, UnsafeMutablePointer<UInt8>?, UnsafeMutablePointer<UInt8>?, UnsafeMutablePointer<UInt8>?, UnsafeMutablePointer<UInt8>?, UnsafeMutablePointer<UInt8>?, UnsafeMutablePointer<UInt8>?) {
        return _value.pointee.data
    }

    public var linesize: (Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32) {
        return _value.pointee.linesize
    }
    
    public var pts: Int64 {
        get { return _value.pointee.pts }
        set { _value.pointee.pts = newValue }
    }

    public var pkt_dts: Int64 {
        return _value.pointee.pkt_dts
    }
    
    public var codedPictureNumber: Int32 {
        return _value.pointee.coded_picture_number
    }
    
    public var displayPictureNumber: Int32 {
        return _value.pointee.display_picture_number
    }
    
    internal var buf: [FFmpegBuffer?] {
        let list = [
            _value.pointee.buf.0, _value.pointee.buf.1, _value.pointee.buf.2, _value.pointee.buf.3,
            _value.pointee.buf.4, _value.pointee.buf.5, _value.pointee.buf.6, _value.pointee.buf.7
        ]
        return list.map({ $0 != nil ? FFmpegBuffer($0!) : nil })
    }
    
    internal var extendedBuf: [FFmpegBuffer] {
        var list = [FFmpegBuffer]()
        let count = Int(extendedBufCount)
        list.reserveCapacity(count)
        for i in 0..<count {
            list.append(FFmpegBuffer(_value.pointee.extended_buf[i]!))
        }
        return list
    }
    
    public var extendedBufCount: Int32 {
        return _value.pointee.nb_extended_buf
    }
    
    public var pktPos: Int64 {
        return _value.pointee.pkt_pos
    }
    
    public var pktDuration: Int64 {
        return _value.pointee.pkt_duration
    }
    
    public var pktSize: Int32 {
        return _value.pointee.pkt_size
    }
    
    public var metadata: FFmpegDictionary {
        get {
            return .init(metadata: _value.pointee.metadata)
        }
    }
    
    public func ref(dst: FFmpegFrame) throws {
        try throwFFmpegError(av_frame_ref(dst._value, _value))
    }
    
    public func unref() {
        av_frame_unref(_value)
    }
    
    public func clone() throws -> FFmpegFrame {
        guard let p = av_frame_clone(_value) else {
            throw FFmpegAllocateError("av_frame_clone")
        }
        return FFmpegFrame(p)
    }

    public func getBuffer(align: Int32 = 0) throws {
        try throwFFmpegError(av_frame_get_buffer(_value, align))
    }

    public func isWritable() -> Bool {
        return av_frame_is_writable(_value) > 0
    }

    public func makeWritable() throws {
        try throwFFmpegError(av_frame_make_writable(_value))
    }
    
    deinit {
        var ptr: UnsafeMutablePointer<AVFrame>? = _value
        av_frame_free(&ptr)
    }
}

// MARK: - Video

extension FFmpegFrame {
    
    /// Pixel format.
    public var pixelFormat: FFmpegPixelFormat {
        get { return .init(value: _value.pointee.format) }
        set { _value.pointee.format = newValue.rawValue.rawValue }
    }
    
    /// Picture width.
    public var width: Int32 {
        get { return _value.pointee.width }
        set { _value.pointee.width = newValue }
    }
    
    /// Picture height.
    public var height: Int32 {
        get { return _value.pointee.height }
        set { _value.pointee.height = newValue }
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
    public var sampleAspectRatio: FFmpegRational {
        get { return .init(rawValue: _value.pointee.sample_aspect_ratio) }
        //        set { _value.pointee.sample_aspect_ratio = newValue }
    }
}

// MARK: - Audio

extension FFmpegFrame {
    
    /// Sample format.
    public var sampleFmt: FFmpegSampleFormat {
        get { return .init(rawValue: _value.pointee.format) }
        set { _value.pointee.format = newValue.rawValue.rawValue }
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
