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
    
    public init(name: String) throws {
        guard let p = av_bsf_get_by_name(name) else {
            throw FFmpegAllocateError("av_bsf_get_by_name")
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
        try throwFFmpegError(av_bsf_get_null_filter(&p))
        return .init(p!)
    }
    
    public init(filter: FFmpegBitStreamFilter) throws {
        var p: UnsafeMutablePointer<AVBSFContext>?
        try throwFFmpegError(av_bsf_alloc(filter._value, &p))
        _value = p!
    }
    
    public init(list: String) throws {
        var p: UnsafeMutablePointer<AVBSFContext>?
        try throwFFmpegError(av_bsf_list_parse_str(list, &p))
        _value = p!
    }
    
    public func prepare() throws {
        try throwFFmpegError(av_bsf_init(_value))
    }
    
    public func send(packet: FFmpegPacket) throws {
        try throwFFmpegError(av_bsf_send_packet(_value, packet._value))
    }
    
    public func reveive(packet: FFmpegPacket) throws {
        try throwFFmpegError(av_bsf_receive_packet(_value, packet._value))
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
