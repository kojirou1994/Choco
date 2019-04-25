import Foundation
import CLibbluray
import Common
import MplsReader
/*
 mkv codec
 - "MPEG-4p10/AVC/h.264"
 - "FLAC"
 - "DTS-HD Master Audio"
 - "DTS-HD Master Audio"
 - "HDMV PGS"
 */
//struct PP {
//    let i: Int
//}
//
//func get() -> UnsafePointer<PP> {
//    let p = PP.init(i: 5)
//    return withUnsafePointer(to: p, {print($0);print($0.pointee);return $0})
//}
//

exit(0)
extension MplsPlaylist {
    var m2tsList: [[String]] {
        let angleCount = playItems.max(by: {$0.multiAngle.angleCount < $1.multiAngle.angleCount})!.multiAngle.angleCount + 1
        var result = [[String]]()
        result.reserveCapacity(angleCount)
        for index in 0..<angleCount {
            result.append(playItems.map {$0.clipId(for: index)})
        }
        return result
    }
}

let mpls = try mplsParse(path: "/Users/kojirou/Projects/Remuxer/multi_angle_PLAYLIST/00000.mpls")
let lists = mpls.m2tsList
lists.forEach { print($0.joined(separator: "+")) }
/*
let pcmM2ts = "/Volumes/EXTREME/h264_pcm_pgs.m2ts"
let dtsM2ts = "/Volumes/EXTREME/h264_pcm_dts.m2ts"
let truehdM2ts = "/Volumes/EXTREME/h264_truehd_ac3.m2ts"
let mp4 = "/Users/Kojirou/Downloads/David Okun - From C++ to Swift- Modern Cross-Platform SDKs.mp4"
let lang = "/Volumes/EXTREME/lang.mkv"

#if DEBUG
let input = lang
#else
let input = CommandLine.arguments[1]
#endif
let context = try AVFormatContext.init(url: input)
try context.findStreamInfo()

//context.dumpFormat(isOutput: false)

//var target: [Int: FileHandle] = [:]

extension AVStream {
    
    var language: String {
        return metadata["language"] ?? "und"
    }
    
    var isLosslessAudio: Bool {
        guard mediaType == .audio else {
            return false
        }
        switch codecpar.codecId {
        case AV_CODEC_ID_FLAC, AV_CODEC_ID_ALAC, AV_CODEC_ID_TRUEHD:
            return true
        case AV_CODEC_ID_DTS:
            let codecContext = AVCodecContext.init(codec: AVCodec.findDecoderById(codecpar.codecId)!)!
            try! codecContext.setParameters(codecpar)
            if codecContext.profileName == "DTS-HD MA" {
                return true
            } else {
                return false
            }
        default:
            if codecpar.codecId.name.hasPrefix("pcm") {
                return true
            } else {
                return false
            }
        }
    }
    
}

var arguments = ["-nostdin", "-i", input, "-vn"]

context.streams.forEach { (stream) in
    print("\(stream.index) \(stream.codecpar.codecId.name) \(stream.isLosslessAudio ? "lossless" : "lossy") \(stream.language)")
    if stream.isLosslessAudio {
        arguments.append("-map")
        arguments.append("0:\(stream.index)")
        arguments.append("\(input.deletingPathExtension)-\(stream.index)-\(stream.language).flac")
    }
    //    let codecContext = AVCodecContext.init(codec: AVCodec.findDecoderById(stream.codecpar.codecId)!)!
    //    try! codecContext.setParameters(stream.codecpar)
    //    print(codecContext.str)
    //    print(codecContext.profileName)
    
    //    let output = "/Users/Kojirou/Downloads/ffout/\(stream.index)"
    //    FileManager.default.createFile(atPath: output, contents: nil, attributes: nil)
    //    target[stream.index] = FileHandle.init(forWritingAtPath: output)
}

#if !DEBUG
let p = Process.launchedProcess(launchPath: "/usr/local/bin/ffmpeg", arguments: arguments)
p.waitUntilExit()
#else
print("ffmpeg " + arguments.joined(separator: " "))
#endif

exit(0)

let outputVideo = "/Users/Kojirou/Downloads/ffout1/0.264"
let outputAudio = "/Users/Kojirou/Downloads/ffout1/1.m4a"

let packet = AVPacket.init()

let outputVideoFmtContext = try AVFormatContext.init(format: nil, formatName: nil, filename: outputVideo)
let outputAudioFmtContext = try AVFormatContext.init(format: nil, formatName: nil, filename: outputAudio)

let outputFormatVideo = outputVideoFmtContext.oformat
//let outputFormatAudio = outputVideoFmtContext.oformat
let codec = AVCodecContext.init(codec: AVCodec.findEncoderByName("hevc")!)
codec?.pixFmt = AV_PIX_FMT_YUV444P
context.streams.forEach { (stream) in
    var outputStream: AVStream?
    if stream.mediaType == .video {
        outputStream = outputVideoFmtContext.addStream(codec: AVCodec.findEncoderById(stream.codecpar.codecId))
        try! outputStream?.setParameters(stream.codecpar)
    } else if stream.mediaType == .audio, stream.index == 1 {
        //        outputStream = outputAudioFmtContext.addStream(codec: AVCodec.findEncoderById(stream.codecpar.codecId))
        outputStream = outputAudioFmtContext.addStream(codec: AVCodec.findEncoderById(AV_CODEC_ID_ALAC))
        //        try! outputStream?.setParameters(stream.codecpar)
    }
    if outputStream == nil {
        //        print("Allocating output stream failed.")
    }
    
}

outputVideoFmtContext.dumpFormat(isOutput: true)
outputAudioFmtContext.dumpFormat(isOutput: true)

try outputVideoFmtContext.openIO(url: outputVideo, flags: AVIOFlag.write)
try outputAudioFmtContext.openIO(url: outputAudio, flags: AVIOFlag.write)

try outputVideoFmtContext.writeHeader()
try outputAudioFmtContext.writeHeader()

extension AVFormatContext {
    func readFrameToEnd(_ processing: ((AVPacket) throws -> ())) rethrows {
        let packet = AVPacket.init()
        while true {
            defer {packet.unref()}
            do {
                try readFrame(into: packet)
                try processing(packet)
            } catch {
                print(error)
                break
            }
        }
    }
}

try context.readFrameToEnd { (packet) in
    let inStream = context.streams[packet.streamIndex]
    if packet.streamIndex == 0 {
        // Video
        let outStream = outputVideoFmtContext.streams[0]
        packet.pts = av_rescale_q_rnd(packet.pts, inStream.timebase, outStream.timebase, AVRounding(rawValue: AV_ROUND_NEAR_INF.rawValue | AV_ROUND_PASS_MINMAX.rawValue))
        packet.dts = av_rescale_q_rnd(packet.dts, inStream.timebase, outStream.timebase, AVRounding(rawValue: AV_ROUND_NEAR_INF.rawValue | AV_ROUND_PASS_MINMAX.rawValue))
        packet.duration = av_rescale_q(packet.duration, inStream.timebase, outStream.timebase)
        packet.pos = -1
        packet.streamIndex = 0
        try outputVideoFmtContext.interleavedWriteFrame(pkt: packet)
    } else if packet.streamIndex == 1 {
        // truehd
        let outStream = outputAudioFmtContext.streams[0]
        packet.pts = av_rescale_q_rnd(packet.pts, inStream.timebase, outStream.timebase, AVRounding(rawValue: AV_ROUND_NEAR_INF.rawValue | AV_ROUND_PASS_MINMAX.rawValue))
        packet.dts = av_rescale_q_rnd(packet.dts, inStream.timebase, outStream.timebase, AVRounding(rawValue: AV_ROUND_NEAR_INF.rawValue | AV_ROUND_PASS_MINMAX.rawValue))
        packet.duration = av_rescale_q(packet.duration, inStream.timebase, outStream.timebase)
        packet.pos = -1
        packet.streamIndex = 0
        try outputAudioFmtContext.interleavedWriteFrame(pkt: packet)
    }
}

try outputVideoFmtContext.writeTrailer()
try outputAudioFmtContext.writeTrailer()
// MARK: Demux directly
//while true {
//    defer { packet.unref() }
//    do {
//        try context.readFrame(into: packet)
////        print(packet.streamIndex)
//        guard let handle = target[packet.streamIndex] else {
//            print("No handle for stream!")
//            continue
//        }
//        handle.write(Data.init(bytes: packet.data!, count: packet.size))
//    } catch {
//        print(error)
//        exit(0)
//    }
//}
*/
