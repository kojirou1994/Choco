//
//  FFmpegCodec.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/18.
//

import Foundation
import CFFmpeg

public final class FFmpegCodec: CPointerWrapper {
    
    internal let _value: UnsafeMutablePointer<AVCodec>
    
    internal init(_ value: UnsafeMutablePointer<AVCodec>) {
        _value = value
    }

    public init(decoderId: FFmpegCodecID) throws {
        guard let p = avcodec_find_decoder(decoderId.rawValue) else {
            throw FFmpegAllocateError.init("avcodec_find_decoder")
        }
        _value = p
    }
    
    public init(decoderName: String) throws {
        guard let p = avcodec_find_decoder_by_name(decoderName) else {
            throw FFmpegAllocateError.init("avcodec_find_decoder_by_name")
        }
        _value = p
    }
    
    public init(encoderId: FFmpegCodecID) throws {
        guard let p = avcodec_find_encoder(encoderId.rawValue) else {
            throw FFmpegAllocateError.init("avcodec_find_encoder")
        }
        _value = p
    }
    
    public init(encoderName: String) throws {
        guard let p = avcodec_find_encoder_by_name(encoderName) else {
            throw FFmpegAllocateError.init("avcodec_find_encoder_by_name")
        }
        _value = p
    }
    
    public var name: String {
        return String(cString: _value.pointee.name)
    }
    
    public var longName: String {
        return String(cString: _value.pointee.long_name)
    }
    
    public var mediaType: FFmpegMediaType {
        return .init(rawValue: _value.pointee.type)
    }
    
    public var id: FFmpegCodecID {
        return .init(rawValue: _value.pointee.id)
    }
    
    public var capabilities: FFmpegCodecCapability {
        return .init(rawValue: _value.pointee.capabilities)
    }
    
    public var supportedFramerates: [FFmpegRational] {
        return readArray(pointer: _value.pointee.supported_framerates, stop: { ($0.den, $0.num) == (0, 0) },
                         transform: { .init(rawValue: $0) })
    }
    
    public var pixelFormats: [FFmpegPixelFormat] {
        return readArray(pointer: _value.pointee.pix_fmts, stop: { $0.rawValue == -1 },
                         transform: { FFmpegPixelFormat.init(rawValue: $0) })
    }
    
    public var supportedSampleRates: [Int32] {
        return readArray(pointer: _value.pointee.supported_samplerates, stop: { $0 == 0 }, transform: {$0})
    }
    
    public var sampleFormats: [FFmpegSampleFormat] {
        return readArray(pointer: _value.pointee.sample_fmts, stop: { $0.rawValue == -1 }, transform: {FFmpegSampleFormat.init(rawValue: $0)})
    }
    
    public var channelLayouts: [FFmpegChannelLayout] {
        return readArray(pointer: _value.pointee.channel_layouts, stop: { $0 == 0 },
                         transform: { FFmpegChannelLayout(rawValue: $0) })
    }
    
    public var maxLowres: UInt8 {
        return _value.pointee.max_lowres
    }
    
    public var isDecoder: Bool {
        return av_codec_is_decoder(_value) != 0
    }
    
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

public struct FFmpegCodecCapability: OptionSet {
    
    public let rawValue: Int32
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
}

public extension FFmpegCodecCapability {
    static var draw_horiz_band: FFmpegCodecCapability { return .init(rawValue: AV_CODEC_CAP_DRAW_HORIZ_BAND) }
    static var dr1: FFmpegCodecCapability { return .init(rawValue: AV_CODEC_CAP_DR1) }
    static var truncated: FFmpegCodecCapability { return .init(rawValue: AV_CODEC_CAP_TRUNCATED) }
    static var delay: FFmpegCodecCapability { return .init(rawValue: AV_CODEC_CAP_DELAY) }
    static var small_last_frame: FFmpegCodecCapability { return .init(rawValue: AV_CODEC_CAP_SMALL_LAST_FRAME) }
    static var subframes: FFmpegCodecCapability { return .init(rawValue: AV_CODEC_CAP_SUBFRAMES) }
    static var experimental: FFmpegCodecCapability { return .init(rawValue: AV_CODEC_CAP_EXPERIMENTAL) }
    static var channel_conf: FFmpegCodecCapability { return .init(rawValue: AV_CODEC_CAP_CHANNEL_CONF) }
    static var frame_threads: FFmpegCodecCapability { return .init(rawValue: AV_CODEC_CAP_FRAME_THREADS) }
    static var slice_threads: FFmpegCodecCapability { return .init(rawValue: AV_CODEC_CAP_SLICE_THREADS) }
    static var param_change: FFmpegCodecCapability { return .init(rawValue: AV_CODEC_CAP_PARAM_CHANGE) }
    static var auto_threads: FFmpegCodecCapability { return .init(rawValue: AV_CODEC_CAP_AUTO_THREADS) }
    static var variable_frame_size: FFmpegCodecCapability { return .init(rawValue: AV_CODEC_CAP_VARIABLE_FRAME_SIZE) }
    static var avoid_probing: FFmpegCodecCapability { return .init(rawValue: AV_CODEC_CAP_AVOID_PROBING) }
    static var intra_only: FFmpegCodecCapability { return .init(rawValue: AV_CODEC_CAP_INTRA_ONLY) }
    static var lossless: FFmpegCodecCapability { return .init(rawValue: .init(bitPattern: AV_CODEC_CAP_LOSSLESS)) }
    static var hardware: FFmpegCodecCapability { return .init(rawValue: AV_CODEC_CAP_HARDWARE) }
    static var hybrid: FFmpegCodecCapability { return .init(rawValue: AV_CODEC_CAP_HYBRID) }
}

extension FFmpegCodecCapability: CustomStringConvertible {
    public var description: String {
        var str = "["
        if contains(.draw_horiz_band) { str += "draw_horiz_band, " }
        if contains(.dr1) { str += "dr1, " }
        if contains(.truncated) { str += "truncated, " }
        if contains(.delay) { str += "delay, " }
        if contains(.small_last_frame) { str += "small_last_frame, " }
        if contains(.subframes) { str += "subframes, " }
        if contains(.experimental) { str += "experimental, " }
        if contains(.channel_conf) { str += "channel_conf, " }
        if contains(.frame_threads) { str += "frame_threads, " }
        if contains(.slice_threads) { str += "slice_threads, " }
        if contains(.param_change) { str += "param_change, " }
        if contains(.auto_threads) { str += "auto_threads, " }
        if contains(.variable_frame_size) { str += "variable_frame_size, " }
        if contains(.avoid_probing) { str += "avoid_probing, " }
        if contains(.intra_only) { str += "intra_only, " }
        if contains(.lossless) { str += "lossless, " }
        if contains(.hardware) { str += "hardware, " }
        if contains(.hybrid) { str += "hybrid, " }
        //        if contains(.encoderReorderedOpaque) { str += "encoderReorderedOpaque, " }
        if str.suffix(2) == ", " {
            str.removeLast(2)
        }
        str += "]"
        return str
    }
}
