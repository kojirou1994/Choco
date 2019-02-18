//
//  Codec.swift
//  SwiftFFmpeg
//
//  Created by sunlubo on 2018/6/28.
//

import CFFmpeg

extension AVCodecID {
    public var name: String {
        return String(cString: avcodec_get_name(self))
    }
    
    /// The codec's media type.
    public var mediaType: AVMediaType {
        return avcodec_get_type(self)
    }
}

// MARK: - AVCodecCap

/// codec capabilities
public struct AVCodecCap: OptionSet {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    /// Audio encoder supports receiving a different number of samples in each call.
    public static let variableFrameSize = AVCodecCap(rawValue: AV_CODEC_CAP_VARIABLE_FRAME_SIZE)
}

// MARK: - AVCodec

public struct AVCodecWrapper {
    internal let codecPtr: UnsafeMutablePointer<AVCodec>

    public init?(decoderId: AVCodecID) {
        guard let codecPtr = avcodec_find_decoder(decoderId) else {
            return nil
        }
        self.init(codecPtr: codecPtr)
    }
    public init?(decoderName: String) {
        guard let codecPtr = avcodec_find_decoder_by_name(decoderName) else {
            return nil
        }
        self.init(codecPtr: codecPtr)
    }
    public init?(encoderId: AVCodecID) {
        guard let codecPtr = avcodec_find_encoder(encoderId) else {
            return nil
        }
        self.init(codecPtr: codecPtr)
    }
    public init?(encoderName: String) {
        guard let codecPtr = avcodec_find_encoder_by_name(encoderName) else {
            return nil
        }
        self.init(codecPtr: codecPtr)
    }

    internal init(codecPtr: UnsafeMutablePointer<AVCodec>) {
        self.codecPtr = codecPtr
    }

    /// The codec's name.
    public var name: String {
        return String(cString: codecPtr.pointee.name)
    }

    /// The codec's descriptive name, meant to be more human readable than name.
    public var longName: String {
        return String(cString: codecPtr.pointee.long_name)
    }

    /// The codec's media type.
    public var mediaType: AVMediaType {
        return codecPtr.pointee.type
    }

    /// The codec's id.
    public var id: AVCodecID {
        return codecPtr.pointee.id
    }

    /// Codec capabilities.
    public var capabilities: AVCodecCap {
        return AVCodecCap(rawValue: codecPtr.pointee.capabilities)
    }

    /// Returns an array of the framerates supported by the codec.
    public var supportedFramerates: [AVRational] {
        var list = [AVRational]()
        var ptr = codecPtr.pointee.supported_framerates
        let zero = AVRational(num: 0, den: 0)
        while let p = ptr, p.pointee != zero {
            list.append(p.pointee)
            ptr = p.advanced(by: 1)
        }
        return list
    }

    /// Returns an array of the pixel formats supported by the codec.
    public var pixFmts: [AVPixelFormat] {
        var list = [AVPixelFormat]()
        var ptr = codecPtr.pointee.pix_fmts
        while let p = ptr, p.pointee != AV_PIX_FMT_NONE {
            list.append(p.pointee)
            ptr = p.advanced(by: 1)
        }
        return list
    }

    /// Returns an array of the audio samplerates supported by the codec.
    public var supportedSampleRates: [Int] {
        var list = [Int]()
        var ptr = codecPtr.pointee.supported_samplerates
        while let p = ptr, p.pointee != 0 {
            list.append(Int(p.pointee))
            ptr = p.advanced(by: 1)
        }
        return list
    }

    /// Returns an array of the sample formats supported by the codec.
    public var sampleFmts: [AVSampleFormat] {
        var list = [AVSampleFormat]()
        var ptr = codecPtr.pointee.sample_fmts
        while let p = ptr, p.pointee != AV_SAMPLE_FMT_NONE {
            list.append(p.pointee)
            ptr = p.advanced(by: 1)
        }
        return list
    }

    /// Returns an array of the channel layouts supported by the codec.
    public var channelLayouts: [AVChannelLayout] {
        var list = [AVChannelLayout]()
        var ptr = codecPtr.pointee.channel_layouts
        while let p = ptr, p.pointee != 0 {
            list.append(AVChannelLayout(rawValue: p.pointee))
            ptr = p.advanced(by: 1)
        }
        return list
    }

    /// Maximum value for lowres supported by the decoder.
    public var maxLowres: UInt8 {
        return codecPtr.pointee.max_lowres
    }

    /// Returns a Boolean value indicating whether the codec is decoder.
    public var isDecoder: Bool {
        return av_codec_is_decoder(codecPtr) != 0
    }

    /// Returns a Boolean value indicating whether the codec is encoder.
    public var isEncoder: Bool {
        return av_codec_is_encoder(codecPtr) != 0
    }
}
