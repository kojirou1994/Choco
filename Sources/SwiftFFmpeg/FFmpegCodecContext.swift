//
//  FFmpegCodecContext.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/18.
//

import Foundation
import CFFmpeg

public final class FFmpegCodecContext: CPointerWrapper {
    
    internal let _value: UnsafeMutablePointer<AVCodecContext>
    
    internal init(_ value: UnsafeMutablePointer<AVCodecContext>) {
        _value = value
        freeWhenDone = false
    }
    
    private let freeWhenDone: Bool
    
    public init(codec: FFmpegCodec) throws {
        guard let p = avcodec_alloc_context3(codec._value) else {
            throw FFmpegAllocateError("avcodec_alloc_context3")
        }
        self._value = p
        freeWhenDone = true
    }
    
    public var mediaType: FFmpegMediaType {
        return .init(rawValue: _value.pointee.codec_type)
    }
    
    public var codec: FFmpegCodec {
        get {
            return .init(.init(mutating: _value.pointee.codec))
        }
    }
    
    public var codecId: FFmpegCodecID {
        get { return .init(rawValue: _value.pointee.codec_id) }
        set { _value.pointee.codec_id = newValue.rawValue }
    }

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
    
    public var timebase: FFmpegRational {
        get { return .init(rawValue: _value.pointee.time_base) }
        set { _value.pointee.time_base = newValue.rawValue }
    }
    
    public var frameNumber: Int32 {
        return _value.pointee.frame_number
    }
    
    /// Returns a Boolean value indicating whether the codec is open.
    public var isOpen: Bool {
        return avcodec_is_open(_value) > 0
    }
    
    public func set(parameter: FFmpegCodecParameters) throws {
        try throwFFmpegError(avcodec_parameters_to_context(_value, parameter._value))
    }
    
    public func openCodec(options: [String: String] = [:]) throws {
        var metadata = FFmpegDictionary.init(dictionary: options).metadata
        try throwFFmpegError(avcodec_open2(_value, nil, &metadata))
        
        readUnrecognizedOptions(metadata)
    }
    
    public func send(packet: FFmpegPacket) throws {
        try throwFFmpegError(avcodec_send_packet(_value, packet._value))
    }
    
    public func receive(frame: FFmpegFrame) throws {
        try throwFFmpegError(avcodec_receive_frame(_value, frame._value))
    }
    
    public func send(frame: FFmpegFrame?) throws {
        try throwFFmpegError(avcodec_send_frame(_value, frame?._value))
    }
    
    public func receive(packet: FFmpegPacket) throws {
        try throwFFmpegError(avcodec_receive_packet(_value, packet._value))
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
    
    public func setOption(key: String, value: String) {
        try! throwFFmpegError(av_opt_set(_value.pointee.priv_data, key, value, 0))
    }
}

// MARK: - Video

extension FFmpegCodecContext {

    public var width: Int32 {
        get { return _value.pointee.width }
        set { _value.pointee.width = newValue }
    }
    
    public var height: Int32 {
        get { return _value.pointee.height }
        set { _value.pointee.height = newValue }
    }

    public var codedWidth: Int32 {
        get { return _value.pointee.coded_width }
        set { _value.pointee.coded_width = newValue }
    }

    public var codedHeight: Int {
        get { return Int(_value.pointee.coded_height) }
        set { _value.pointee.coded_height = Int32(newValue) }
    }

    public var gopSize: Int32 {
        get { return _value.pointee.gop_size }
        set { _value.pointee.gop_size = newValue }
    }

    public var pixelFormat: FFmpegPixelFormat {
        get { return .init(rawValue: _value.pointee.pix_fmt) }
        set { _value.pointee.pix_fmt = newValue.rawValue }
    }

    public var maxBFrames: Int32 {
        get { return _value.pointee.max_b_frames }
        set { _value.pointee.max_b_frames = newValue }
    }
    
    public var mbDecision: Int32 {
        get { return _value.pointee.mb_decision }
        set { _value.pointee.mb_decision = newValue }
    }
    
    public var sampleAspectRatio: FFmpegRational {
        get { return .init(rawValue: _value.pointee.sample_aspect_ratio) }
        set { _value.pointee.sample_aspect_ratio = newValue.rawValue }
    }

    public var lowres: Int32 {
        return _value.pointee.lowres
    }

    public var framerate: FFmpegRational {
        get { return .init(rawValue: _value.pointee.framerate) }
        set { _value.pointee.framerate = newValue.rawValue }
    }
    
}

// MARK: - Audio

extension FFmpegCodecContext {
    
    public var sampleRate: Int32 {
        get { return _value.pointee.sample_rate }
        set { _value.pointee.sample_rate = newValue }
    }
    
    public var channelCount: Int32 {
        get { return _value.pointee.channels }
        set { _value.pointee.channels = newValue }
    }
    
    public var sampleFormat: FFmpegSampleFormat {
        get { return .init(rawValue: _value.pointee.sample_fmt)  }
        set { _value.pointee.sample_fmt = newValue.rawValue }
    }
    
    public var frameSize: Int32 {
        return _value.pointee.frame_size
    }

    public var channelLayout: FFmpegChannelLayout {
        get { return FFmpegChannelLayout(rawValue: _value.pointee.channel_layout) }
        set { _value.pointee.channel_layout = newValue.rawValue }
    }
    
}
