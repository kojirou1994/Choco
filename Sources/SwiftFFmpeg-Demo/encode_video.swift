//
//  encode_video.swift
//  SwiftFFmpeg-Demo
//
//  Created by Kojirou on 2019/4/17.
//

import Foundation
import SwiftFFmpeg

func encode(enc_ctx: FFmpegCodecContext, frame: FFmpegFrame?,
            pkt: FFmpegPacket, outfile: FileHandle) throws {
    if frame != nil {
        print("Send frame \(frame!.pts)")
    }
    
    try enc_ctx.send(frame: frame)
    while true {
        do {
            try enc_ctx.receive(packet: pkt)
        } catch let error as FFmpegError {
            if error == .EAGAIN || error == .EOF {
                return
            } else {
                print("Error during encoding")
                exit(1)
            }
        }
        print("Write packed \(pkt.pts) (size=\(pkt.size)")
        outfile.write(.init(bytesNoCopy: UnsafeMutableRawPointer.init(pkt.data!), count: Int(pkt.size), deallocator: .none))
        pkt.unref()
    }
}

func encode_video(filename: String) throws {
    let codec = try FFmpegCodec.init(encoderId: .h264)
    let c = try FFmpegCodecContext.init(codec: codec)
    let pkt = try FFmpegPacket.init()
    
    c.bitRate = 400_000
    c.width = 352
    c.height = 288
    // fps
    c.timebase = .init(num: 1, den: 25)
    c.framerate = .init(num: 25, den: 1)
    
    c.gopSize = 10
    c.maxBFrames = 1
    c.pixelFormat = .yuv420p10le
    
    if codec.id == .h264 {
         c.setOption(key: "preset", value: "slow")
    }
    
    // open it
    try c.openCodec()
    
    FileManager.default.createFile(atPath: filename, contents: nil, attributes: nil)
    let filehandle = FileHandle.init(forWritingAtPath: filename)!
    
    let frame = try FFmpegFrame.init()
    frame.pixelFormat = c.pixelFormat
    frame.width = c.width
    frame.height = c.height
    
    try frame.getBuffer(align: 32)
    
    for i in 0..<250 {
        fflush(stdout)
        
        try frame.makeWritable()
        
        for y in 0..<c.height {
            for x in 0..<c.width {
                frame.data.0![Int(y * frame.linesize.0 + x)] = UInt8.init(truncatingIfNeeded: Int(x + y) + i * 3)
            }
        }
        
        for y in 0..<c.height/2 {
            for x in 0..<c.width/2 {
                frame.data.1![Int(y * frame.linesize.1 + x)] = UInt8.init(truncatingIfNeeded: 128 + Int(y) + i * 2)
                frame.data.2![Int(y * frame.linesize.2 + x)] = UInt8.init(truncatingIfNeeded: 64 + Int(x) + i * 5)
            }
        }
        
        frame.pts = Int64(i)
        
        try encode(enc_ctx: c, frame: frame, pkt: pkt, outfile: filehandle)
    }
    
    try encode(enc_ctx: c, frame: nil, pkt: pkt, outfile: filehandle)
    
    filehandle.write(.init([0, 0, 1, 0xb7]))
}
