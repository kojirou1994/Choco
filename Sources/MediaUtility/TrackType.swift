public enum TrackType: String, Codable, CustomStringConvertible {
    case video
    case audio
    case subtitles
    
    public var description: String {
        return rawValue
    }
}
