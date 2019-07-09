public enum MediaTools: String {
    case ffmpeg
    case mkvmerge
    case mkvextract
    case mp4Box = "MP4Box"
    case LsmashRemuxer = "remuxer"
    
    public func executable(arguments: [String]) -> AnyExecutable {
        return .init(executableName: rawValue, arguments: arguments)
    }
}
