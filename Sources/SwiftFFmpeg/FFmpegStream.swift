//
//  FFmpegStream.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/17.
//

import Foundation
import CFFmpeg

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
    
    public var timebase: FFmpegRational {
        get { return .init(rawValue: _value.pointee.time_base) }
        set { _value.pointee.time_base = newValue.rawValue }
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
    
    public var sampleAspectRatio: FFmpegRational {
        return .init(rawValue: _value.pointee.sample_aspect_ratio)
    }
    
    public var metadata: FFmpegDictionary {
        return .init(metadata: _value.pointee.metadata)
    }
    
    public var averageFramerate: FFmpegRational {
        return .init(rawValue: _value.pointee.avg_frame_rate)
    }
    
    public var realFramerate: FFmpegRational {
        return .init(rawValue: _value.pointee.r_frame_rate)
    }
    
    public var codecParameters: FFmpegCodecParameters {
        return FFmpegCodecParameters(_value.pointee.codecpar)
    }
    
    public var mediaType: FFmpegMediaType {
        return codecParameters.codecType
    }
    
    public func set(codecParameters: FFmpegCodecParameters) throws {
        try throwFFmpegError(avcodec_parameters_copy(_value.pointee.codecpar, codecParameters._value))
    }
    
    public func copyParameters(from codecCtx: FFmpegCodecContext) throws {
        try throwFFmpegError(avcodec_parameters_from_context(_value.pointee.codecpar, codecCtx._value))
    }
}
