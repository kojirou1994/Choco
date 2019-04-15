//
//  FFmpegCodecID.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/14.
//

import Foundation
import CFFmpeg

public struct FFmpegCodecID: CustomStringConvertible, Equatable {
    
    init(rawValue: AVCodecID) {
        self.rawValue = rawValue
    }
    
    var rawValue: AVCodecID
    
    public var description: String {
        return name
    }
    
    public var name: String {
        return String(cString: avcodec_get_name(rawValue))
    }
    
    /// The codec's media type.
    public var mediaType: FFmpegMediaType {
        return .init(rawValue: avcodec_get_type(rawValue))
    }
    
}

public extension FFmpegCodecID {
    
    static var none: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_NONE) }
    
    /* video codecs */
    static var mpeg1video: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MPEG1VIDEO) }
    ///< preferred ID for MPEG-1/2 video decoding
    static var mpeg2video: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MPEG2VIDEO) }
    static var h261: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_H261) }
    static var h263: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_H263) }
    static var rv10: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_RV10) }
    static var rv20: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_RV20) }
    static var mjpeg: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MJPEG) }
    static var mjpegb: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MJPEGB) }
    static var ljpeg: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_LJPEG) }
    static var sp5x: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SP5X) }
    static var jpegls: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_JPEGLS) }
    static var mpeg4: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MPEG4) }
    static var rawvideo: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_RAWVIDEO) }
    static var msmpeg4v1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MSMPEG4V1) }
    static var msmpeg4v2: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MSMPEG4V2) }
    static var msmpeg4v3: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MSMPEG4V3) }
    static var wmv1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_WMV1) }
    static var wmv2: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_WMV2) }
    static var h263p: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_H263P) }
    static var h263i: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_H263I) }
    static var flv1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_FLV1) }
    static var svq1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SVQ1) }
    static var svq3: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SVQ3) }
    static var dvvideo: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DVVIDEO) }
    static var huffyuv: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_HUFFYUV) }
    static var cyuv: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_CYUV) }
    static var h264: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_H264) }
    static var indeo3: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_INDEO3) }
    static var vp3: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_VP3) }
    static var theora: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_THEORA) }
    static var asv1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ASV1) }
    static var asv2: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ASV2) }
    static var ffv1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_FFV1) }
    static var k4xm: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_4XM) }
    static var vcr1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_VCR1) }
    static var cljr: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_CLJR) }
    static var mdec: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MDEC) }
    static var roq: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ROQ) }
    static var interplay_video: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_INTERPLAY_VIDEO) }
    static var xan_wc3: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_XAN_WC3) }
    static var xan_wc4: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_XAN_WC4) }
    static var rpza: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_RPZA) }
    static var cinepak: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_CINEPAK) }
    static var ws_vqa: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_WS_VQA) }
    static var msrle: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MSRLE) }
    static var msvideo1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MSVIDEO1) }
    static var idcin: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_IDCIN) }
    static var k8bps: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_8BPS) }
    static var smc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SMC) }
    static var flic: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_FLIC) }
    static var truemotion1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TRUEMOTION1) }
    static var vmdvideo: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_VMDVIDEO) }
    static var mszh: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MSZH) }
    static var zlib: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ZLIB) }
    static var qtrle: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_QTRLE) }
    static var tscc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TSCC) }
    static var ulti: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ULTI) }
    static var qdraw: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_QDRAW) }
    static var vixl: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_VIXL) }
    static var qpeg: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_QPEG) }
    static var png: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PNG) }
    static var ppm: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PPM) }
    static var pbm: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PBM) }
    static var pgm: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PGM) }
    static var pgmyuv: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PGMYUV) }
    static var pam: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PAM) }
    static var ffvhuff: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_FFVHUFF) }
    static var rv30: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_RV30) }
    static var rv40: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_RV40) }
    static var vc1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_VC1) }
    static var wmv3: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_WMV3) }
    static var loco: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_LOCO) }
    static var wnv1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_WNV1) }
    static var aasc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_AASC) }
    static var indeo2: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_INDEO2) }
    static var fraps: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_FRAPS) }
    static var truemotion2: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TRUEMOTION2) }
    static var bmp: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_BMP) }
    static var cscd: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_CSCD) }
    static var mmvideo: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MMVIDEO) }
    static var zmbv: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ZMBV) }
    static var avs: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_AVS) }
    static var smackvideo: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SMACKVIDEO) }
    static var nuv: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_NUV) }
    static var kmvc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_KMVC) }
    static var flashsv: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_FLASHSV) }
    static var cavs: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_CAVS) }
    static var jpeg2000: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_JPEG2000) }
    static var vmnc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_VMNC) }
    static var vp5: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_VP5) }
    static var vp6: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_VP6) }
    static var vp6f: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_VP6F) }
    static var targa: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TARGA) }
    static var dsicinvideo: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DSICINVIDEO) }
    static var tiertexseqvideo: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TIERTEXSEQVIDEO) }
    static var tiff: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TIFF) }
    static var gif: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_GIF) }
    static var dxa: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DXA) }
    static var dnxhd: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DNXHD) }
    static var thp: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_THP) }
    static var sgi: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SGI) }
    static var c93: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_C93) }
    static var bethsoftvid: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_BETHSOFTVID) }
    static var ptx: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PTX) }
    static var txd: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TXD) }
    static var vp6a: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_VP6A) }
    static var amv: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_AMV) }
    static var vb: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_VB) }
    static var pcx: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCX) }
    static var sunrast: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SUNRAST) }
    static var indeo4: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_INDEO4) }
    static var indeo5: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_INDEO5) }
    static var mimic: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MIMIC) }
    static var rl2: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_RL2) }
    static var escape124: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ESCAPE124) }
    static var dirac: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DIRAC) }
    static var bfi: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_BFI) }
    static var cmv: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_CMV) }
    static var motionpixels: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MOTIONPIXELS) }
    static var tgv: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TGV) }
    static var tgq: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TGQ) }
    static var tqi: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TQI) }
    static var aura: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_AURA) }
    static var aura2: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_AURA2) }
    static var v210x: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_V210X) }
    static var tmv: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TMV) }
    static var v210: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_V210) }
    static var dpx: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DPX) }
    static var mad: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MAD) }
    static var frwu: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_FRWU) }
    static var flashsv2: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_FLASHSV2) }
    static var cdgraphics: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_CDGRAPHICS) }
    static var r210: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_R210) }
    static var anm: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ANM) }
    static var binkvideo: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_BINKVIDEO) }
    static var iff_ilbm: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_IFF_ILBM) }
    
    static var kgv1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_KGV1) }
    static var yop: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_YOP) }
    static var vp8: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_VP8) }
    static var pictor: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PICTOR) }
    static var ansi: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ANSI) }
    static var a64_multi: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_A64_MULTI) }
    static var a64_multi5: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_A64_MULTI5) }
    static var r10k: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_R10K) }
    static var mxpeg: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MXPEG) }
    static var lagarith: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_LAGARITH) }
    static var prores: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PRORES) }
    static var jv: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_JV) }
    static var dfa: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DFA) }
    static var wmv3image: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_WMV3IMAGE) }
    static var vc1image: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_VC1IMAGE) }
    static var utvideo: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_UTVIDEO) }
    static var bmv_video: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_BMV_VIDEO) }
    static var vble: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_VBLE) }
    static var dxtory: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DXTORY) }
    static var v410: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_V410) }
    static var xwd: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_XWD) }
    static var cdxl: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_CDXL) }
    static var xbm: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_XBM) }
    static var zerocodec: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ZEROCODEC) }
    static var mss1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MSS1) }
    static var msa1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MSA1) }
    static var tscc2: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TSCC2) }
    static var mts2: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MTS2) }
    static var cllc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_CLLC) }
    static var mss2: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MSS2) }
    static var vp9: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_VP9) }
    static var aic: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_AIC) }
    static var escape130: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ESCAPE130) }
    static var g2m: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_G2M) }
    static var webp: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_WEBP) }
    static var hnm4_video: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_HNM4_VIDEO) }
    static var hevc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_HEVC) }
    
    static var fic: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_FIC) }
    static var alias_pix: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ALIAS_PIX) }
    static var brender_pix: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_BRENDER_PIX) }
    static var paf_video: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PAF_VIDEO) }
    static var exr: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_EXR) }
    static var vp7: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_VP7) }
    static var sanm: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SANM) }
    static var sgirle: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SGIRLE) }
    static var mvc1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MVC1) }
    static var mvc2: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MVC2) }
    static var hqx: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_HQX) }
    static var tdsc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TDSC) }
    static var hq_hqa: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_HQ_HQA) }
    static var hap: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_HAP) }
    static var dds: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DDS) }
    static var dxv: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DXV) }
    static var screenpresso: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SCREENPRESSO) }
    static var rscc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_RSCC) }
    static var avs2: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_AVS2) }
    
    static var y41p: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_Y41P) }
    static var avrp: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_AVRP) }
    static var k012v: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_012V) }
    static var avui: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_AVUI) }
    static var ayuv: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_AYUV) }
    static var targa_y216: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TARGA_Y216) }
    static var v308: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_V308) }
    static var v408: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_V408) }
    static var yuv4: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_YUV4) }
    static var avrn: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_AVRN) }
    static var cpia: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_CPIA) }
    static var xface: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_XFACE) }
    static var snow: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SNOW) }
    static var smvjpeg: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SMVJPEG) }
    static var apng: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_APNG) }
    static var daala: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DAALA) }
    static var cfhd: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_CFHD) }
    static var truemotion2rt: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TRUEMOTION2RT) }
    static var m101: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_M101) }
    static var magicyuv: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MAGICYUV) }
    static var sheervideo: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SHEERVIDEO) }
    static var ylc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_YLC) }
    static var psd: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PSD) }
    static var pixlet: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PIXLET) }
    static var speedhq: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SPEEDHQ) }
    static var fmvc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_FMVC) }
    static var scpr: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SCPR) }
    static var clearvideo: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_CLEARVIDEO) }
    static var xpm: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_XPM) }
    static var av1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_AV1) }
    static var bitpacked: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_BITPACKED) }
    static var mscc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MSCC) }
    static var srgc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SRGC) }
    static var svg: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SVG) }
    static var gdv: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_GDV) }
    static var fits: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_FITS) }
    static var imm4: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_IMM4) }
    static var prosumer: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PROSUMER) }
    static var mwsc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MWSC) }
    static var wcmv: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_WCMV) }
    static var rasc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_RASC) }
    
    /* various PCM "codecs" */
    ///< A dummy id pointing at the start of audio codecs
    static var first_audio: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_FIRST_AUDIO) }
    static var pcm_s16le: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_S16LE) }
    static var pcm_s16be: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_S16BE) }
    static var pcm_u16le: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_U16LE) }
    static var pcm_u16be: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_U16BE) }
    static var pcm_s8: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_S8) }
    static var pcm_u8: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_U8) }
    static var pcm_mulaw: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_MULAW) }
    static var pcm_alaw: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_ALAW) }
    static var pcm_s32le: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_S32LE) }
    static var pcm_s32be: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_S32BE) }
    static var pcm_u32le: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_U32LE) }
    static var pcm_u32be: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_U32BE) }
    static var pcm_s24le: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_S24LE) }
    static var pcm_s24be: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_S24BE) }
    static var pcm_u24le: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_U24LE) }
    static var pcm_u24be: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_U24BE) }
    static var pcm_s24daud: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_S24DAUD) }
    static var pcm_zork: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_ZORK) }
    static var pcm_s16le_planar: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_S16LE_PLANAR) }
    static var pcm_dvd: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_DVD) }
    static var pcm_f32be: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_F32BE) }
    static var pcm_f32le: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_F32LE) }
    static var pcm_f64be: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_F64BE) }
    static var pcm_f64le: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_F64LE) }
    static var pcm_bluray: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_BLURAY) }
    static var pcm_lxf: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_LXF) }
    static var s302m: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_S302M) }
    static var pcm_s8_planar: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_S8_PLANAR) }
    static var pcm_s24le_planar: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_S24LE_PLANAR) }
    static var pcm_s32le_planar: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_S32LE_PLANAR) }
    static var pcm_s16be_planar: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_S16BE_PLANAR) }
    
    static var pcm_s64le: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_S64LE) }
    static var pcm_s64be: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_S64BE) }
    static var pcm_f16le: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_F16LE) }
    static var pcm_f24le: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_F24LE) }
    static var pcm_vidc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PCM_VIDC) }
    
    /* various ADPCM codecs */
    static var adpcm_ima_qt: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_IMA_QT) }
    static var adpcm_ima_wav: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_IMA_WAV) }
    static var adpcm_ima_dk3: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_IMA_DK3) }
    static var adpcm_ima_dk4: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_IMA_DK4) }
    static var adpcm_ima_ws: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_IMA_WS) }
    static var adpcm_ima_smjpeg: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_IMA_SMJPEG) }
    static var adpcm_ms: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_MS) }
    static var adpcm_4xm: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_4XM) }
    static var adpcm_xa: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_XA) }
    static var adpcm_adx: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_ADX) }
    static var adpcm_ea: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_EA) }
    static var adpcm_g726: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_G726) }
    static var adpcm_ct: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_CT) }
    static var adpcm_swf: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_SWF) }
    static var adpcm_yamaha: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_YAMAHA) }
    static var adpcm_sbpro_4: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_SBPRO_4) }
    static var adpcm_sbpro_3: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_SBPRO_3) }
    static var adpcm_sbpro_2: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_SBPRO_2) }
    static var adpcm_thp: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_THP) }
    static var adpcm_ima_amv: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_IMA_AMV) }
    static var adpcm_ea_r1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_EA_R1) }
    static var adpcm_ea_r3: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_EA_R3) }
    static var adpcm_ea_r2: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_EA_R2) }
    static var adpcm_ima_ea_sead: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_IMA_EA_SEAD) }
    static var adpcm_ima_ea_eacs: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_IMA_EA_EACS) }
    static var adpcm_ea_xas: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_EA_XAS) }
    static var adpcm_ea_maxis_xa: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_EA_MAXIS_XA) }
    static var adpcm_ima_iss: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_IMA_ISS) }
    static var adpcm_g722: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_G722) }
    static var adpcm_ima_apc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_IMA_APC) }
    static var adpcm_vima: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_VIMA) }
    
    static var adpcm_afc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_AFC) }
    static var adpcm_ima_oki: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_IMA_OKI) }
    static var adpcm_dtk: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_DTK) }
    static var adpcm_ima_rad: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_IMA_RAD) }
    static var adpcm_g726le: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_G726LE) }
    static var adpcm_thp_le: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_THP_LE) }
    static var adpcm_psx: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_PSX) }
    static var adpcm_aica: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_AICA) }
    static var adpcm_ima_dat4: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_IMA_DAT4) }
    static var adpcm_mtaf: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ADPCM_MTAF) }
    
    /* AMR */
    static var amr_nb: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_AMR_NB) }
    static var amr_wb: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_AMR_WB) }
    
    /* RealAudio codecs*/
    static var ra_144: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_RA_144) }
    static var ra_288: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_RA_288) }
    
    /* various DPCM codecs */
    static var roq_dpcm: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ROQ_DPCM) }
    static var interplay_dpcm: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_INTERPLAY_DPCM) }
    static var xan_dpcm: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_XAN_DPCM) }
    static var sol_dpcm: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SOL_DPCM) }
    
    static var sdx2_dpcm: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SDX2_DPCM) }
    static var gremlin_dpcm: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_GREMLIN_DPCM) }
    
    /* audio codecs */
    static var mp2: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MP2) }
    ///< preferred ID for decoding MPEG audio layer 1, 2 or 3
    static var mp3: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MP3) }
    static var aac: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_AAC) }
    static var ac3: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_AC3) }
    static var dts: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DTS) }
    static var vorbis: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_VORBIS) }
    static var dvaudio: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DVAUDIO) }
    static var wmav1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_WMAV1) }
    static var wmav2: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_WMAV2) }
    static var mace3: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MACE3) }
    static var mace6: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MACE6) }
    static var vmdaudio: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_VMDAUDIO) }
    static var flac: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_FLAC) }
    static var mp3adu: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MP3ADU) }
    static var mp3on4: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MP3ON4) }
    static var shorten: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SHORTEN) }
    static var alac: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ALAC) }
    static var westwood_snd1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_WESTWOOD_SND1) }
    ///< as in Berlin toast format
    static var gsm: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_GSM) }
    static var qdm2: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_QDM2) }
    static var cook: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_COOK) }
    static var truespeech: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TRUESPEECH) }
    static var tta: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TTA) }
    static var smackaudio: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SMACKAUDIO) }
    static var qcelp: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_QCELP) }
    static var wavpack: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_WAVPACK) }
    static var dsicinaudio: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DSICINAUDIO) }
    static var imc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_IMC) }
    static var musepack7: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MUSEPACK7) }
    static var mlp: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MLP) }
    static var gsm_ms: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_GSM_MS) }
    static var atrac3: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ATRAC3) }
    static var ape: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_APE) }
    static var nellymoser: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_NELLYMOSER) }
    static var musepack8: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MUSEPACK8) }
    static var speex: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SPEEX) }
    static var wmavoice: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_WMAVOICE) }
    static var wmapro: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_WMAPRO) }
    static var wmalossless: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_WMALOSSLESS) }
    static var atrac3p: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ATRAC3P) }
    static var eac3: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_EAC3) }
    static var sipr: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SIPR) }
    static var mp1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MP1) }
    static var twinvq: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TWINVQ) }
    static var truehd: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TRUEHD) }
    static var mp4als: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MP4ALS) }
    static var atrac1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ATRAC1) }
    static var binkaudio_rdft: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_BINKAUDIO_RDFT) }
    static var binkaudio_dct: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_BINKAUDIO_DCT) }
    static var aac_latm: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_AAC_LATM) }
    static var qdmc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_QDMC) }
    static var celt: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_CELT) }
    static var g723_1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_G723_1) }
    static var g729: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_G729) }
    static var k8svx_exp: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_8SVX_EXP) }
    static var k8svx_fib: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_8SVX_FIB) }
    static var bmv_audio: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_BMV_AUDIO) }
    static var ralf: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_RALF) }
    static var iac: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_IAC) }
    static var ilbc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ILBC) }
    static var opus: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_OPUS) }
    static var comfort_noise: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_COMFORT_NOISE) }
    static var tak: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TAK) }
    static var metasound: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_METASOUND) }
    static var paf_audio: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PAF_AUDIO) }
    static var on2avc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ON2AVC) }
    static var dss_sp: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DSS_SP) }
    static var codec2: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_CODEC2) }
    
    static var ffwavesynth: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_FFWAVESYNTH) }
    static var sonic: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SONIC) }
    static var sonic_ls: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SONIC_LS) }
    static var evrc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_EVRC) }
    static var smv: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SMV) }
    static var dsd_lsbf: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DSD_LSBF) }
    static var dsd_msbf: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DSD_MSBF) }
    static var dsd_lsbf_planar: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DSD_LSBF_PLANAR) }
    static var dsd_msbf_planar: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DSD_MSBF_PLANAR) }
    static var k4gv: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_4GV) }
    static var interplay_acm: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_INTERPLAY_ACM) }
    static var xma1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_XMA1) }
    static var xma2: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_XMA2) }
    static var dst: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DST) }
    static var atrac3al: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ATRAC3AL) }
    static var atrac3pal: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ATRAC3PAL) }
    static var dolby_e: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DOLBY_E) }
    static var aptx: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_APTX) }
    static var aptx_hd: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_APTX_HD) }
    static var sbc: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SBC) }
    static var atrac9: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ATRAC9) }
    
    /* subtitle codecs */
    ///< A dummy ID pointing at the start of subtitle codecs.
    static var first_subtitle: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_FIRST_SUBTITLE) }
    static var dvd_subtitle: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DVD_SUBTITLE) }
    static var dvb_subtitle: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DVB_SUBTITLE) }
    ///< raw UTF-8 text
    static var text: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TEXT) }
    static var xsub: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_XSUB) }
    static var ssa: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SSA) }
    static var mov_text: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MOV_TEXT) }
    static var hdmv_pgs_subtitle: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_HDMV_PGS_SUBTITLE) }
    static var dvb_teletext: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DVB_TELETEXT) }
    static var srt: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SRT) }
    
    static var microdvd: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MICRODVD) }
    static var eia_608: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_EIA_608) }
    static var jacosub: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_JACOSUB) }
    static var sami: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SAMI) }
    static var realtext: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_REALTEXT) }
    static var stl: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_STL) }
    static var subviewer1: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SUBVIEWER1) }
    static var subviewer: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SUBVIEWER) }
    static var subrip: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SUBRIP) }
    static var webvtt: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_WEBVTT) }
    static var mpl2: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MPL2) }
    static var vplayer: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_VPLAYER) }
    static var pjs: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PJS) }
    static var ass: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_ASS) }
    static var hdmv_text_subtitle: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_HDMV_TEXT_SUBTITLE) }
    static var ttml: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TTML) }
    
    /* other specific kind of codecs (generally used for attachments) */
    ///< A dummy ID pointing at the start of various fake codecs.
    static var first_unknown: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_FIRST_UNKNOWN) }
    static var ttf: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TTF) }
    
    ///< Contain timestamp estimated through PCR of program stream.
    static var scte_35: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SCTE_35) }
    static var bintext: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_BINTEXT) }
    static var xbin: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_XBIN) }
    static var idf: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_IDF) }
    static var otf: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_OTF) }
    static var smpte_klv: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_SMPTE_KLV) }
    static var dvd_nav: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_DVD_NAV) }
    static var timed_id3: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_TIMED_ID3) }
    static var bin_data: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_BIN_DATA) }
    
    ///< codec_id is not known (like AV_CODEC_ID_NONE) but lavf should attempt to identify it
    static var probe: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_PROBE) }
    
    /**< _FAKE_ codec to indicate a raw MPEG-2 TS
     * stream (only used by libavformat) */
    static var mpeg2ts: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MPEG2TS) }
    
    /**< _FAKE_ codec to indicate a MPEG-4 Systems
     * stream (only used by libavformat) */
    static var mpeg4systems: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_MPEG4SYSTEMS) }
    
    ///< Dummy codec for streams containing only metadata information.
    static var ffmetadata: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_FFMETADATA) }
    ///< Passthrough codec, AVFrames wrapped in AVPacket
    static var wrapped_avframe: FFmpegCodecID { return .init(rawValue: AV_CODEC_ID_WRAPPED_AVFRAME) }
}
