import Foundation
import Kwift

public struct MkvmergeIdentification: Decodable {
    /// an array describing the attachments found if any
    var attachments: [Attachment]
    var chapters: [Chapter]
    /// information about the identified container
    var container: Container
    var errors: [String]
    var fileName: String
    var globalTags: [GlobalTag]
    var identificationFormatVersion: Int
    var trackTags: [TrackTag]
    var tracks: [Track]
    var warnings: [String]
    
    public struct Container: Decodable {
        /// additional properties for the container varying by container format
        var properties: Properties?
        /// States whether or not mkvmerge knows about the format
        var recognized: Bool
        /// States whether or not mkvmerge can read the format
        var supported: Bool
        /// A human-readable description/name for the container format
        var type: String?
    
        public struct Properties: Decodable {
        
            /// A unique number identifying the container type that's supposed to stay constant over all future releases of MKVToolNix
            var containerType: Int?
            /// The muxing date in ISO 8601 format (in local time zone)
            var dateLocal: String?
            /// The muxing date in ISO 8601 format (in UTC)
            var dateUtc: String?
            /// The file's/segment's duration in nanoseconds
            var duration: Int?
            /// States whether or not the container has timestamps for the packets (e.g. Matroska, MP4) or not (e.g. SRT, MP3)
            var isProvidingTimestamps: Bool?
            /// A Unicode string containing the name and possibly version of the low-level library or application that created the file
            var muxingApplication: String?
            /// A hexadecimal string of the next segment's UID (only for Matroska files)
            var nextSegmentUid: String?
            /// An array of names of additional files processed as well
            var otherFile: [String]?
            /// States whether or not the identified file is a playlist (e.g. MPLS) referring to several other files
            var playlist: Bool?
            /// The number of chapters in a playlist if it is a one
            var playlistChapters: Int?
            /// The total duration in nanoseconds of all files referenced by the playlist if it is a one
            var playlistDuration: Int?
            /// An array of file names the playlist contains
            var playlistFile: [String]?
            /// The total size in bytes of all files referenced by the playlist if it is a one
            var playlistSize: Int?
            /// "A hexadecimal string of the previous segment's UID (only for Matroska files)
            var previousSegmentUid: String?
            var programs: [Program]?
            /// A hexadecimal string of the segment's UID (only for Matroska files)
            var segmentUid: String?
            var title: String?
            /// A Unicode string containing the name and possibly version of the high-level application that created the file
            var writingApplication: String?
        
            /// A container describing multiple programs multiplexed into the source file, e.g. multiple programs in one DVB transport stream
            struct Program: Decodable {
                /// A unique number identifying a set of tracks that belong together; used e.g. in DVB for multiplexing multiple stations within a single transport stream
                var programNumber: Int?
                /// The name of a service provided by this program, e.g. a TV channel name such as 'arte HD'
                var serviceName: String
                /// The name of the provider of the service provided by this program, e.g. a TV station name such as 'ARD'
                var serviceProvider: String
                
                private enum CodingKeys: String, CodingKey {
                    case programNumber = "program_number"
                    case serviceName = "service_name"
                    case serviceProvider = "service_provider"
                }
            }
        
            private enum CodingKeys: String, CodingKey {
                case containerType = "container_type"
                case dateLocal = "date_local"
                case dateUtc = "date_utc"
                case duration
                case isProvidingTimestamps = "is_providing_timestamps"
                case muxingApplication = "muxing_application"
                case nextSegmentUid = "next_segment_uid"
                case otherFile = "other_file"
                case playlist
                case playlistChapters = "playlist_chapters"
                case playlistDuration = "playlist_duration"
                case playlistFile = "playlist_file"
                case playlistSize = "playlist_size"
                case previousSegmentUid = "previous_segment_uid"
                case programs
                case segmentUid = "segment_uid"
                case title
                case writingApplication = "writing_application"
            }
        
        }
    
    }

    struct GlobalTag: Decodable {
        var numEntries: Int
        private enum CodingKeys: String, CodingKey {
            case numEntries = "num_entries"
        }
    }
    
    struct TrackTag: Decodable {
        var numEntries: Int
        var trackId: Int
        private enum CodingKeys: String, CodingKey {
            case numEntries = "num_entries"
            case trackId = "track_id"
        }
    }

