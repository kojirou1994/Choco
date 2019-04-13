//
//  FFmpegLog.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/13.
//

import CFFmpeg

public struct FFmpegLog {
    
    public static func set(level: Level) {
        av_log_set_level(level.rawValue)
    }
    
    public static var currentLevel: Level {
        return .init(rawValue: av_log_get_level())
    }
    
    public enum Level: CaseIterable {
        case quite, panic, fatal, error, warning, info, verbose, debug, trace, maxOffset
        
        var rawValue: Int32 {
            switch self {
            case .debug:   return AV_LOG_DEBUG
            case .error:   return AV_LOG_ERROR
            case .fatal:   return AV_LOG_FATAL
            case .info:   return AV_LOG_INFO
            case .maxOffset:   return AV_LOG_MAX_OFFSET
            case .panic:   return AV_LOG_PANIC
            case .quite:   return AV_LOG_QUIET
            case .trace:   return AV_LOG_TRACE
            case .verbose:   return AV_LOG_VERBOSE
            case .warning:   return AV_LOG_WARNING
            }
        }
        
        init(rawValue: Int32) {
            switch rawValue {
            case AV_LOG_DEBUG: self = .debug
            case AV_LOG_ERROR: self = .error
            case AV_LOG_FATAL: self = .fatal
            case AV_LOG_INFO: self = .info
            case AV_LOG_MAX_OFFSET: self = .maxOffset
            case AV_LOG_PANIC: self = .panic
            case AV_LOG_QUIET: self = .quite
            case AV_LOG_TRACE: self = .trace
            case AV_LOG_WARNING: self = .warning
            case AV_LOG_VERBOSE: self = .verbose
            default:
                fatalError()
            }
        }
    }
}
