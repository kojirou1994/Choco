//
//  FFmpegColorPrimaries.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/14.
//

import Foundation
import CFFmpeg

public enum FFmpegColorPrimaries: CustomStringConvertible {
    
    case reserved0
    case bt709
    case unspecified
    case reserved
    case bt470m
    case bt470bg
    case smpte170m
    case smpte240m
    case film
    case bt2020
    case smpte428
    case smptest428_1
    case smpte431
    case smpte432
    case jedec_p22
    case nb
    
    var rawValue: AVColorPrimaries {
        switch self {
        case .reserved0: return AVCOL_PRI_RESERVED0
        case .bt709: return AVCOL_PRI_BT709
        case .unspecified: return AVCOL_PRI_UNSPECIFIED
        case .reserved: return AVCOL_PRI_RESERVED
        case .bt470m: return AVCOL_PRI_BT470M
        case .bt470bg: return AVCOL_PRI_BT470BG
        case .smpte170m: return AVCOL_PRI_SMPTE170M
        case .smpte240m: return AVCOL_PRI_SMPTE240M
        case .film: return AVCOL_PRI_FILM
        case .bt2020: return AVCOL_PRI_BT2020
        case .smpte428: return AVCOL_PRI_SMPTE428
        case .smptest428_1: return AVCOL_PRI_SMPTEST428_1
        case .smpte431: return AVCOL_PRI_SMPTE431
        case .smpte432: return AVCOL_PRI_SMPTE432
        case .jedec_p22: return AVCOL_PRI_JEDEC_P22
        case .nb: return AVCOL_PRI_NB
        }
    }
    
    init(rawValue: AVColorPrimaries) {
        switch rawValue {
        case AVCOL_PRI_RESERVED0: self = .reserved0
        case AVCOL_PRI_BT709: self = .bt709
        case AVCOL_PRI_UNSPECIFIED: self = .unspecified
        case AVCOL_PRI_RESERVED: self = .reserved
        case AVCOL_PRI_BT470M: self = .bt470m
        case AVCOL_PRI_BT470BG: self = .bt470bg
        case AVCOL_PRI_SMPTE170M: self = .smpte170m
        case AVCOL_PRI_SMPTE240M: self = .smpte240m
        case AVCOL_PRI_FILM: self = .film
        case AVCOL_PRI_BT2020: self = .bt2020
        case AVCOL_PRI_SMPTE428: self = .smpte428
        case AVCOL_PRI_SMPTEST428_1: self = .smptest428_1
        case AVCOL_PRI_SMPTE431: self = .smpte431
        case AVCOL_PRI_SMPTE432: self = .smpte432
        case AVCOL_PRI_JEDEC_P22: self = .jedec_p22
        case AVCOL_PRI_NB: self = .nb
        default: fatalError()
        }
    }
    
    public var description: String {
        switch self {
        case .reserved0: return "reserved0"
        case .bt709: return "also ITU-R BT1361 / IEC 61966-2-4 / SMPTE RP177 Annex B"
        case .unspecified: return "also ITU-R BT1361 / IEC 61966-2-4 / SMPTE RP177 Annex B"
        case .reserved: return "also ITU-R BT1361 / IEC 61966-2-4 / SMPTE RP177 Annex B"
        case .bt470m: return "also FCC Title 47 Code of Federal Regulations 73.682 (a)(20)"
        case .bt470bg: return "also ITU-R BT601-6 625 / ITU-R BT1358 625 / ITU-R BT1700 625 PAL & SECAM"
        case .smpte170m: return "also ITU-R BT601-6 525 / ITU-R BT1358 525 / ITU-R BT1700 NTSC"
        case .smpte240m: return "functionally identical to above"
        case .film: return "colour filters using Illuminant C"
        case .bt2020: return "ITU-R BT2020"
        case .smpte428: return "SMPTE ST 428-1 (CIE 1931 XYZ)"
        case .smptest428_1: return "SMPTE ST 428-1 (CIE 1931 XYZ)"
        case .smpte431: return "SMPTE ST 431-2 (2011) / DCI P3"
        case .smpte432: return "SMPTE ST 432-1 (2010) / P3 D65 / Display P3"
        case .jedec_p22: return "JEDEC P22 phosphors"
        case .nb: return "Not part of ABI"
        }
        
    }
    
}