    public struct Track: Decodable {
        var codec: String
        var id: Int
        var type: String
        var properties: Properties
    
        public struct Properties: Decodable {
        
            var aacIsSbr: AacIsSbr?
            var audioBitsPerSample: Int?
            var audioChannels: Int?
            var audioSamplingFrequency: Int?
            var codecDelay: Int?
            var codecId: String?
            var codecPrivateData: String?
            var codecPrivateLength: Int?
            var contentEncodingAlgorithms: String?
            var defaultDuration: Int?
            var defaultTrack: Bool?
            var displayDimensions: String?
            var displayUnit: Int?
            var enabledTrack: Bool?
            var encoding: String?
            var forcedTrack: Bool?
            var language: String?
            var minimumTimestamp: Int?
            var multiplexedTracks: [Int]?
            var number: Int?
            var packetizer: String?
            var pixelDimensions: String?
            var programNumber: Int?
            var stereoMode: Int?
            var streamId: Int?
            var subStreamId: Int?
            var tagArtist: String?
            var tagBitsps: String?
            var tagBps: String?
            var tagFps: String?
            var tagTitle: String?
            var teletextPage: Int?
            var textSubtitles: Bool?
            var trackName: String?
            var uid: UInt?

            enum AacIsSbr: String, Decodable {
                case `true`,`false`,unknown
            }
            
            private enum CodingKeys: String, CodingKey {
                case aacIsSbr = "aac_is_sbr"
                case audioBitsPerSample = "audio_bits_per_sample"
                case audioChannels = "audio_channels"
                case audioSamplingFrequency = "audio_sampling_frequency"
                case codecDelay = "codec_delay"
                case codecId = "codec_id"
                case codecPrivateData = "codec_private_data"
                case codecPrivateLength = "codec_private_length"
                case contentEncodingAlgorithms = "content_encoding_algorithms"
                case defaultDuration = "default_duration"
                case defaultTrack = "default_track"
                case displayDimensions = "display_dimensions"
                case displayUnit = "display_unit"
                case enabledTrack = "enabled_track"
                case encoding
                case forcedTrack = "forced_track"
                case language
                case minimumTimestamp = "minimum_timestamp"
                case multiplexedTracks = "multiplexed_tracks"
                case number
                case packetizer
                case pixelDimensions = "pixel_dimensions"
                case programNumber = "program_number"
                case stereoMode = "stereo_mode"
                case streamId = "stream_id"
                case subStreamId = "sub_stream_id"
                case tagArtist = "tag_artist"
                case tagBitsps = "tag_bitsps"
                case tagBps = "tag_bps"
                case tagFps = "tag_fps"
                case tagTitle = "tag_title"
                case teletextPage = "teletext_page"
                case textSubtitles = "text_subtitles"
                case trackName = "track_name"
                case uid
            }
        
        }
    }

    struct Attachment: Decodable {
        var contentType: String?
        var description: String?
        var fileName: String
        var id: Int
        var size: Int
        var properties: Property
        var type: String?
        
        struct Property: Decodable {
            var uid: Int
        }
        
        
        private enum CodingKeys: String, CodingKey {
            case contentType = "content_type"
            case fileName = "file_name"
            case description
            case id
            case size
            case properties
            case type
        }
    }
    
    struct Chapter: Decodable {
        var numEntries: Int
        private enum CodingKeys: String, CodingKey {
            case numEntries = "num_entries"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case globalTags = "global_tags"
        case fileName = "file_name"
        case container
        case tracks
        case errors
        case trackTags = "track_tags"
        case attachments
        case identificationFormatVersion = "identification_format_version"
        case warnings
        case chapters
    }

}

extension MkvmergeIdentification {
    
    init(filePath: String) throws {
        print("Reading file: \(filePath)")
        let mkvmerge = try Process.init(executableName: "mkvmerge", arguments: ["-J", filePath])
        
        let pipe = Pipe.init()
        mkvmerge.standardOutput = pipe
        mkvmerge.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        try mkvmerge.checkTerminationStatus()
        self = try jsonDecoder.decode(MkvmergeIdentification.self, from: data)
    }
    
}
