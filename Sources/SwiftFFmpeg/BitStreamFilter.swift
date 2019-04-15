//
//  BitStreamFilter.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/15.
//

import Foundation
import CFFmpeg

public final class FFmpegBitStreamFilter: CustomStringConvertible {
    var _value: UnsafePointer<AVBitStreamFilter>
    
    init(_ value: UnsafePointer<AVBitStreamFilter>) {
        _value = value
    }
    
    public init?(name: String) {
        guard let p = av_bsf_get_by_name(name) else {
            return nil
        }
        _value = p
    }
    
    public var name: String {
        return .init(cString: _value.pointee.name)
    }
    
    public var codecIds: [FFmpegCodecID] {
        guard let p = _value.pointee.codec_ids else {
            return []
        }
        var result = [FFmpegCodecID]()
        for i in 0..<Int.max {
            let element = FFmpegCodecID(rawValue: p[i])
            if element == .none {
                return result
            } else {
                result.append(element)
            }
        }
        return result
    }
    
    public var description: String {
        return """
        name: \(name)
        codecIds: \(codecIds.map{$0.description}.joined(separator: ", "))
        """
    }
    
    public static var registeredBitstreamFilters: [FFmpegBitStreamFilter] {
        var result = [FFmpegBitStreamFilter]()
        var state: UnsafeMutableRawPointer?
        while let p = av_bsf_iterate(&state) {
            result.append(.init(p))
        }
        return result
    }
}

public final class FFmpegBitStreamFilterContext: CPointerWrapper, CustomStringConvertible {
    var _value: UnsafeMutablePointer<AVBSFContext>
    
    init(_ value: UnsafeMutablePointer<AVBSFContext>) {
        _value = value
    }
    
    public static func nullFilter() throws -> FFmpegBitStreamFilterContext {
        var p: UnsafeMutablePointer<AVBSFContext>?
        try throwIfFail(av_bsf_get_null_filter(&p))
        return .init(p!)
    }
    
    public init(filter: FFmpegBitStreamFilter) throws {
        var p: UnsafeMutablePointer<AVBSFContext>?
        try throwIfFail(av_bsf_alloc(filter._value, &p))
        _value = p!
    }
    
    public init(list: String) throws {
        var p: UnsafeMutablePointer<AVBSFContext>?
        try throwIfFail(av_bsf_list_parse_str(list, &p))
        _value = p!
    }
    
    public func prepare() throws {
        try throwIfFail(av_bsf_init(_value))
    }
    
    public func send(packet: FFmpegPacket) throws {
        try throwIfFail(av_bsf_send_packet(_value, packet._value))
    }
    
    public func reveive(packet: FFmpegPacket) throws {
        try throwIfFail(av_bsf_receive_packet(_value, packet._value))
    }
    
    public func flush() {
        av_bsf_flush(_value)
    }
    
    deinit {
        var p: UnsafeMutablePointer<AVBSFContext>? = _value
        av_bsf_free(&p)
    }
    
    public var description: String {
        return """
        """
    }
}
/*
public struct AVBitStreamFilterContext {
    
    public var priv_data: UnsafeMutableRawPointer!
    
    public var filter: UnsafePointer<AVBitStreamFilter>!
    
    public var parser: UnsafeMutablePointer<AVCodecParserContext>!
    
    public var next: UnsafeMutablePointer<AVBitStreamFilterContext>!
    
    /**
     * Internal default arguments, used if NULL is passed to av_bitstream_filter_filter().
     * Not for access by library users.
     */
    public var args: UnsafeMutablePointer<Int8>!
    
    public init()
    
    public init(priv_data: UnsafeMutableRawPointer!, filter: UnsafePointer<AVBitStreamFilter>!, parser: UnsafeMutablePointer<AVCodecParserContext>!, next: UnsafeMutablePointer<AVBitStreamFilterContext>!, args: UnsafeMutablePointer<Int8>!)
}

public struct AVBSFContext {
    
    /**
     * A class for logging and AVOptions
     */
    public var av_class: UnsafePointer<AVClass>!
    
    
    /**
     * The bitstream filter this context is an instance of.
     */
    public var filter: UnsafePointer<AVBitStreamFilter>!
    
    
    /**
     * Opaque libavcodec internal data. Must not be touched by the caller in any
     * way.
     */
    public var `internal`: OpaquePointer!
    
    
    /**
     * Opaque filter-specific private data. If filter->priv_class is non-NULL,
     * this is an AVOptions-enabled struct.
     */
    public var priv_data: UnsafeMutableRawPointer!
    
    
    /**
     * Parameters of the input stream. This field is allocated in
     * av_bsf_alloc(), it needs to be filled by the caller before
     * av_bsf_init().
     */
    public var par_in: UnsafeMutablePointer<AVCodecParameters>!
    
    
    /**
     * Parameters of the output stream. This field is allocated in
     * av_bsf_alloc(), it is set by the filter in av_bsf_init().
     */
    public var par_out: UnsafeMutablePointer<AVCodecParameters>!
    
    
    /**
     * The timebase used for the timestamps of the input packets. Set by the
     * caller before av_bsf_init().
     */
    public var time_base_in: AVRational
    
    
    /**
     * The timebase used for the timestamps of the output packets. Set by the
     * filter in av_bsf_init().
     */
    public var time_base_out: AVRational
    
    public init()
    
    public init(av_class: UnsafePointer<AVClass>!, filter: UnsafePointer<AVBitStreamFilter>!, internal: OpaquePointer!, priv_data: UnsafeMutableRawPointer!, par_in: UnsafeMutablePointer<AVCodecParameters>!, par_out: UnsafeMutablePointer<AVCodecParameters>!, time_base_in: AVRational, time_base_out: AVRational)
}
*/
