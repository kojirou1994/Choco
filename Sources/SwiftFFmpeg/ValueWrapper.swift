//
//  ValueWrapper.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/12.
//

import Foundation
import CFFmpeg

public struct Capability: OptionSet {
    
    public let rawValue: Int32
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

}

public extension Capability {
    static var draw_horiz_band: Capability { return .init(rawValue: AV_CODEC_CAP_DRAW_HORIZ_BAND) }
    static var dr1: Capability { return .init(rawValue: AV_CODEC_CAP_DR1) }
    static var truncated: Capability { return .init(rawValue: AV_CODEC_CAP_TRUNCATED) }
    static var delay: Capability { return .init(rawValue: AV_CODEC_CAP_DELAY) }
    static var small_last_frame: Capability { return .init(rawValue: AV_CODEC_CAP_SMALL_LAST_FRAME) }
    static var subframes: Capability { return .init(rawValue: AV_CODEC_CAP_SUBFRAMES) }
    static var experimental: Capability { return .init(rawValue: AV_CODEC_CAP_EXPERIMENTAL) }
    static var channel_conf: Capability { return .init(rawValue: AV_CODEC_CAP_CHANNEL_CONF) }
    static var frame_threads: Capability { return .init(rawValue: AV_CODEC_CAP_FRAME_THREADS) }
    static var slice_threads: Capability { return .init(rawValue: AV_CODEC_CAP_SLICE_THREADS) }
    static var param_change: Capability { return .init(rawValue: AV_CODEC_CAP_PARAM_CHANGE) }
    static var auto_threads: Capability { return .init(rawValue: AV_CODEC_CAP_AUTO_THREADS) }
    static var variable_frame_size: Capability { return .init(rawValue: AV_CODEC_CAP_VARIABLE_FRAME_SIZE) }
    static var avoid_probing: Capability { return .init(rawValue: AV_CODEC_CAP_AVOID_PROBING) }
    static var intra_only: Capability { return .init(rawValue: AV_CODEC_CAP_INTRA_ONLY) }
    static var lossless: Capability { return .init(rawValue: .init(bitPattern: AV_CODEC_CAP_LOSSLESS)) }
    static var hardware: Capability { return .init(rawValue: AV_CODEC_CAP_HARDWARE) }
    static var hybrid: Capability { return .init(rawValue: AV_CODEC_CAP_HYBRID) }
}

extension Capability: CustomStringConvertible {
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
