//
//  ConvertLosslessAudio.swift
//  Remuxer
//
//  Created by Kojirou on 2018/9/17.
//

import Foundation
import Common
//import SwiftFFmpeg

/*
func dumpTracks(input: String) throws {
    let context = try AVFormatContextWrapper.init(url: input)
    try context.findStreamInfo()
    context.streams.forEach { (stream) in
        print("\(stream.index) \(stream.codecParameters.codecId.name) \(stream.isLosslessAudio ? "lossless" : "lossy") \(stream.language)")
        print(stream.metadata.dictionary)
    }
}
*/
/*
extension FFmpegFormatContext {
    
    var primaryLanguage: String {
        for stream in streams {
            if stream.mediaType == .audio {
                return stream.language
            }
        }
        return "und"
    }
    
}

extension FFmpegStream {
    
    var language: String {
        return metadata["language"] ?? "und"
    }
    
    var isAC3: Bool {
        
        switch codecParameters.codecId {
        case FFmpegCodecID.ac3, FFmpegCodecID.eac3:
            return true
        default:
            return false
        }
    }
    
    var isTruehd: Bool {
        switch codecParameters.codecId {
        case FFmpegCodecID.truehd:
            return true
        default:
            return false
        }
    }
    
    var isDtshd: Bool {
        switch codecParameters.codecId {
        case FFmpegCodecID.dts:
            let codecContext = try! FFmpegCodecContext.init(codec: FFmpegCodec.init(decoderId: codecParameters.codecId))
            try! codecContext.set(parameter: codecParameters)
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
        switch codecParameters.codecId {
        case .truehd:
            return true
        case .dts:
            let codecContext = try! FFmpegCodecContext.init(codec: FFmpegCodec.init(decoderId: codecParameters.codecId))
            try! codecContext.set(parameter: codecParameters)
            if codecContext.profileName == "DTS-HD MA" {
                return true
            } else {
                return false
            }
        default:
            if codecParameters.codecId.name.hasPrefix("pcm") {
                return true
            } else {
                return false
            }
        }
    }
    
//    var isGoodLosslessAudio: Bool
    
    var isLosslessAudio: Bool {
        guard mediaType == .audio else {
            return false
        }
        switch codecParameters.codecId {
        case .flac, .alac, .truehd:
            return true
        case .dts:
            let codecContext = try! FFmpegCodecContext.init(codec: FFmpegCodec.init(decoderId: codecParameters.codecId))
            try! codecContext.set(parameter: codecParameters)
            if codecContext.profileName == "DTS-HD MA" {
                return true
            } else {
                return false
            }
        default:
            if codecParameters.codecId.name.hasPrefix("pcm") {
                return true
            } else {
                return false
            }
        }
    }
    
}
*/

extension MkvmergeIdentification.Track {
    var isLosslessAudio: Bool {
        guard type == .audio else {
            return false
        }
        switch codec {
        case "FLAC", "ALAC" , "DTS-HD Master Audio", "PCM", "TrueHD Atmos", "TrueHD":
            return true
        default:
            print("Not lossless: \(codec)")
            return false
        }
    }
    
    var isAC3: Bool {
        
        switch codec {
        case "E-AC-3", "AC-3":
            return true
        default:
            return false
        }
    }
    
    var isTruehd: Bool {
        switch codec {
        case "TrueHD Atmos", "TrueHD":
            return true
        default:
            return false
        }
    }
}
