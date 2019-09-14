import Foundation
import MediaTools
import MediaUtility

guard CommandLine.argc > 1 else {
    print("No inputs!")
    exit(1)
}

extension TrackType {
    var mark: String {
        switch self {
        case .audio: return "A"
        case .subtitles: return "S"
        case .video: return "V"
        }
    }
}

extension MkvmergeIdentification.Track {
    var isLosslessAudio: Bool {
        guard type == .audio else {
            return false
        }
        switch codec {
        case "FLAC", "ALAC" , "DTS-HD Master Audio", "PCM", "TrueHD Atmos", "TrueHD":
            return true
        default:
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
    
    var isTrueHD: Bool {
        switch codec {
        case "TrueHD Atmos", "TrueHD":
            return true
        default:
            return false
        }
    }
    
    var info: String {
        var str = "\(id): \(type.mark) \(codec)"
        if let lang = properties.language {
            str.append(" \(lang)")
        }
//        switch type {
//        case .video:
//            str.append(" \(properties.pixelDimensions!)")
//        case .audio:
//            str.append(" \(properties.audioBitsPerSample!)bits")
//        default:
//            break
//        }
        if type == .video {
            str.append(" ")
            str.append(properties.pixelDimensions ?? "")
        } else if type == .audio {
            str.append(" \(isLosslessAudio ? "lossless" : "lossy")")
            str.append(" \(properties.audioBitsPerSample ?? 0)bits")
            str.append(" \(properties.audioSamplingFrequency ?? 0)Hz")
            str.append(" \(properties.audioChannels ?? 0)ch")
        }
        return str
    }
}

func trackinfo(_ file: String) {
    do {
        let info = try MkvmergeIdentification(filePath: file)
        print(file)
        for track in info.tracks {
            print(track.info)
        }
        print("\n\n")
    } catch {
        print("Failed to read \(file), error: \(error)")
    }
}

CommandLine.arguments[1...].forEach(trackinfo(_:))
