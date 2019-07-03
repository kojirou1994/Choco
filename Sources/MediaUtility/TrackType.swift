public enum TrackType: String, Decodable, CustomStringConvertible {
    case video
    case audio
    case subtitles
    
    public var description: String {
        return rawValue
    }
}
