//
//  ConvertLosslessAudio.swift
//  Remuxer
//
//  Created by Kojirou on 2018/9/17.
//

import Foundation
import SwiftFFmpeg
import Kwift

func convertLosslessAudio(input: String, outputDir: String, preferedLanguages: Set<String>) throws {
    var flacConverters = [Flac]()
    var arguments = ["-v", "quiet", "-nostdin", "-y", "-i", input, "-vn"]
    
    let context = try AVFormatContext.init(url: input)
    try context.findStreamInfo()
    context.streams.forEach { (stream) in
        print("\(stream.index) \(stream.codecpar.codecId.name) \(stream.isLosslessAudio ? "lossless" : "lossy") \(stream.language)")
        if stream.isGrossAudio, preferedLanguages.contains(stream.language) {
            arguments.append("-map")
            arguments.append("0:\(stream.index)")
            let tempFlac = "\(outputDir)/\(input.filenameWithoutExtension)-\(stream.index)-\(stream.language)-ffmpeg.flac"
            let finalFlac = "\(outputDir)/\(input.filenameWithoutExtension)-\(stream.index)-\(stream.language).flac"
            arguments.append(tempFlac)
            flacConverters.append(Flac.init(input: tempFlac, output: finalFlac))
        }
    }
    
    let ffmpeg = try Process.init(executableName: "ffmpeg", arguments: arguments)
    ffmpeg.launchUntilExit()
    try ffmpeg.checkTerminationStatus()
    
    try flacConverters.forEach { (flac) in
        try flac.convert()
        try FileManager.default.removeItem(atPath: flac.input)
    }
}

func dumpTracks(input: String) throws {
    let context = try AVFormatContext.init(url: input)
    try context.findStreamInfo()
    context.streams.forEach { (stream) in
        print("\(stream.index) \(stream.codecpar.codecId.name) \(stream.isLosslessAudio ? "lossless" : "lossy") \(stream.language)")
        print(stream.metadata.dictionary)
    }
    print(try context.findBestStream(type: .audio))
}

extension AVFormatContext {
    
    var primaryLanguage: String {
        for stream in streams {
            if stream.mediaType == .audio {
                return stream.language
            }
        }
        return "und"
    }
    
}

extension AVStream {
    
    var language: String {
        return metadata["language"] ?? "und"
    }
    
    var isAC3: Bool {
        switch codecpar.codecId {
        case AV_CODEC_ID_AC3, AV_CODEC_ID_EAC3:
            return true
        default:
            return false
        }
    }
    
    var isTruehd: Bool {
        switch codecpar.codecId {
        case AV_CODEC_ID_TRUEHD:
            return true
        default:
            return false
        }
    }
    
    var isDtshd: Bool {
        switch codecpar.codecId {
        case AV_CODEC_ID_DTS:
            let codecContext = AVCodecContext.init(codec: AVCodec.findDecoderById(codecpar.codecId)!)!
            try! codecContext.setParameters(codecpar)
            if codecContext.profileName == "DTS-HD MA" {
                return true
            } else {
                return false
            }
        default:
            return false
        }
    }
    
    var isGrossAudio: Bool {
        guard mediaType == .audio else {
            return false
        }
        switch codecpar.codecId {
        case AV_CODEC_ID_TRUEHD:
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
