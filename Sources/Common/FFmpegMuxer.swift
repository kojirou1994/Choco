//
//  FFmpegMuxer.swift
//  Common
//
//  Created by Kojirou on 2018/9/22.
//

import Foundation

public struct FFmpegMuxer: Converter {
    
    public var arguments: [String] {
        let arguments: [String]
        switch mode {
        case .audioOnly:
            arguments = ["-v", "quiet", "-nostdin", "-y", "-i", input, "-c", "copy", "-vn", "-sn", output]
        case .copyAll:
            arguments = ["-v", "quiet", "-nostdin", "-y", "-i", input, "-c", "copy", output]
        case .videoOnly:
            arguments = ["-v", "quiet", "-nostdin", "-y", "-i", input, "-c", "copy", "-an", "-sn", output]
        }
        return arguments
    }
    
    public static let executableName = "ffmpeg"
    
    public let input: String
    
    public let output: String
    
    public var alternative: [Converter]?
    
    public let mode: CopyMode
    
    public init(input: String, output: String) {
        self.input = input
        self.output = output
        self.mode = .copyAll
    }
    
    public init(input: String, output: String, mode: CopyMode) {
        self.input = input
        self.output = output
        self.mode = mode
    }
    
    public enum CopyMode {
        case copyAll, videoOnly, audioOnly
    }
    
}
