import Foundation
import SwiftFFmpeg

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

