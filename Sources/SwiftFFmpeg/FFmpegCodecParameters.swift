//
//  FFmpegCodecParameters.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/14.
//

import Foundation
import CFFmpeg

public final class FFmpegCodecParameters: CPointerWrapper {
    
    internal var _value: UnsafeMutablePointer<AVCodecParameters>
    
    internal init(_ value: UnsafeMutablePointer<AVCodecParameters>) {
        self._value = value
    }
    
    /// General type of the encoded data.
    public var codecType: FFmpegMediaType {
        return .init(rawValue: _value.pointee.codec_type)
    }
    
    /// Specific type of the encoded data (the codec used).
    public var codecId: FFmpegCodecID {
        return .init(rawValue: _value.pointee.codec_id)
    }
    
    /// Additional information about the codec (corresponds to the AVI FOURCC).
    public var codecTag: UInt32 {
        get { return _value.pointee.codec_tag }
        set { _value.pointee.codec_tag = newValue }
    }
    
    public var bitRate: Int64 {
        return _value.pointee.bit_rate
    }
    
    public var bitsPerCodedSample: Int32 {
        return _value.pointee.bits_per_coded_sample
    }
    
    public var bitsPerRawSample: Int32 {
        return _value.pointee.bits_per_raw_sample
    }
    
    public var profile: Int32 {
        return _value.pointee.profile
    }
    
    public var level: Int32 {
        return _value.pointee.level
    }
    
    public var normalDescription: String {
        return """
        codecType: \(codecType)
        codecId: \(codecId)
        codecTag: \(codecTag)
        bitRate: \(bitRate)
        bitsPerCodedSample: \(bitsPerCodedSample)
        bitsPerRawSample: \(bitsPerRawSample)
        profile: \(profile)
        level: \(level)
        
        """
    }
}

extension FFmpegCodecParameters: CustomStringConvertible {
    public var description: String {
        switch codecType {
        case .video:
            return normalDescription + videoDescription
        case .audio:
            return normalDescription + audioDescription
        default:
            return normalDescription
        }
    }
}

// MARK: - Video

extension FFmpegCodecParameters {
    
    public var pixelFormat: FFmpegPixelFormat {
        return .init(value: _value.pointee.format)
    }
    
    public var width: Int32 {
        return _value.pointee.width
    }
    
    public var height: Int32 {
        return _value.pointee.height
    }
    
    public var sampleAspectRatio: AVRational {
        return _value.pointee.sample_aspect_ratio
    }
    
    public var fieldOrder: FFmpegFieldOrder {
        return .init(rawValue: _value.pointee.field_order)
    }
    
    public var colorRange: FFmpegColorRange {
        return .init(rawValue: _value.pointee.color_range)
    }
    
    public var colorPrimaries: FFmpegColorPrimaries {
        return .init(rawValue: _value.pointee.color_primaries)
    }
    
    public var colorTrc: FFmpegColorTransferCharacteristic {
        return .init(rawValue: _value.pointee.color_trc)
    }
    
    public var colorSpace: FFmpegColorSpace {
        return .init(rawValue: _value.pointee.color_space)
    }
    
    public var chromaLocation: FFmpegChromaLocation {
        return .init(rawValue: _value.pointee.chroma_location)
    }
    
    public var videoDelay: Int32 {
        return _value.pointee.video_delay
    }
    
    public var videoDescription: String {
        return """
        pixelFormat: \(pixelFormat)
        width: \(width)
        height: \(height)
        sampleAspectRatio: \(sampleAspectRatio)
        fieldOrder: \(fieldOrder)
        colorRange: \(colorRange)
        colorPrimaries: \(colorPrimaries)
        colorTrc: \(colorTrc)
        colorSpace: \(colorSpace)
        chromaLocation: \(chromaLocation)
        videoDelay: \(videoDelay)
        """
    }
    
}

// MARK: - Audio

extension FFmpegCodecParameters {
    
    public var sampleFormat: FFmpegSampleFormat {
        return .init(rawValue: _value.pointee.format)
    }
    
    public var channelLayout: FFmpegChannelLayout {
        return FFmpegChannelLayout(rawValue: _value.pointee.channel_layout)
    }
    
    public var channelCount: Int32 {
        return _value.pointee.channels
    }
    
    /// The number of audio samples per second.
    public var sampleRate: Int32 {
        return _value.pointee.sample_rate
    }
    
    public var blockAlign: Int32 {
        return _value.pointee.block_align
    }
    
    public var initialPadding: Int32 {
        return _value.pointee.initial_padding
    }
    
    public var trailingPadding: Int32 {
        return _value.pointee.trailing_padding
    }
    
    public var seekPreroll: Int32 {
        return _value.pointee.seek_preroll
    }
    
    public var frameSize: Int32 {
        return _value.pointee.frame_size
    }
    
    public var audioDescription: String {
        return """
        sampleFormat: \(sampleFormat)
        channelLayout: \(channelLayout)
        channelCount: \(channelCount)
        sampleRate: \(sampleRate)
        blockAlign: \(blockAlign)
        initialPadding: \(initialPadding)
        trailingPadding: \(trailingPadding)
        seekPreroll: \(seekPreroll)
        frameSize: \(frameSize)
        """
    }
}
