//
//  FuncWrapper.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/13.
//
import CFFmpeg

public struct FFmpegRegister {
    public static func register() {
        
    }
    
    private static func test() {
        
    }
}

public struct FFmpegRescale {
    public static func rescale(_ a: Int64, _ b: Int64, _ c: Int64) -> Int64 {
        return av_rescale(a, b, c)
    }
    
    public static func rescale_rnd(_ a: Int64, _ b: Int64, _ c: Int64, _ rnd: FFmpegRounding) -> Int64 {
        return av_rescale_rnd(a, b, c, rnd.avRounding)
    }
    
    public static func rescale_q(_ a: Int64, _ bq: AVRational, _ cq: AVRational) -> Int64 {
        return av_rescale_q(a, bq, cq)
    }
    
    public static func rescale_q_rnd(_ a: Int64, _ bq: AVRational, _ cq: AVRational, _ rnd: FFmpegRounding) -> Int64 {
        return av_rescale_q_rnd(a, bq, cq, rnd.avRounding)
    }
}

public struct FFmpegTimestamp {
    public static func ts2str(timestamp: Int64) -> String {
        // AV_TS_MAX_STRING_SIZE 32
        var buffer = [CChar].init(repeating: 0, count: 32)
        av_ts_make_string(&buffer, timestamp)
        return String.init(cString: &buffer)
    }
    
    public static func av_ts2timestr(timestamp: Int64, timebase: AVRational) -> String {
        var buffer = [CChar].init(repeating: 0, count: 32)
        var timebase = timebase
        av_ts_make_time_string(&buffer, timestamp, &timebase)
        return String.init(cString: &buffer)
    }
}

public struct FFmpegRounding: OptionSet {
    public let rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    internal init(rawValue: AVRounding) {
        self.rawValue = rawValue.rawValue
    }
    
    internal var avRounding: AVRounding {
        return .init(rawValue: rawValue)
    }
}

public extension FFmpegRounding {
    static let zero: FFmpegRounding = .init(rawValue: AV_ROUND_ZERO)
    static let inf: FFmpegRounding = .init(rawValue: AV_ROUND_INF)
    static let down: FFmpegRounding = .init(rawValue: AV_ROUND_DOWN)
    static let up: FFmpegRounding = .init(rawValue: AV_ROUND_UP)
    static let nearInf: FFmpegRounding = .init(rawValue: AV_ROUND_NEAR_INF)
    static let passMinmax: FFmpegRounding = .init(rawValue: AV_ROUND_PASS_MINMAX)
}
