//
//  extensions.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/12.
//

import Foundation
import CFFmpeg

public struct FFmpegRational: CustomStringConvertible {
    
    internal let rawValue: AVRational
    
    internal init(rawValue: AVRational) {
        self.rawValue = rawValue
    }
    
    public init(num: Int32, den: Int32) {
        rawValue = .init(num: num, den: den)
    }
    
    public init(d: Double, max: Int32) {
        rawValue = av_d2q(d, max)
    }
    
    /// Convert an AVRational to a `double`.
    public var doubleValue: Double {
        return av_q2d(rawValue)
    }
    
    public var inverted: FFmpegRational {
        return .init(rawValue: av_inv_q(rawValue))
    }
    
    public func nearer(_ q1: FFmpegRational, _ q2: FFmpegRational) -> Int32 {
        return av_nearer_q(rawValue, q1.rawValue, q2.rawValue)
    }
    
    public var description: String {
        return "\(rawValue.num)/\(rawValue.den)"
    }
    
}

extension FFmpegRational: Comparable, Equatable {
    
    public static func < (lhs: FFmpegRational, rhs: FFmpegRational) -> Bool {
        return av_cmp_q(lhs.rawValue, rhs.rawValue) == -1
    }
    
    public static func == (lhs: FFmpegRational, rhs: FFmpegRational) -> Bool {
        return av_cmp_q(lhs.rawValue, rhs.rawValue) == 0
    }
    
    public static func + (lhs: FFmpegRational, rhs: FFmpegRational) -> FFmpegRational {
        return .init(rawValue: av_add_q(lhs.rawValue, rhs.rawValue))
    }
    
    public static func - (lhs: FFmpegRational, rhs: FFmpegRational) -> FFmpegRational {
        return .init(rawValue: av_sub_q(lhs.rawValue, rhs.rawValue))
    }
    
    public static func * (lhs: FFmpegRational, rhs: FFmpegRational) -> FFmpegRational {
        return .init(rawValue: av_mul_q(lhs.rawValue, rhs.rawValue))
    }
    
    public static func / (lhs: FFmpegRational, rhs: FFmpegRational) -> FFmpegRational {
        return .init(rawValue: av_div_q(lhs.rawValue, rhs.rawValue))
    }
}

extension AVRounding {
    
//    func union(_ other: AVRounding) -> AVRounding {
//        if other != AV_ROUND_PASS_MINMAX { return self }
//        return AVRounding(rawValue | other.rawValue)
//    }
}
