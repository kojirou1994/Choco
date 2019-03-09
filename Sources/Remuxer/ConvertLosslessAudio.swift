//
//  ConvertLosslessAudio.swift
//  Remuxer
//
//  Created by Kojirou on 2018/9/17.
//

import Foundation
import Common
import SwiftFFmpeg

/*
func dumpTracks(input: String) throws {
    let context = try AVFormatContextWrapper.init(url: input)
    try context.findStreamInfo()
    context.streams.forEach { (stream) in
        print("\(stream.index) \(stream.codecpar.codecId.name) \(stream.isLosslessAudio ? "lossless" : "lossy") \(stream.language)")
        print(stream.metadata.dictionary)
    }
}
*/
extension AVFormatContextWrapper {
    
    var primaryLanguage: String {
        for stream in streams {
            if stream.mediaType == AVMEDIA_TYPE_AUDIO {
                return stream.language
            }
        }
        return "und"
    }
    
}

extension AVStreamWrapper {
    
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
            let codecContext = AVCodecContextWrapper.init(codec: AVCodecWrapper.init(decoderId: codecpar.codecId)!)!
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
        guard mediaType == AVMEDIA_TYPE_AUDIO else {
            return false
        }
        switch codecpar.codecId {
        case AV_CODEC_ID_TRUEHD:
            return true
        case AV_CODEC_ID_DTS:
            let codecContext = AVCodecContextWrapper.init(codec: AVCodecWrapper.init(decoderId: codecpar.codecId)!)!
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
    
//    var isGoodLosslessAudio: Bool
    
    var isLosslessAudio: Bool {
        guard mediaType == AVMEDIA_TYPE_AUDIO else {
            return false
        }
        switch codecpar.codecId {
        case AV_CODEC_ID_FLAC, AV_CODEC_ID_ALAC, AV_CODEC_ID_TRUEHD:
            return true
        case AV_CODEC_ID_DTS:
            let codecContext = AVCodecContextWrapper.init(codec: AVCodecWrapper.init(decoderId: codecpar.codecId)!)!
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
