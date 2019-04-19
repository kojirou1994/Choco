//
//  functions.swift
//  SwiftFFmpeg-Demo
//
//  Created by Kojirou on 2019/4/17.
//

import Foundation
import SwiftFFmpeg

func demuxAudio(input: String) throws {
    let audioOutput = input.appending(".ac3")
    let inF = try FFmpegInputFormatContext.init(url: input)
    try inF.findStreamInfo()
    inF.dumpFormat()
    let audioStream = inF.streams[1]
    let decoder = try FFmpegCodec.init(decoderId: audioStream.codecParameters.codecId)
    print("decoder: \(decoder)")
    let codecContext = try FFmpegCodecContext.init(codec: decoder)
    try codecContext.set(parameter: audioStream.codecParameters)
    try codecContext.openCodec(options: ["refcounted_frames": "1"])
    let audioIndex = 1
    guard let audioOutputFile = fopen(audioOutput, "wb") else {
        fatalError("Could not open \(audioOutput)")
    }
    defer {
        fclose(audioOutputFile)
    }
    
    let frame = try FFmpegFrame.init()
    let pkt = try FFmpegPacket.init()
    
    while let _ = try? inF.readFrame(into: pkt) {
        if pkt.streamIndex == audioIndex {
            try codecContext.send(packet: pkt)
            
            while true {
                do {
                    try codecContext.receive(frame: frame)
                } catch let err as FFmpegError where err == .EAGAIN || err == .EOF {
                    break
                }
                
                let unpaddedLineSize = Int(frame.sampleCount) * frame.sampleFmt.bytesPerSample
                fwrite(frame.extendedData[0], 1, unpaddedLineSize, audioOutputFile)
                
                print("audio frame: \(codecContext.frameNumber)")
                
                frame.unref()
            }
        }
    }
    try codecContext.send(packet: pkt)
    
    while true {
        do {
            try codecContext.receive(frame: frame)
        } catch let err as FFmpegError {
            if err == .EAGAIN || err == .EOF {
                break
            } else {
                fatalError("\(err)")
            }
        }
        
        let unpaddedLineSize = Int(frame.sampleCount) * frame.sampleFmt.bytesPerSample
        fwrite(frame.extendedData[0], 1, unpaddedLineSize, audioOutputFile)
        
        print("audio frame: \(codecContext.frameNumber)")
        
        frame.unref()
    }
    print("Demuxing succeeded.")
}

func metadata(input: String) throws {
    let fmt = try FFmpegInputFormatContext.init(url: input)
    fmt.metadata.dictionary.forEach { (v) in
        print("\(v.key)=\(v.value)")
    }
}

func remuxing(input: String) throws {
    let ofmt: FFmpegOutputFormat
    let ifmtCtx: FFmpegInputFormatContext
    let ofmtCtx: FFmpegOutputFormatContext
    
    let outFilename = input.appending("_remux.mp4")
    var streamIndex: Int32 = 0
    var streamMappingSize: Int32 = 0
    ifmtCtx = try .init(url: input)
    try ifmtCtx.findStreamInfo()
    ifmtCtx.dumpFormat()
    ofmtCtx = try .init(outputFormat: nil, formatName: nil, filename: outFilename)
    streamMappingSize = Int32(Int(ifmtCtx.streamCount))
    var streamMapping = [Int32].init(repeating: 0, count: Int(streamMappingSize))
    ofmt = ofmtCtx.outputFormat
    for i in 0..<Int(ifmtCtx.streamCount) {
        let inStream = ifmtCtx.stream(at: i)
        let codecpar = inStream.codecParameters
        
        switch codecpar.codecType {
        case .video, .audio, .subtitle:
            break
        default:
            streamMapping[i] = -1
            continue
        }
        
        streamMapping[i] = streamIndex
        streamIndex += 1
        
        let outStream = try ofmtCtx.addStream(codec: nil)
        try outStream.set(codecParameters: codecpar)
        outStream.codecParameters.codecTag = 0
    }
    print("dump output info\n==================")
    ofmtCtx.dumpFormat()
    
    if !ofmt.flags.contains(.noFile) {
        try ofmtCtx.openOutput(filename: outFilename)
    }
    
    try ofmtCtx.writeHeader()
    
    let pkt = try FFmpegPacket.init()
    
    while true {
        do {
            try ifmtCtx.readFrame(into: pkt)
        } catch {
            print(error)
            break
        }
        
        let inStream = ifmtCtx.stream(at: Int(pkt.streamIndex))
        if pkt.streamIndex >= streamMappingSize ||
            streamMapping[Int(pkt.streamIndex)] < 0 {
            pkt.unref()
            continue
        }
        
        pkt.streamIndex = streamMapping[Int(pkt.streamIndex)]
        let outStream = ofmtCtx.stream(at: Int(pkt.streamIndex))
        ifmtCtx.logPacket(packet: pkt, tag: "in")
        
        /// copy packet
        pkt.pts = FFmpegRescale.rescale_q_rnd(pkt.pts, inStream.timebase, outStream.timebase, [.nearInf, .passMinmax])
        pkt.dts = FFmpegRescale.rescale_q_rnd(pkt.dts, inStream.timebase, outStream.timebase, [.nearInf, .passMinmax])
        pkt.duration = FFmpegRescale.rescale_q(pkt.duration, inStream.timebase, outStream.timebase)
        pkt.position = -1
        
        
        ofmtCtx.logPacket(packet: pkt, tag: "out")
        
        do {
            try ofmtCtx.interleavedWriteFrame(pkt: pkt)
        } catch {
            print("Error muxing packet: \(error)")
            break
        }
        pkt.unref()
        
    }
    
    try ofmtCtx.writeTrailer()
}

extension FFmpegFormatContext {
    
    func logPacket(packet: FFmpegPacket, tag: String) {
        let timeBase = stream(at: Int(packet.streamIndex)).timebase
        print("\(tag): pts:\(FFmpegTimestamp.ts2str(timestamp: packet.pts)), ptsTime: \(FFmpegTimestamp.av_ts2timestr(timestamp: packet.pts, timebase: timeBase)), dts: \(FFmpegTimestamp.ts2str(timestamp: packet.dts)), dtsTime: \(FFmpegTimestamp.av_ts2timestr(timestamp: packet.dts, timebase: timeBase)), duration: \(FFmpegTimestamp.ts2str(timestamp: packet.duration)), durationTime: \(FFmpegTimestamp.av_ts2timestr(timestamp: packet.duration, timebase: timeBase)), streamIndex: \(packet.streamIndex)")
    }
    
}
