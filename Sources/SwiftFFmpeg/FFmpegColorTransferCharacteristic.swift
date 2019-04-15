//
//  FFmpegColorTransferCharacteristic.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/14.
//

import Foundation
import CFFmpeg

public enum FFmpegColorTransferCharacteristic: CustomStringConvertible {
    
    case reserved0
    case bt709
    case unspecified
    case reserved
    case gamma22
    case gamma28
    case smpte170m
    case smpte240m
    case linear
    case log
    case log_sqrt
    case iec61966_2_4
    case bt1361_ecg
    case iec61966_2_1
    case bt2020_10
    case bt2020_12
    case smpte2084
    case smptest2084
    case smpte428
    case smptest428_1
    case arib_std_b67
    case nb
    
    var rawValue: AVColorTransferCharacteristic {
        switch self {
        case .reserved0: return AVCOL_TRC_RESERVED0
        case .bt709: return AVCOL_TRC_BT709
        case .unspecified: return AVCOL_TRC_UNSPECIFIED
        case .reserved: return AVCOL_TRC_RESERVED
        case .gamma22: return AVCOL_TRC_GAMMA22
        case .gamma28: return AVCOL_TRC_GAMMA28
        case .smpte170m: return AVCOL_TRC_SMPTE170M
        case .smpte240m: return AVCOL_TRC_SMPTE240M
        case .linear: return AVCOL_TRC_LINEAR
        case .log: return AVCOL_TRC_LOG
        case .log_sqrt: return AVCOL_TRC_LOG_SQRT
        case .iec61966_2_4: return AVCOL_TRC_IEC61966_2_4
        case .bt1361_ecg: return AVCOL_TRC_BT1361_ECG
        case .iec61966_2_1: return AVCOL_TRC_IEC61966_2_1
        case .bt2020_10: return AVCOL_TRC_BT2020_10
        case .bt2020_12: return AVCOL_TRC_BT2020_12
        case .smpte2084: return AVCOL_TRC_SMPTE2084
        case .smptest2084: return AVCOL_TRC_SMPTEST2084
        case .smpte428: return AVCOL_TRC_SMPTE428
        case .smptest428_1: return AVCOL_TRC_SMPTEST428_1
        case .arib_std_b67: return AVCOL_TRC_ARIB_STD_B67
        case .nb: return AVCOL_TRC_NB
        }
    }
    
    init(rawValue: AVColorTransferCharacteristic) {
        switch rawValue {
        case AVCOL_TRC_RESERVED0: self = .reserved0
        case AVCOL_TRC_BT709: self = .bt709
        case AVCOL_TRC_UNSPECIFIED: self = .unspecified
        case AVCOL_TRC_RESERVED: self = .reserved
        case AVCOL_TRC_GAMMA22: self = .gamma22
        case AVCOL_TRC_GAMMA28: self = .gamma28
        case AVCOL_TRC_SMPTE170M: self = .smpte170m
        case AVCOL_TRC_SMPTE240M: self = .smpte240m
        case AVCOL_TRC_LINEAR: self = .linear
        case AVCOL_TRC_LOG: self = .log
        case AVCOL_TRC_LOG_SQRT: self = .log_sqrt
        case AVCOL_TRC_IEC61966_2_4: self = .iec61966_2_4
        case AVCOL_TRC_BT1361_ECG: self = .bt1361_ecg
        case AVCOL_TRC_IEC61966_2_1: self = .iec61966_2_1
        case AVCOL_TRC_BT2020_10: self = .bt2020_10
        case AVCOL_TRC_BT2020_12: self = .bt2020_12
        case AVCOL_TRC_SMPTE2084: self = .smpte2084
        case AVCOL_TRC_SMPTEST2084: self = .smptest2084
        case AVCOL_TRC_SMPTE428: self = .smpte428
        case AVCOL_TRC_SMPTEST428_1: self = .smptest428_1
        case AVCOL_TRC_ARIB_STD_B67: self = .arib_std_b67
        case AVCOL_TRC_NB: self = .nb
        default: fatalError()
        }
    }
    
    public var description: String {
        switch self {
        case .reserved0: return "reserved0"
        case .bt709: return "also ITU-R BT1361"
        case .unspecified: return "also ITU-R BT1361"
        case .reserved: return "also ITU-R BT1361"
        case .gamma22: return "also ITU-R BT470M / ITU-R BT1700 625 PAL & SECAM"
        case .gamma28: return "also ITU-R BT470BG"
        case .smpte170m: return "also ITU-R BT601-6 525 or 625 / ITU-R BT1358 525 or 625 / ITU-R BT1700 NTSC"
        case .smpte240m: return "also ITU-R BT601-6 525 or 625 / ITU-R BT1358 525 or 625 / ITU-R BT1700 NTSC"
        case .linear: return "Linear transfer characteristics"
        case .log: return "Logarithmic transfer characteristic (100:1 range)"
        case .log_sqrt: return "Logarithmic transfer characteristic (100 * Sqrt(10) : 1 range)"
        case .iec61966_2_4: return "IEC 61966-2-4"
        case .bt1361_ecg: return "ITU-R BT1361 Extended Colour Gamut"
        case .iec61966_2_1: return "IEC 61966-2-1 (sRGB or sYCC)"
        case .bt2020_10: return "ITU-R BT2020 for 10-bit system"
        case .bt2020_12: return "ITU-R BT2020 for 12-bit system"
        case .smpte2084: return "SMPTE ST 2084 for 10-, 12-, 14- and 16-bit systems"
        case .smptest2084: return "SMPTE ST 2084 for 10-, 12-, 14- and 16-bit systems"
        case .smpte428: return "SMPTE ST 428-1"
        case .smptest428_1: return "SMPTE ST 428-1"
        case .arib_std_b67: return "ARIB STD-B67, known as Hybrid log-gamma"
        case .nb: return "Not part of ABI"
        }
        
    }
    
}
