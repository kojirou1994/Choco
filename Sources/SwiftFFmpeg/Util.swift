//
//  Util.swift
//  SwiftFFmpeg
//
//  Created by sunlubo on 2018/7/9.
//
import CFFmpeg

@usableFromInline
internal func readUnrecognizedOptions(_ dict: OpaquePointer?) {
    var dictionary = FFmpegDictionary(metadata: dict)
    dictionary.enumerate { (key, value) in
        print("Warning: Option \(key)=\(value) not recognized.")
    }
    dictionary.free()
}

@usableFromInline
internal func readArray<P, T>(pointer: UnsafePointer<P>?, stop: (P) -> Bool, transform: (P) -> T) -> [T] {
    guard let p = pointer else {
        return []
    }
    var result = [T]()
    for i in 0..<Int.max {
        let v = p[i]
        if stop(v) {
            break
        } else {
            result.append(transform(v))
        }
    }
    return result
}

public struct FFmpegVersion {
    private static func AV_VERSION(_ a: Int32, _ b: Int32, _ c: Int32) -> String {
        return "\(a).\(b).\(c)"
    }
    
    private static func AV_VERSION_INT(_ a: Int32, _ b: Int32, _ c: Int32) -> Int32 {
        return ((a)<<16 | (b)<<8 | (c))
    }
    
    
    public struct LIBAVFORMAT {
        public static var versionInt: Int32 {
            return FFmpegVersion.AV_VERSION_INT(LIBAVFORMAT_VERSION_MAJOR, LIBAVFORMAT_VERSION_MINOR, LIBAVFORMAT_VERSION_MICRO)
        }
        
        public static var version: String {
            return FFmpegVersion.AV_VERSION(LIBAVFORMAT_VERSION_MAJOR, LIBAVFORMAT_VERSION_MINOR, LIBAVFORMAT_VERSION_MICRO)
        }
        
        public static var licence: String {
            return .init(cString: avformat_license())
        }
    }
    
    public struct LIBAVCODEC {
        public static var versionInt: Int32 {
            return FFmpegVersion.AV_VERSION_INT(LIBAVCODEC_VERSION_MAJOR, LIBAVCODEC_VERSION_MINOR, LIBAVCODEC_VERSION_MICRO)
        }
        
        public static var version: String {
            return FFmpegVersion.AV_VERSION(LIBAVCODEC_VERSION_MAJOR, LIBAVCODEC_VERSION_MINOR, LIBAVCODEC_VERSION_MICRO)
        }
        
        public static var licence: String {
            return .init(cString: avcodec_license())
        }
    }
    
}
