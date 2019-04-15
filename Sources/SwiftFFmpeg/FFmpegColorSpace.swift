//
//  FFmpegColorSpace.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/14.
//

import Foundation
import CFFmpeg

public enum FFmpegColorSpace: CustomStringConvertible {
    
    case rgb
    case bt709
    case unspecified
    case reserved
    case fcc
    case bt470bg
    case smpte170m
    case smpte240m
    case ycgco
    case ycocg
    case bt2020_ncl
    case bt2020_cl
    case smpte2085
    case chroma_derived_ncl
    case chroma_derived_cl
    case ictcp
    case nb
    
    var rawValue: AVColorSpace {
        switch self {
        case .rgb: return AVCOL_SPC_RGB
        case .bt709: return AVCOL_SPC_BT709
        case .unspecified: return AVCOL_SPC_UNSPECIFIED
        case .reserved: return AVCOL_SPC_RESERVED
        case .fcc: return AVCOL_SPC_FCC
        case .bt470bg: return AVCOL_SPC_BT470BG
        case .smpte170m: return AVCOL_SPC_SMPTE170M
        case .smpte240m: return AVCOL_SPC_SMPTE240M
        case .ycgco: return AVCOL_SPC_YCGCO
        case .ycocg: return AVCOL_SPC_YCOCG
        case .bt2020_ncl: return AVCOL_SPC_BT2020_NCL
        case .bt2020_cl: return AVCOL_SPC_BT2020_CL
        case .smpte2085: return AVCOL_SPC_SMPTE2085
        case .chroma_derived_ncl: return AVCOL_SPC_CHROMA_DERIVED_NCL
        case .chroma_derived_cl: return AVCOL_SPC_CHROMA_DERIVED_CL
        case .ictcp: return AVCOL_SPC_ICTCP
        case .nb: return AVCOL_SPC_NB
        }
    }
    
    init(rawValue: AVColorSpace) {
        switch rawValue {
        case AVCOL_SPC_RGB: self = .rgb
        case AVCOL_SPC_BT709: self = .bt709
        case AVCOL_SPC_UNSPECIFIED: self = .unspecified
        case AVCOL_SPC_RESERVED: self = .reserved
        case AVCOL_SPC_FCC: self = .fcc
        case AVCOL_SPC_BT470BG: self = .bt470bg
        case AVCOL_SPC_SMPTE170M: self = .smpte170m
        case AVCOL_SPC_SMPTE240M: self = .smpte240m
        case AVCOL_SPC_YCGCO: self = .ycgco
        case AVCOL_SPC_YCOCG: self = .ycocg
        case AVCOL_SPC_BT2020_NCL: self = .bt2020_ncl
        case AVCOL_SPC_BT2020_CL: self = .bt2020_cl
        case AVCOL_SPC_SMPTE2085: self = .smpte2085
        case AVCOL_SPC_CHROMA_DERIVED_NCL: self = .chroma_derived_ncl
        case AVCOL_SPC_CHROMA_DERIVED_CL: self = .chroma_derived_cl
        case AVCOL_SPC_ICTCP: self = .ictcp
        case AVCOL_SPC_NB: self = .nb
        default: fatalError()
        }
    }
    
    public var description: String {
        switch self {
        case .rgb: return "order of coefficients is actually GBR, also IEC 61966-2-1 (sRGB)"
        case .bt709: return "also ITU-R BT1361 / IEC 61966-2-4 xvYCC709 / SMPTE RP177 Annex B"
        case .unspecified: return "also ITU-R BT1361 / IEC 61966-2-4 xvYCC709 / SMPTE RP177 Annex B"
        case .reserved: return "also ITU-R BT1361 / IEC 61966-2-4 xvYCC709 / SMPTE RP177 Annex B"
        case .fcc: return "FCC Title 47 Code of Federal Regulations 73.682 (a)(20)"
        case .bt470bg: return "also ITU-R BT601-6 625 / ITU-R BT1358 625 / ITU-R BT1700 625 PAL & SECAM / IEC 61966-2-4 xvYCC601"
        case .smpte170m: return "also ITU-R BT601-6 525 / ITU-R BT1358 525 / ITU-R BT1700 NTSC"
        case .smpte240m: return "functionally identical to above"
        case .ycgco: return "Used by Dirac / VC-2 and H.264 FRext, see ITU-T SG16"
        case .ycocg: return "Used by Dirac / VC-2 and H.264 FRext, see ITU-T SG16"
        case .bt2020_ncl: return "ITU-R BT2020 non-constant luminance system"
        case .bt2020_cl: return "ITU-R BT2020 constant luminance system"
        case .smpte2085: return "SMPTE 2085, Y'D'zD'x"
        case .chroma_derived_ncl: return "Chromaticity-derived non-constant luminance system"
        case .chroma_derived_cl: return "Chromaticity-derived constant luminance system"
        case .ictcp: return "ITU-R BT.2100-0, ICtCp"
        case .nb: return "Not part of ABI"
        }
        
    }
    
}
