//
//  ValueTypes.swift
//  BD_Chapters_MOD
//
//  Created by Kojirou on 2019/2/5.
//

import Foundation

public enum AudioRate: UInt8, CustomStringConvertible {
    public var description: String {
        switch self {
        case .k192Khz: return "192 Khz"
        case .k48Khz: return "48 Khz"
        case .k48_192Khz: return "48/192 Khz"
        case .k48_96Khz: return "48/96 Khz"
        case .k96Khz: return "96 Khz"
        case .reserved1: return "Reserved1"
        case .reserved2: return "Reserved2"
        case .reserved3: return "Reserved3"
        }
    }
    
    case reserved1 = 0
    case k48Khz = 1
    case reserved2 = 2
    case reserved3 = 3
    case k96Khz = 4
    case k192Khz = 5
    case k48_192Khz = 12
    case k48_96Khz = 14
    
    init(value: UInt8) throws {
        if let v = AudioRate.init(rawValue: value) {
            self = v
        } else {
            throw MplsReadError.invalidAudioRate(value)
        }
    }
    
}
public enum AudioFormat: UInt8, CustomStringConvertible {
    
    init(value: UInt8) throws {
        if let v = AudioFormat.init(rawValue: value) {
            self = v
        } else {
            throw MplsReadError.invalidAudioFormat(value)
        }
    }
    
    public var description: String {
        switch self {
        case .mono: return "Mono"
        case .stereo: return "Stereo"
        case .multiChannel: return "Multi Channel"
        case .combo: return "Combo"
        case .reserved1: return "Reserved1"
        case .reserved2: return "Reserved2"
        case .reserved3: return "Reserved3"
        case .reserved4: return "Reserved4"
        }
    }
    
    case reserved1 = 0
    case mono = 1
    case reserved2 = 2
    case stereo = 3
    case reserved3 = 4
    case reserved4 = 5
    case multiChannel = 6
    case combo = 12
    
}

public enum VideoRate: UInt8, CustomStringConvertible {
    case reserved1 = 0
    case k23_976 = 1
    case k24 = 2
    case k25 = 3
    case k29_97 = 4
    case reserved2 = 5
    case k50 = 6
    case k59_94 = 7
    
    init(value: UInt8) throws {
        if let v = VideoRate.init(rawValue: value) {
            self = v
        } else {
            throw MplsReadError.invalidVideoRate(value)
        }
    }
    
    public var description: String {
        switch self {
        case .k23_976: return "23.976"
        case .k24: return "24"
        case .k25: return "25"
        case .k29_97: return "29.97"
        case .k50: return "50"
        case .k59_94: return "59.94"
        case .reserved1: return "Reserved1"
        case .reserved2: return "Reserved2"
        }
    }
    
    public var doubleValue: Double {
        switch self {
        case .k23_976: return 23.976
        case .k24: return 24
        case .k25: return 25
        case .k29_97: return 29.97
        case .k50: return 50
        case .k59_94: return 59.94
        case .reserved1: return 0
        case .reserved2: return 0
        }
    }
}

public enum VideoFormat: UInt8, CustomStringConvertible {
    case reserved = 0
    case k480i = 1
    case k576i = 2
    case k480p = 3
    case k1080i = 4
    case k720p = 5
    case k1080p = 6
    case k576p = 7
    case k4k = 8
    
    init(value: UInt8) throws {
        if let v = VideoFormat.init(rawValue: value) {
            self = v
        } else {
            throw MplsReadError.invalidVideoFormat(value)
        }
    }
    
    public var description: String {
        switch self {
        case .k1080i: return "1080i"
        case .k1080p: return "1080p"
        case .k480i: return "480i"
        case .k480p: return "480p"
        case .k576i: return "576i"
        case .k576p: return "576p"
        case .k720p: return "720p"
        case .reserved: return "Reserved"
        case .k4k: return "4k"
        }
    }
}

public enum Codec: UInt8, CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .InteractiveGraphics: return "Interactive Graphics"
        case .ac3: return "AC-3"
        case .ac3Plus: return "AC-3 Plus"
        case .dts: return "DTS"
        case .dtsHD: return "DTS-HD"
        case .dtsHDMater: return "DTS-HD Master"
        case .h264: return "H.264"
        case .lpcm: return "LPCM"
        case .mpeg1Audio: return "MPEG-1 Audio"
        case .mpeg1Video: return "MPEG-1 Video"
        case .mpeg2Audio: return "MPEG-2 Audio"
        case .mpeg2Video: return "MPEG-2 Video"
        case .presentationGraphics: return "Presentation Graphics"
        case .textSubtitle: return "Text Subtitle"
        case .trueHD: return "TrueHD"
        case .vc1: return "VC-1"
        case .hevc: return "HEVC"
        }
    }
    
    case mpeg1Video = 0x01
    case mpeg2Video = 0x02
    case mpeg1Audio = 0x03
    case mpeg2Audio = 0x04
    case lpcm = 0x80
    case ac3 = 0x81
    case dts = 0x82
    case trueHD = 0x83
    case ac3Plus = 0x84
    case dtsHD = 0x85
    case dtsHDMater = 0x86
    case vc1 = 0xea
    case h264 = 0x1b
    case presentationGraphics = 0x90
    case InteractiveGraphics = 0x91
    case textSubtitle = 0x92
    case hevc = 0x24
    
    public init(value: UInt8) throws {
        if let v = Codec.init(rawValue: value) {
            self = v
        } else {
            throw MplsReadError.invalidCodec(value)
        }
    }
    
    var isVideo: Bool {
        switch self {
        case .mpeg1Video, .mpeg2Video, .vc1, .h264, .hevc:
            return true
        default:
            return false
        }
    }
    
    var isAudio: Bool {
        switch self {
        case .mpeg1Audio, .mpeg2Audio, .lpcm, .ac3, .dts, .trueHD, .ac3Plus, .dtsHD, .dtsHDMater:
            return true
        default:
            return false
        }
    }
    
    var isGraphics: Bool {
        switch self {
        case .presentationGraphics, .InteractiveGraphics:
            return true
        default:
            return false
        }
    }
    
    var isText: Bool {
        switch self {
        case .textSubtitle:
            return true
        default:
            return false
        }
    }
}
