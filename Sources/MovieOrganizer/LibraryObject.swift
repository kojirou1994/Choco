//
//  File.swift
//  
//
//  Created by Kojirou on 2019/6/24.
//

import Foundation
import MediaTools

struct LibraryObject {
    
    //    enum MetaData: String {
    //        case imdb
    //        case tag
    //        case tvdbLang
    //    }
    
    struct Movie {
        let path: String
        let imdbId: String
        let tag: String?
    }
    
    struct Series {
        let path: String
        let seriesNumber: Int
    }
    
    enum LibraryImportError: Error {
        case unsuportted(type: TrackType, codec: String)
    }
    
    struct MediaFile {
        let path: String
        let tracks: [Track]
        
        init(path: String) throws {
            let mkvinfo = try MkvmergeIdentification.init(filePath: path)
            self.tracks = try mkvinfo.tracks.map(Track.init)
            self.path = path
        }
        
        struct Track {
            let codec: Codec
            
            let language: String
            
            init(_ track: MkvmergeIdentification.Track) throws {
                switch (track.type, track.codec) {
                case (.video, "MPEG-4p10/AVC/h.264"), (.video, "AVC/h.264"):
                    codec = .video(.avc)
                case (.video, "MPEG-H/HEVC/h.265"):
                    codec = .video(.hevc)
                case (.audio, "FLAC"):
                    codec = .audio(.flac)
                case (.audio, "AAC"):
                    codec = .audio(.aac)
                case (.audio, "AC-3"), (.audio, "E-AC-3"):
                    codec = .audio(.ac3)
                case (.audio, "PCM"):
                    codec = .audio(.pcm)
                case (.audio, "TrueHD Atmos"):
                    codec = .audio(.shitTrueHDAtmos)
                case (.audio, "DTS-HD Master Audio"):
                    codec = .audio(.shitDTSHD)
                case (.audio, "Opus"):
                    codec = .audio(.opus)
                case (.subtitles, "HDMV PGS"):
                    codec = .subtitle(.pgs)
                case (.subtitles, "SubStationAlpha"):
                    codec = .subtitle(.ass)
                case (.subtitles, "SubRip/SRT"):
                    codec = .subtitle(.srt)
                default:
                    throw LibraryImportError.unsuportted(type: track.type, codec: track.codec)
                }
                language = track.properties.language ?? "und"
            }
            
            enum Codec {
                case video(VideoCodec)
                case audio(AudioCodec)
                case subtitle(SubtitleCodec)
                
                enum VideoCodec {
                    case avc
                    case hevc
                }
                
                enum AudioCodec {
                    case flac
                    case aac
                    case opus
                    case shitDTS
                    case shitDTSHD
                    case shitTrueHD
                    case shitTrueHDAtmos
                    case ac3
                    case pcm
                }
                
                enum SubtitleCodec {
                    case ass
                    case srt
                    case pgs
                }
            }
            
        }
    }
    
    
}
