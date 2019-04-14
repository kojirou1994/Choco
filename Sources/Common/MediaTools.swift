//
//  MediaTools.swift
//  Common
//
//  Created by Kojirou on 2019/4/14.
//

import Foundation
import Executable

public struct FFmpeg: Executable {
    public static let executableName = "ffmpeg"
    public let arguments: [String]
    
    public init(arguments: [String]) {
        self.arguments = arguments
    }
}

public struct MKVmerge: Executable {
    public static let executableName = "mkvmerge"
    public let arguments: [String]
    
    public init(arguments: [String]) {
        self.arguments = arguments
    }
}

public struct MKVextract: Executable {
    public static let executableName = "mkvextract"
    public let arguments: [String]
    
    public init(arguments: [String]) {
        self.arguments = arguments
    }
}

public struct MP4Box: Executable {
    public static let executableName = "MP4Box"
    public let arguments: [String]
    
    public init(arguments: [String]) {
        self.arguments = arguments
    }
}

public struct LsmashRemuxer: Executable {
    public static let executableName = "remuxer"
    public let arguments: [String]
    
    public init(arguments: [String]) {
        self.arguments = arguments
    }
}
