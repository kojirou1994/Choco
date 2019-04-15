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
try demuxAudio(input: file)
//FFmpegLog.set(level: .quite)
//let context = try FFmpegFormatContext.init(url: file)
//try context.findStreamInfo()
//context.streams.forEach { (stream) in
//    let codecParameters = stream.codecParameters
//    print(codecParameters)
//}
import CFFmpeg
/*
 
if CommandLine.argc < 2 {
    print("Usage: \(CommandLine.arguments[0]) <input file>")
    exit(1)
}

let input = CommandLine.arguments[1]

let fmtCtx = AVFormatContextWrapper()
try fmtCtx.openInput(input)
try fmtCtx.findStreamInfo()

fmtCtx.dumpFormat(isOutput: false)

guard let stream = fmtCtx.videoStream else {
    fatalError("No video stream")
}
guard let codec = AVCodecWrapper.init(decoderId: stream.codecpar.codecId) else {
    fatalError("Codec not found")
}
guard let codecCtx = AVCodecContextWrapper(codec: codec) else {
    fatalError("Could not allocate video codec context.")
}
try codecCtx.setParameters(stream.codecpar)
try codecCtx.openCodec()

let pkt = AVPacketWrapper()
let frame = AVFrameWrapper()

while let _ = try? fmtCtx.readFrame(into: pkt) {
    defer { pkt.unref() }

    if pkt.streamIndex != stream.index {
        continue
    }

    try codecCtx.sendPacket(pkt)

    while true {
        do {
            try codecCtx.receiveFrame(frame)
        } catch let err as AVError where err == .EAGAIN || err == .EOF {
            break
        }

        let str = String(
            format: "Frame %3d (type=%@, size=%5d bytes) pts %4lld key_frame %d [DTS %3lld]",
            codecCtx.frameNumber,
            frame.pictType.description,
            frame.pktSize,
            frame.pts,
            frame.isKeyFrame,
            frame.codedPictureNumber
        )
        print(str)

        frame.unref()
    }
}

print("Done.")

*/
