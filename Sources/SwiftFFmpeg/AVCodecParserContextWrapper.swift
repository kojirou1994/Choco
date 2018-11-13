//
//  AVCodecParserContext.swift
//  SwiftFFmpeg
//
//  Created by sunlubo on 2018/7/1.
//


import CFFmpeg
//internal typealias AVCodecParserContext = CFFmpeg.AVCodecParserContext

public final class AVCodecParserContextWrapper {
    private let codecCtx: AVCodecContextWrapper

    internal let ctxPtr: UnsafeMutablePointer<AVCodecParserContext>
//    internal var ctx: AVCodecParserContext { return ctxPtr.pointee }

    public init(codecCtx: AVCodecContextWrapper) {
        self.codecCtx = codecCtx
        self.ctxPtr = av_parser_init(Int32(codecCtx.codec.id.rawValue))
    }

    /// Parse a packet.
    ///
    /// - Parameters:
    ///   - data: input buffer.
    ///   - size: buffer size in bytes without the padding.
    ///     I.e. the full buffer size is assumed to be buf_size + AV_INPUT_BUFFER_PADDING_SIZE.
    ///     To signal EOF, this should be 0 (so that the last frame can be output).
    ///   - packet: packet
    ///   - pts: input presentation timestamp.
    ///   - dts: input decoding timestamp.
    ///   - pos: input byte position in stream.
    /// - Returns: The number of bytes of the input bitstream used.
    public func parse(
        data: UnsafePointer<UInt8>,
        size: Int,
        packet: AVPacketWrapper,
        pts: Int64 = AV_NOPTS_VALUE,
        dts: Int64 = AV_NOPTS_VALUE,
        pos: Int64 = 0
    ) -> Int {
        var poutbuf: UnsafeMutablePointer<UInt8>?
        var poutbufSize: Int32 = 0
        let ret = av_parser_parse2(ctxPtr, codecCtx.ctxPtr, &poutbuf, &poutbufSize, data, Int32(size), pts, dts, pos)
        packet.packetPtr.pointee.data = poutbuf
        packet.packetPtr.pointee.size = poutbufSize
        return Int(ret)
    }

    deinit {
        av_parser_close(ctxPtr)
    }
}
