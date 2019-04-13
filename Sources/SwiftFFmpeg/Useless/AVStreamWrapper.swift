//
//  AVStream.swift
//  SwiftFFmpeg
//
//  Created by sunlubo on 2018/6/29.
//

import CFFmpeg

// MARK: - AVDiscard

//public typealias AVDiscard = CFFmpeg.AVDiscard

//extension AVDiscard {
//    /// discard nothing
//    public static let none = AVDISCARD_NONE
//    /// discard useless packets like 0 size packets in avi
//    public static let `default` = AVDISCARD_DEFAULT
//    /// discard all non reference
//    public static let nonRef = AVDISCARD_NONREF
//    /// discard all bidirectional frames
//    public static let bidir = AVDISCARD_BIDIR
//    /// discard all non intra frames
//    public static let nonIntra = AVDISCARD_NONINTRA
//    /// discard all frames except keyframes
//    public static let nonKey = AVDISCARD_NONKEY
//    /// discard all
//    public static let all = AVDISCARD_ALL
//}

// MARK: - Audio

/// This class describes the properties of an encoded stream.
