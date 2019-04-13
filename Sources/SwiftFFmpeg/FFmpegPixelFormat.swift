//
//  FFmpegPixelFormat.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/13.
//

import CFFmpeg

public struct FFmpegPixelFormat: CustomStringConvertible, Equatable {
    
    internal let rawValue: AVPixelFormat
    
    internal init(value: Int32) {
        self.rawValue = AVPixelFormat(value)
    }
    
    internal init(rawValue: AVPixelFormat) {
        self.rawValue = rawValue
    }
    
    public init(name: String) {
        rawValue = av_get_pix_fmt(name)
    }
    
    public var name: String {
        if let strBytes = av_get_pix_fmt_name(rawValue) {
            return String(cString: strBytes)
        }
        return "unknown"
    }
    
    /// The number of planes in the pixel format.
    public var planeCount: Int {
        let count = Int(av_pix_fmt_count_planes(rawValue))
        return count >= 0 ? count : 0
    }
    
    public var description: String {
        return name
    }
    
}

public extension FFmpegPixelFormat {
    static var none: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_NONE) }
    ///< planar YUV 4:2:0, 12bpp, (1 Cr & Cb sample per 2x2 Y samples)
    static var yuv420p: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV420P) }
    ///< packed YUV 4:2:2, 16bpp, Y0 Cb Y1 Cr
    static var yuyv422: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUYV422) }
    ///< packed RGB 8:8:8, 24bpp, RGBRGB...
    static var rgb24: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_RGB24) }
    ///< packed RGB 8:8:8, 24bpp, BGRBGR...
    static var bgr24: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BGR24) }
    ///< planar YUV 4:2:2, 16bpp, (1 Cr & Cb sample per 2x1 Y samples)
    static var yuv422p: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV422P) }
    ///< planar YUV 4:4:4, 24bpp, (1 Cr & Cb sample per 1x1 Y samples)
    static var yuv444p: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV444P) }
    ///< planar YUV 4:1:0,  9bpp, (1 Cr & Cb sample per 4x4 Y samples)
    static var yuv410p: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV410P) }
    ///< planar YUV 4:1:1, 12bpp, (1 Cr & Cb sample per 4x1 Y samples)
    static var yuv411p: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV411P) }
    ///<        Y        ,  8bpp
    static var gray8: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GRAY8) }
    ///<        Y        ,  1bpp, 0 is white, 1 is black, in each byte pixels are ordered from the msb to the lsb
    static var monowhite: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_MONOWHITE) }
    ///<        Y        ,  1bpp, 0 is black, 1 is white, in each byte pixels are ordered from the msb to the lsb
    static var monoblack: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_MONOBLACK) }
    ///< 8 bits with AV_PIX_FMT_RGB32 palette
    static var pal8: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_PAL8) }
    ///< planar YUV 4:2:0, 12bpp, full scale (JPEG), deprecated in favor of AV_PIX_FMT_YUV420P and setting color_range
    static var yuvj420p: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVJ420P) }
    ///< planar YUV 4:2:2, 16bpp, full scale (JPEG), deprecated in favor of AV_PIX_FMT_YUV422P and setting color_range
    static var yuvj422p: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVJ422P) }
    ///< planar YUV 4:4:4, 24bpp, full scale (JPEG), deprecated in favor of AV_PIX_FMT_YUV444P and setting color_range
    static var yuvj444p: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVJ444P) }
    ///< packed YUV 4:2:2, 16bpp, Cb Y0 Cr Y1
    static var uyvy422: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_UYVY422) }
    ///< packed YUV 4:1:1, 12bpp, Cb Y0 Y1 Cr Y2 Y3
    static var uyyvyy411: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_UYYVYY411) }
    ///< packed RGB 3:3:2,  8bpp, (msb)2B 3G 3R(lsb)
    static var bgr8: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BGR8) }
    ///< packed RGB 1:2:1 bitstream,  4bpp, (msb)1B 2G 1R(lsb), a byte contains two pixels, the first pixel in the byte is the one composed by the 4 msb bits
    static var bgr4: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BGR4) }
    ///< packed RGB 1:2:1,  8bpp, (msb)1B 2G 1R(lsb)
    static var bgr4_byte: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BGR4_BYTE) }
    ///< packed RGB 3:3:2,  8bpp, (msb)2R 3G 3B(lsb)
    static var rgb8: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_RGB8) }
    ///< packed RGB 1:2:1 bitstream,  4bpp, (msb)1R 2G 1B(lsb), a byte contains two pixels, the first pixel in the byte is the one composed by the 4 msb bits
    static var rgb4: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_RGB4) }
    ///< packed RGB 1:2:1,  8bpp, (msb)1R 2G 1B(lsb)
    static var rgb4_byte: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_RGB4_BYTE) }
    ///< planar YUV 4:2:0, 12bpp, 1 plane for Y and 1 plane for the UV components, which are interleaved (first byte U and the following byte V)
    static var nv12: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_NV12) }
    ///< as above, but U and V bytes are swapped
    static var nv21: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_NV21) }
    ///< packed ARGB 8:8:8:8, 32bpp, ARGBARGB...
    static var argb: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_ARGB) }
    ///< packed RGBA 8:8:8:8, 32bpp, RGBARGBA...
    static var rgba: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_RGBA) }
    ///< packed ABGR 8:8:8:8, 32bpp, ABGRABGR...
    static var abgr: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_ABGR) }
    ///< packed BGRA 8:8:8:8, 32bpp, BGRABGRA...
    static var bgra: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BGRA) }
    ///<        Y        , 16bpp, big-endian
    static var gray16be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GRAY16BE) }
    ///<        Y        , 16bpp, little-endian
    static var gray16le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GRAY16LE) }
    ///< planar YUV 4:4:0 (1 Cr & Cb sample per 1x2 Y samples)
    static var yuv440p: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV440P) }
    ///< planar YUV 4:4:0 full scale (JPEG), deprecated in favor of AV_PIX_FMT_YUV440P and setting color_range
    static var yuvj440p: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVJ440P) }
    ///< planar YUV 4:2:0, 20bpp, (1 Cr & Cb sample per 2x2 Y & A samples)
    static var yuva420p: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVA420P) }
    ///< packed RGB 16:16:16, 48bpp, 16R, 16G, 16B, the 2-byte value for each R/G/B component is stored as big-endian
    static var rgb48be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_RGB48BE) }
    ///< packed RGB 16:16:16, 48bpp, 16R, 16G, 16B, the 2-byte value for each R/G/B component is stored as little-endian
    static var rgb48le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_RGB48LE) }
    ///< packed RGB 5:6:5, 16bpp, (msb)   5R 6G 5B(lsb), big-endian
    static var rgb565be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_RGB565BE) }
    ///< packed RGB 5:6:5, 16bpp, (msb)   5R 6G 5B(lsb), little-endian
    static var rgb565le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_RGB565LE) }
    ///< packed RGB 5:5:5, 16bpp, (msb)1X 5R 5G 5B(lsb), big-endian   , X=unused/undefined
    static var rgb555be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_RGB555BE) }
    ///< packed RGB 5:5:5, 16bpp, (msb)1X 5R 5G 5B(lsb), little-endian, X=unused/undefined
    static var rgb555le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_RGB555LE) }
    ///< packed BGR 5:6:5, 16bpp, (msb)   5B 6G 5R(lsb), big-endian
    static var bgr565be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BGR565BE) }
    ///< packed BGR 5:6:5, 16bpp, (msb)   5B 6G 5R(lsb), little-endian
    static var bgr565le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BGR565LE) }
    ///< packed BGR 5:5:5, 16bpp, (msb)1X 5B 5G 5R(lsb), big-endian   , X=unused/undefined
    static var bgr555be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BGR555BE) }
    ///< packed BGR 5:5:5, 16bpp, (msb)1X 5B 5G 5R(lsb), little-endian, X=unused/undefined
    static var bgr555le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BGR555LE) }
    
    /** @name Deprecated pixel formats */
    /**@{*/
    ///< HW acceleration through VA API at motion compensation entry-point, Picture.data[3] contains a vaapi_render_state struct which contains macroblocks as well as various fields extracted from headers
    static var vaapi_moco: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_VAAPI_MOCO) }
    ///< HW acceleration through VA API at IDCT entry-point, Picture.data[3] contains a vaapi_render_state struct which contains fields extracted from headers
    static var vaapi_idct: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_VAAPI_IDCT) }
    ///< HW decoding through VA API, Picture.data[3] contains a VASurfaceID
    static var vaapi_vld: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_VAAPI_VLD) }
    /**@}*/
    static var vaapi: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_VAAPI) }
    
    /**
     *  Hardware acceleration through VA-API, data[3] contains a
     *  VASurfaceID.
     */
    
    ///< planar YUV 4:2:0, 24bpp, (1 Cr & Cb sample per 2x2 Y samples), little-endian
    static var yuv420p16le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV420P16LE) }
    ///< planar YUV 4:2:0, 24bpp, (1 Cr & Cb sample per 2x2 Y samples), big-endian
    static var yuv420p16be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV420P16BE) }
    ///< planar YUV 4:2:2, 32bpp, (1 Cr & Cb sample per 2x1 Y samples), little-endian
    static var yuv422p16le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV422P16LE) }
    ///< planar YUV 4:2:2, 32bpp, (1 Cr & Cb sample per 2x1 Y samples), big-endian
    static var yuv422p16be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV422P16BE) }
    ///< planar YUV 4:4:4, 48bpp, (1 Cr & Cb sample per 1x1 Y samples), little-endian
    static var yuv444p16le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV444P16LE) }
    ///< planar YUV 4:4:4, 48bpp, (1 Cr & Cb sample per 1x1 Y samples), big-endian
    static var yuv444p16be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV444P16BE) }
    ///< HW decoding through DXVA2, Picture.data[3] contains a LPDIRECT3DSURFACE9 pointer
    static var dxva2_vld: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_DXVA2_VLD) }
    
    ///< packed RGB 4:4:4, 16bpp, (msb)4X 4R 4G 4B(lsb), little-endian, X=unused/undefined
    static var rgb444le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_RGB444LE) }
    ///< packed RGB 4:4:4, 16bpp, (msb)4X 4R 4G 4B(lsb), big-endian,    X=unused/undefined
    static var rgb444be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_RGB444BE) }
    ///< packed BGR 4:4:4, 16bpp, (msb)4X 4B 4G 4R(lsb), little-endian, X=unused/undefined
    static var bgr444le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BGR444LE) }
    ///< packed BGR 4:4:4, 16bpp, (msb)4X 4B 4G 4R(lsb), big-endian,    X=unused/undefined
    static var bgr444be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BGR444BE) }
    ///< 8 bits gray, 8 bits alpha
    static var ya8: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YA8) }
    
    ///< alias for AV_PIX_FMT_YA8
    static var y400a: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_Y400A) }
    ///< alias for AV_PIX_FMT_YA8
    static var gray8a: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GRAY8A) }
    
    ///< packed RGB 16:16:16, 48bpp, 16B, 16G, 16R, the 2-byte value for each R/G/B component is stored as big-endian
    static var bgr48be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BGR48BE) }
    ///< packed RGB 16:16:16, 48bpp, 16B, 16G, 16R, the 2-byte value for each R/G/B component is stored as little-endian
    static var bgr48le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BGR48LE) }
    
    /**
     * The following 12 formats have the disadvantage of needing 1 format for each bit depth.
     * Notice that each 9/10 bits sample is stored in 16 bits with extra padding.
     * If you want to support multiple bit depths, then using AV_PIX_FMT_YUV420P16* with the bpp stored separately is better.
     */
    ///< planar YUV 4:2:0, 13.5bpp, (1 Cr & Cb sample per 2x2 Y samples), big-endian
    static var yuv420p9be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV420P9BE) }
    ///< planar YUV 4:2:0, 13.5bpp, (1 Cr & Cb sample per 2x2 Y samples), little-endian
    static var yuv420p9le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV420P9LE) }
    ///< planar YUV 4:2:0, 15bpp, (1 Cr & Cb sample per 2x2 Y samples), big-endian
    static var yuv420p10be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV420P10BE) }
    ///< planar YUV 4:2:0, 15bpp, (1 Cr & Cb sample per 2x2 Y samples), little-endian
    static var yuv420p10le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV420P10LE) }
    ///< planar YUV 4:2:2, 20bpp, (1 Cr & Cb sample per 2x1 Y samples), big-endian
    static var yuv422p10be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV422P10BE) }
    ///< planar YUV 4:2:2, 20bpp, (1 Cr & Cb sample per 2x1 Y samples), little-endian
    static var yuv422p10le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV422P10LE) }
    ///< planar YUV 4:4:4, 27bpp, (1 Cr & Cb sample per 1x1 Y samples), big-endian
    static var yuv444p9be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV444P9BE) }
    ///< planar YUV 4:4:4, 27bpp, (1 Cr & Cb sample per 1x1 Y samples), little-endian
    static var yuv444p9le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV444P9LE) }
    ///< planar YUV 4:4:4, 30bpp, (1 Cr & Cb sample per 1x1 Y samples), big-endian
    static var yuv444p10be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV444P10BE) }
    ///< planar YUV 4:4:4, 30bpp, (1 Cr & Cb sample per 1x1 Y samples), little-endian
    static var yuv444p10le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV444P10LE) }
    ///< planar YUV 4:2:2, 18bpp, (1 Cr & Cb sample per 2x1 Y samples), big-endian
    static var yuv422p9be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV422P9BE) }
    ///< planar YUV 4:2:2, 18bpp, (1 Cr & Cb sample per 2x1 Y samples), little-endian
    static var yuv422p9le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV422P9LE) }
    ///< planar GBR 4:4:4 24bpp
    static var gbrp: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBRP) }
    static var gbr24p: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBR24P) }
    ///< planar GBR 4:4:4 27bpp, big-endian
    static var gbrp9be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBRP9BE) }
    ///< planar GBR 4:4:4 27bpp, little-endian
    static var gbrp9le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBRP9LE) }
    ///< planar GBR 4:4:4 30bpp, big-endian
    static var gbrp10be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBRP10BE) }
    ///< planar GBR 4:4:4 30bpp, little-endian
    static var gbrp10le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBRP10LE) }
    ///< planar GBR 4:4:4 48bpp, big-endian
    static var gbrp16be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBRP16BE) }
    ///< planar GBR 4:4:4 48bpp, little-endian
    static var gbrp16le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBRP16LE) }
    ///< planar YUV 4:2:2 24bpp, (1 Cr & Cb sample per 2x1 Y & A samples)
    static var yuva422p: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVA422P) }
    ///< planar YUV 4:4:4 32bpp, (1 Cr & Cb sample per 1x1 Y & A samples)
    static var yuva444p: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVA444P) }
    ///< planar YUV 4:2:0 22.5bpp, (1 Cr & Cb sample per 2x2 Y & A samples), big-endian
    static var yuva420p9be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVA420P9BE) }
    ///< planar YUV 4:2:0 22.5bpp, (1 Cr & Cb sample per 2x2 Y & A samples), little-endian
    static var yuva420p9le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVA420P9LE) }
    ///< planar YUV 4:2:2 27bpp, (1 Cr & Cb sample per 2x1 Y & A samples), big-endian
    static var yuva422p9be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVA422P9BE) }
    ///< planar YUV 4:2:2 27bpp, (1 Cr & Cb sample per 2x1 Y & A samples), little-endian
    static var yuva422p9le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVA422P9LE) }
    ///< planar YUV 4:4:4 36bpp, (1 Cr & Cb sample per 1x1 Y & A samples), big-endian
    static var yuva444p9be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVA444P9BE) }
    ///< planar YUV 4:4:4 36bpp, (1 Cr & Cb sample per 1x1 Y & A samples), little-endian
    static var yuva444p9le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVA444P9LE) }
    ///< planar YUV 4:2:0 25bpp, (1 Cr & Cb sample per 2x2 Y & A samples, big-endian)
    static var yuva420p10be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVA420P10BE) }
    ///< planar YUV 4:2:0 25bpp, (1 Cr & Cb sample per 2x2 Y & A samples, little-endian)
    static var yuva420p10le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVA420P10LE) }
    ///< planar YUV 4:2:2 30bpp, (1 Cr & Cb sample per 2x1 Y & A samples, big-endian)
    static var yuva422p10be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVA422P10BE) }
    ///< planar YUV 4:2:2 30bpp, (1 Cr & Cb sample per 2x1 Y & A samples, little-endian)
    static var yuva422p10le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVA422P10LE) }
    ///< planar YUV 4:4:4 40bpp, (1 Cr & Cb sample per 1x1 Y & A samples, big-endian)
    static var yuva444p10be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVA444P10BE) }
    ///< planar YUV 4:4:4 40bpp, (1 Cr & Cb sample per 1x1 Y & A samples, little-endian)
    static var yuva444p10le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVA444P10LE) }
    ///< planar YUV 4:2:0 40bpp, (1 Cr & Cb sample per 2x2 Y & A samples, big-endian)
    static var yuva420p16be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVA420P16BE) }
    ///< planar YUV 4:2:0 40bpp, (1 Cr & Cb sample per 2x2 Y & A samples, little-endian)
    static var yuva420p16le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVA420P16LE) }
    ///< planar YUV 4:2:2 48bpp, (1 Cr & Cb sample per 2x1 Y & A samples, big-endian)
    static var yuva422p16be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVA422P16BE) }
    ///< planar YUV 4:2:2 48bpp, (1 Cr & Cb sample per 2x1 Y & A samples, little-endian)
    static var yuva422p16le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVA422P16LE) }
    ///< planar YUV 4:4:4 64bpp, (1 Cr & Cb sample per 1x1 Y & A samples, big-endian)
    static var yuva444p16be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVA444P16BE) }
    ///< planar YUV 4:4:4 64bpp, (1 Cr & Cb sample per 1x1 Y & A samples, little-endian)
    static var yuva444p16le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVA444P16LE) }
    
    ///< HW acceleration through VDPAU, Picture.data[3] contains a VdpVideoSurface
    static var vdpau: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_VDPAU) }
    
    ///< packed XYZ 4:4:4, 36 bpp, (msb) 12X, 12Y, 12Z (lsb), the 2-byte value for each X/Y/Z is stored as little-endian, the 4 lower bits are set to 0
    static var xyz12le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_XYZ12LE) }
    ///< packed XYZ 4:4:4, 36 bpp, (msb) 12X, 12Y, 12Z (lsb), the 2-byte value for each X/Y/Z is stored as big-endian, the 4 lower bits are set to 0
    static var xyz12be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_XYZ12BE) }
    ///< interleaved chroma YUV 4:2:2, 16bpp, (1 Cr & Cb sample per 2x1 Y samples)
    static var nv16: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_NV16) }
    ///< interleaved chroma YUV 4:2:2, 20bpp, (1 Cr & Cb sample per 2x1 Y samples), little-endian
    static var nv20le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_NV20LE) }
    ///< interleaved chroma YUV 4:2:2, 20bpp, (1 Cr & Cb sample per 2x1 Y samples), big-endian
    static var nv20be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_NV20BE) }
    
    ///< packed RGBA 16:16:16:16, 64bpp, 16R, 16G, 16B, 16A, the 2-byte value for each R/G/B/A component is stored as big-endian
    static var rgba64be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_RGBA64BE) }
    ///< packed RGBA 16:16:16:16, 64bpp, 16R, 16G, 16B, 16A, the 2-byte value for each R/G/B/A component is stored as little-endian
    static var rgba64le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_RGBA64LE) }
    ///< packed RGBA 16:16:16:16, 64bpp, 16B, 16G, 16R, 16A, the 2-byte value for each R/G/B/A component is stored as big-endian
    static var bgra64be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BGRA64BE) }
    ///< packed RGBA 16:16:16:16, 64bpp, 16B, 16G, 16R, 16A, the 2-byte value for each R/G/B/A component is stored as little-endian
    static var bgra64le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BGRA64LE) }
    
    ///< packed YUV 4:2:2, 16bpp, Y0 Cr Y1 Cb
    static var yvyu422: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YVYU422) }
    
    ///< 16 bits gray, 16 bits alpha (big-endian)
    static var ya16be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YA16BE) }
    ///< 16 bits gray, 16 bits alpha (little-endian)
    static var ya16le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YA16LE) }
    
    ///< planar GBRA 4:4:4:4 32bpp
    static var gbrap: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBRAP) }
    ///< planar GBRA 4:4:4:4 64bpp, big-endian
    static var gbrap16be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBRAP16BE) }
    ///< planar GBRA 4:4:4:4 64bpp, little-endian
    static var gbrap16le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBRAP16LE) }
    /**
     *  HW acceleration through QSV, data[3] contains a pointer to the
     *  mfxFrameSurface1 structure.
     */
    static var qsv: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_QSV) }
    /**
     * HW acceleration though MMAL, data[3] contains a pointer to the
     * MMAL_BUFFER_HEADER_T structure.
     */
    static var mmal: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_MMAL) }
    
    ///< HW decoding through Direct3D11 via old API, Picture.data[3] contains a ID3D11VideoDecoderOutputView pointer
    static var d3d11va_vld: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_D3D11VA_VLD) }
    
    /**
     * HW acceleration through CUDA. data[i] contain CUdeviceptr pointers
     * exactly as for system memory frames.
     */
    static var cuda: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_CUDA) }
    
    ///< packed RGB 8:8:8, 32bpp, XRGBXRGB...   X=unused/undefined
    static var k0rgb: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_0RGB) }
    ///< packed RGB 8:8:8, 32bpp, RGBXRGBX...   X=unused/undefined
    static var rgb0: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_RGB0) }
    ///< packed BGR 8:8:8, 32bpp, XBGRXBGR...   X=unused/undefined
    static var k0bgr: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_0BGR) }
    ///< packed BGR 8:8:8, 32bpp, BGRXBGRX...   X=unused/undefined
    static var bgr0: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BGR0) }
    
    ///< planar YUV 4:2:0,18bpp, (1 Cr & Cb sample per 2x2 Y samples), big-endian
    static var yuv420p12be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV420P12BE) }
    ///< planar YUV 4:2:0,18bpp, (1 Cr & Cb sample per 2x2 Y samples), little-endian
    static var yuv420p12le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV420P12LE) }
    ///< planar YUV 4:2:0,21bpp, (1 Cr & Cb sample per 2x2 Y samples), big-endian
    static var yuv420p14be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV420P14BE) }
    ///< planar YUV 4:2:0,21bpp, (1 Cr & Cb sample per 2x2 Y samples), little-endian
    static var yuv420p14le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV420P14LE) }
    ///< planar YUV 4:2:2,24bpp, (1 Cr & Cb sample per 2x1 Y samples), big-endian
    static var yuv422p12be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV422P12BE) }
    ///< planar YUV 4:2:2,24bpp, (1 Cr & Cb sample per 2x1 Y samples), little-endian
    static var yuv422p12le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV422P12LE) }
    ///< planar YUV 4:2:2,28bpp, (1 Cr & Cb sample per 2x1 Y samples), big-endian
    static var yuv422p14be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV422P14BE) }
    ///< planar YUV 4:2:2,28bpp, (1 Cr & Cb sample per 2x1 Y samples), little-endian
    static var yuv422p14le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV422P14LE) }
    ///< planar YUV 4:4:4,36bpp, (1 Cr & Cb sample per 1x1 Y samples), big-endian
    static var yuv444p12be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV444P12BE) }
    ///< planar YUV 4:4:4,36bpp, (1 Cr & Cb sample per 1x1 Y samples), little-endian
    static var yuv444p12le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV444P12LE) }
    ///< planar YUV 4:4:4,42bpp, (1 Cr & Cb sample per 1x1 Y samples), big-endian
    static var yuv444p14be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV444P14BE) }
    ///< planar YUV 4:4:4,42bpp, (1 Cr & Cb sample per 1x1 Y samples), little-endian
    static var yuv444p14le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV444P14LE) }
    ///< planar GBR 4:4:4 36bpp, big-endian
    static var gbrp12be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBRP12BE) }
    ///< planar GBR 4:4:4 36bpp, little-endian
    static var gbrp12le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBRP12LE) }
    ///< planar GBR 4:4:4 42bpp, big-endian
    static var gbrp14be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBRP14BE) }
    ///< planar GBR 4:4:4 42bpp, little-endian
    static var gbrp14le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBRP14LE) }
    ///< planar YUV 4:1:1, 12bpp, (1 Cr & Cb sample per 4x1 Y samples) full scale (JPEG), deprecated in favor of AV_PIX_FMT_YUV411P and setting color_range
    static var yuvj411p: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUVJ411P) }
    
    ///< bayer, BGBG..(odd line), GRGR..(even line), 8-bit samples */
    static var bayer_bggr8: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BAYER_BGGR8) }
    ///< bayer, RGRG..(odd line), GBGB..(even line), 8-bit samples */
    static var bayer_rggb8: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BAYER_RGGB8) }
    ///< bayer, GBGB..(odd line), RGRG..(even line), 8-bit samples */
    static var bayer_gbrg8: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BAYER_GBRG8) }
    ///< bayer, GRGR..(odd line), BGBG..(even line), 8-bit samples */
    static var bayer_grbg8: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BAYER_GRBG8) }
    ///< bayer, BGBG..(odd line), GRGR..(even line), 16-bit samples, little-endian */
    static var bayer_bggr16le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BAYER_BGGR16LE) }
    ///< bayer, BGBG..(odd line), GRGR..(even line), 16-bit samples, big-endian */
    static var bayer_bggr16be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BAYER_BGGR16BE) }
    ///< bayer, RGRG..(odd line), GBGB..(even line), 16-bit samples, little-endian */
    static var bayer_rggb16le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BAYER_RGGB16LE) }
    ///< bayer, RGRG..(odd line), GBGB..(even line), 16-bit samples, big-endian */
    static var bayer_rggb16be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BAYER_RGGB16BE) }
    ///< bayer, GBGB..(odd line), RGRG..(even line), 16-bit samples, little-endian */
    static var bayer_gbrg16le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BAYER_GBRG16LE) }
    ///< bayer, GBGB..(odd line), RGRG..(even line), 16-bit samples, big-endian */
    static var bayer_gbrg16be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BAYER_GBRG16BE) }
    ///< bayer, GRGR..(odd line), BGBG..(even line), 16-bit samples, little-endian */
    static var bayer_grbg16le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BAYER_GRBG16LE) }
    ///< bayer, GRGR..(odd line), BGBG..(even line), 16-bit samples, big-endian */
    static var bayer_grbg16be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_BAYER_GRBG16BE) }
    
    ///< XVideo Motion Acceleration via common packet passing
    static var xvmc: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_XVMC) }
    
    ///< planar YUV 4:4:0,20bpp, (1 Cr & Cb sample per 1x2 Y samples), little-endian
    static var yuv440p10le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV440P10LE) }
    ///< planar YUV 4:4:0,20bpp, (1 Cr & Cb sample per 1x2 Y samples), big-endian
    static var yuv440p10be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV440P10BE) }
    ///< planar YUV 4:4:0,24bpp, (1 Cr & Cb sample per 1x2 Y samples), little-endian
    static var yuv440p12le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV440P12LE) }
    ///< planar YUV 4:4:0,24bpp, (1 Cr & Cb sample per 1x2 Y samples), big-endian
    static var yuv440p12be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_YUV440P12BE) }
    ///< packed AYUV 4:4:4,64bpp (1 Cr & Cb sample per 1x1 Y & A samples), little-endian
    static var ayuv64le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_AYUV64LE) }
    ///< packed AYUV 4:4:4,64bpp (1 Cr & Cb sample per 1x1 Y & A samples), big-endian
    static var ayuv64be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_AYUV64BE) }
    
    ///< hardware decoding through Videotoolbox
    static var videotoolbox: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_VIDEOTOOLBOX) }
    
    ///< like NV12, with 10bpp per component, data in the high bits, zeros in the low bits, little-endian
    static var p010le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_P010LE) }
    ///< like NV12, with 10bpp per component, data in the high bits, zeros in the low bits, big-endian
    static var p010be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_P010BE) }
    
    ///< planar GBR 4:4:4:4 48bpp, big-endian
    static var gbrap12be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBRAP12BE) }
    ///< planar GBR 4:4:4:4 48bpp, little-endian
    static var gbrap12le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBRAP12LE) }
    
    ///< planar GBR 4:4:4:4 40bpp, big-endian
    static var gbrap10be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBRAP10BE) }
    ///< planar GBR 4:4:4:4 40bpp, little-endian
    static var gbrap10le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBRAP10LE) }
    
    ///< hardware decoding through MediaCodec
    static var mediacodec: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_MEDIACODEC) }
    
    ///<        Y        , 12bpp, big-endian
    static var gray12be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GRAY12BE) }
    ///<        Y        , 12bpp, little-endian
    static var gray12le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GRAY12LE) }
    ///<        Y        , 10bpp, big-endian
    static var gray10be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GRAY10BE) }
    ///<        Y        , 10bpp, little-endian
    static var gray10le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GRAY10LE) }
    
    ///< like NV12, with 16bpp per component, little-endian
    static var p016le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_P016LE) }
    ///< like NV12, with 16bpp per component, big-endian
    static var p016be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_P016BE) }
    
    /**
     * Hardware surfaces for Direct3D11.
     *
     * This is preferred over the legacy AV_PIX_FMT_D3D11VA_VLD. The new D3D11
     * hwaccel API and filtering support AV_PIX_FMT_D3D11 only.
     *
     * data[0] contains a ID3D11Texture2D pointer, and data[1] contains the
     * texture array index of the frame as intptr_t if the ID3D11Texture2D is
     * an array texture (or always 0 if it's a normal texture).
     */
    static var d3d11: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_D3D11) }
    
    ///<        Y        , 9bpp, big-endian
    static var gray9be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GRAY9BE) }
    ///<        Y        , 9bpp, little-endian
    static var gray9le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GRAY9LE) }
    
    ///< IEEE-754 single precision planar GBR 4:4:4,     96bpp, big-endian
    static var gbrpf32be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBRPF32BE) }
    ///< IEEE-754 single precision planar GBR 4:4:4,     96bpp, little-endian
    static var gbrpf32le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBRPF32LE) }
    ///< IEEE-754 single precision planar GBRA 4:4:4:4, 128bpp, big-endian
    static var gbrapf32be: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBRAPF32BE) }
    ///< IEEE-754 single precision planar GBRA 4:4:4:4, 128bpp, little-endian
    static var gbrapf32le: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_GBRAPF32LE) }
    
    /**
     * DRM-managed buffers exposed through PRIME buffer sharing.
     *
     * data[0] points to an AVDRMFrameDescriptor.
     */
    static var drm_prime: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_DRM_PRIME) }
    /**
     * Hardware surfaces for OpenCL.
     *
     * data[i] contain 2D image objects (typed in C as cl_mem, used
     * in OpenCL as image2d_t) for each plane of the surface.
     */
    static var opencl: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_OPENCL) }
    
    ///< number of pixel formats, DO NOT USE THIS if you want to link with shared libav* because the number of formats might differ between versions
    static var nb: FFmpegPixelFormat { return .init(rawValue: AV_PIX_FMT_NB) }
}
