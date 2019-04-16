import Foundation
import SwiftFFmpeg

//let context = try FFmpegFormatContext.init(url: "/Volumes/GLOWAY/Downloads/New.Years.Concert.2019.BluRay.1080p.DTS-HD.MA.5.1.Flac.x264-beAst.mkv")
//try context.findStreamInfo()
//context.streams.forEach { (stream) in
//    switch stream.mediaType {
//    case .video:
//        dump(stream.codecpar.pixelFormat)
//    case .audio:
//        dump(stream.codecpar.sampleFormat)
//    default:
//        break
//    }
//}
//print(FFmpegCodecID.hevc)
//FFmpegOutputFormat.all.forEach { (o) in
////    print("\(o.mimeType ?? "") \(o.extensions ?? "") \(o.name) \(o.longName) \(o.audioCodec)")
//}
//FFmpegInputFormat.all.forEach { (o) in
//    print("\(o.mimeType ?? "NoMime") \(o.extensions ?? "NoExt") \(o.name) \(o.longName)")
//}

//FFmpegPictureType.allCases.forEach { (t) in
//    dump(t)
//}
//print(FFmpegChannel.frontLeft)

FFmpegLog.set(level: .info)

func demuxAudio(input: String) throws {
    let audioOutput = input.appending(".ac3")
    let inF = try FFmpegFormatContext.init(url: input)
    try inF.findStreamInfo()
    inF.dumpFormat(isOutput: false)
    let audioStream = inF.streams[1]
    let decoder = FFmpegCodec.init(decoderId: audioStream.codecParameters.codecId)!
    print("decoder: \(decoder)")
    let codecContext = FFmpegCodecContext.init(codec: decoder)!
    try codecContext.set(audioStream.codecParameters)
    try codecContext.openCodec(options: ["refcounted_frames": "1"])
    let audioIndex = 1
    guard let audioOutputFile = fopen(audioOutput, "wb") else {
        fatalError("Could not open \(audioOutput)")
    }
    defer {
        fclose(audioOutputFile)
    }
    
    let frame = FFmpegFrame.init()!
    let pkt = FFmpegPacket.init()!
    
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
        } catch let err as FFmpegError/* where err == .tryAgain || err == .eof */{
            break
        }
        
        let unpaddedLineSize = Int(frame.sampleCount) * frame.sampleFmt.bytesPerSample
        fwrite(frame.extendedData[0], 1, unpaddedLineSize, audioOutputFile)
        
        print("audio frame: \(codecContext.frameNumber)")
        
        frame.unref()
    }
    print("Demuxing succeeded.")
}

let file = "/Volumes/GLOWAY/哎不哎都行.mp4"
let file2 = "/Volumes/GLOWAY/01_en.mp4"
//try demuxAudio(input: file)
//FFmpegLog.set(level: .quite)
//let context = try FFmpegFormatContext.init(url: file)
//try context.findStreamInfo()
//context.streams.forEach { (stream) in
//    let codecParameters = stream.codecParameters
//    print(codecParameters)
//}
//let f = try FFmpegFormatContext.init(url: file)
//f.inputFormat?.debug()

//print(FFmpegCodec.init(decoderId: .alac)!)
//print(FFmpegCodec.init(encoderId: .alac)!)
import CFFmpeg
import Kwift

var dic: FFmpegDictionary?

func metadata(input: String) throws {
    let fmt = try FFmpegFormatContext.init(url: input)
    fmt.metadata.dictionary.forEach { (v) in
        print("\(v.key)=\(v.value)")
    }
    dic = fmt.metadata
}

//try metadata(input: file)
//try metadata(input: file2)

func remuxing(input: String) throws {
    let ofmt: FFmpegOutputFormat
    let ifmtCtx: FFmpegFormatContext
    let ofmtCtx: FFmpegFormatContext
    
    let outFilename = input.appending("_remux.mp4")
    var streamIndex: Int32 = 0
    var streamMappingSize: Int32 = 0
    ifmtCtx = try .init(url: input)
    try ifmtCtx.findStreamInfo()
    ifmtCtx.dumpFormat(isOutput: false)
    ofmtCtx = try .outputContext(outputFormat: nil, formatName: nil, filename: outFilename)
    streamMappingSize = Int32(Int(ifmtCtx.streamCount))
    var streamMapping = [Int32].init(repeating: 0, count: Int(streamMappingSize))
    ofmt = ofmtCtx.outputFormat!
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
        
        let outStream = FFmpegStream.init(formatContext: ofmtCtx, codec: nil)!
        try outStream.set(codecParameters: codecpar)
        outStream.codecParameters.codecTag = 0
    }
    print("dump output info\n==================")
    ofmtCtx.dumpFormat(isOutput: true)
    
    if !ofmt.flags.contains(.noFile) {
        try ofmtCtx.openOutput(filename: outFilename)
    }
    
    try ofmtCtx.writeHeader()
    
    let pkt = FFmpegPacket.init()!
    
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
try remuxing(input: file)
//print(AV_CODEC_CAP_INTRA_ONLY.binaryString)
//print(AV_CODEC_CAP_LOSSLESS.binaryString)
//print(AV_CODEC_CAP_HARDWARE.binaryString)
