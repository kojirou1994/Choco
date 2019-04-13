//
//  extensions.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/12.
//

import Foundation
import CFFmpeg

extension AVRational {
    /// Convert an AVRational to a `double`.
    public var doubleValue: Double {
        return av_q2d(self)
    }
}

extension AVRational: Comparable, Equatable {
    public static func < (lhs: AVRational, rhs: AVRational) -> Bool {
        return av_cmp_q(lhs, rhs) == -1
    }
    
    public static func == (lhs: AVRational, rhs: AVRational) -> Bool {
        return av_cmp_q(lhs, rhs) == 0
    }
}

extension AVRounding {
    
//    func union(_ other: AVRounding) -> AVRounding {
//        if other != AV_ROUND_PASS_MINMAX { return self }
//        return AVRounding(rawValue | other.rawValue)
//    }
}

/// Rescale a integer with specified rounding.
///
/// The operation is mathematically equivalent to `a * b / c`, but writing that
/// directly can overflow, and does not support different rounding methods.
//public func rescale<T: BinaryInteger>(_ a: T, _ b: T, _ c: T, _ rnd: AVRounding = .inf) -> Int64 {
//    return av_rescale_rnd(Int64(a), Int64(b), Int64(c), rnd)
//}

/// Rescale a integer by 2 rational numbers with specified rounding.
///
/// The operation is mathematically equivalent to `a * bq / cq`.
//public func rescale<T: BinaryInteger>(_ a: T, _ b: AVRational, _ c: AVRational, _ rnd: AVRounding = .inf) -> Int64 {
//    return av_rescale_q_rnd(Int64(a), b, c, rnd)
//}
