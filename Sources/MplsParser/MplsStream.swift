import Foundation

public struct MplsStream {
    public var streamType: StreamType
    public var codec: Codec
    public var pid: UInt16
    public var subpathId: UInt8?
    public var subclipId: UInt8?
    
    public let attribute: StreamAttribute
}

public enum StreamAttribute {
    case video(Video)
    case audio(Audio)
    case pgs(PGS)
    case textsubtitle(TextSubtitle)
    public struct Video {
        public let format: VideoFormat
        public let rate: VideoRate
    }
    public struct Audio {
        public let format: AudioFormat
        public let rate: AudioRate
        public let language: String
    }
    public struct PGS {
        public let language: String
    }
    public struct TextSubtitle {
        public let charCode: CharacterCode
        public enum CharacterCode: UInt8, CustomStringConvertible {
            
            public var description: String {
                switch self {
                case .big5: return "BIG5 (Chinese)"
                case .gb18030_200: return "GB18030-200 (Chinese)"
                case .gb2312: return "GB2312 (Chinese)"
                case .ksc: return "KSC 5601-1987 (Korean)"
                case .reserved: return "Reserved"
                case .shiftJ: return "Shift JIS (Japanese)"
                case .utf16: return "UTF16"
                case .utf8: return "UTF8"
                }
            }
            
            init(value: UInt8) throws {
                if let v = CharacterCode.init(rawValue: value) {
                    self = v
                } else {
                    throw MplsReadError.invalidCharacterCode(value)
                }
            }
            
            case reserved = 0x00
            case utf8 = 0x01
            case utf16 = 0x02
            case shiftJ = 0x03
            case ksc = 0x04
            case gb18030_200 = 0x05
            case gb2312 = 0x06
            case big5 = 0x07
        }
        public let language: String
    }
    
    public var lang: String {
        switch self {
        case .video(_):
            return "und"
        case .audio(let a):
            return a.language
        case .pgs(let p):
            return p.language
        case .textsubtitle(let t):
            return t.language
        }
    }
}
