import Foundation
import SwiftFFmpeg
import Kwift

FFmpegLog.set(level: .info)

let file = "/Volumes/GLOWAY/哎不哎都行.mp4"
let file2 = "/Volumes/GLOWAY/01_en.mp4"

//try encode_video(filename: "/Volumes/GLOWAY/demo.mp4")

//try metadata(input: file)
//try metadata(input: file2)

//try remuxing(input: file)

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
import CFFmpeg

print(try FFmpegCodec.init(encoderId: .opus).capabilities)
FFmpegOutputFormat.enumrateRegisteredMuxers.forEach { (o) in
    if o.audioCodec == .opus {
        print(o)
    }
}
print(FFmpegVersion.LIBAVCODEC.version)
