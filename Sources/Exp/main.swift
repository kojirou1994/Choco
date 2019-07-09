import Foundation
import MplsReader
import CLibbluray

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

let bd = bd_open(CommandLine.arguments[1], nil)!
let info = bd_get_disc_info(bd)!.pointee

print(info)
print("disc name: \(String.init(cString: info.disc_name))")
for i in 0..<Int(info.num_titles) {
    let title = info.titles[i]!.pointee
    print(title)
}

let count = bd_get_titles(bd, UInt8(TITLES_RELEVANT), 0)
for i in 0..<count {
    let ti = bd_get_title_info(bd, i, 0)!.pointee
    print(ti)
}

let mainTitle = bd_get_main_title(bd)
print(mainTitle)
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
*/
