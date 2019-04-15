//
//  FFmpegSampleFormat.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/14.
//

import Foundation
import CFFmpeg

public struct FFmpegSampleFormat: CustomStringConvertible, Equatable {
    
    var rawValue: AVSampleFormat
    
    init(rawValue: AVSampleFormat) {
        self.rawValue = rawValue
    }
    
    init(rawValue: Int32) {
        self.rawValue = .init(rawValue: rawValue)
    }
    
    /// The name of sample_fmt, or nil if sample_fmt is not recognized.
    public var name: String {
        if let strBytes = av_get_sample_fmt_name(rawValue) {
            return String(cString: strBytes)
        }
        return "unknown"
    }
    
    public var description: String {
        return name
    }
    
    public var packedSampleFmt: FFmpegSampleFormat {
        return .init(rawValue: av_get_packed_sample_fmt(rawValue))
    }
    
    public var planarSampleFmt: FFmpegSampleFormat {
        return .init(rawValue: av_get_planar_sample_fmt(rawValue))
    }
    
    public var isPlanar: Bool {
        return av_sample_fmt_is_planar(rawValue) == 1
    }
    
    public var bytesPerSample: Int {
        return Int(av_get_bytes_per_sample(rawValue))
    }
}
