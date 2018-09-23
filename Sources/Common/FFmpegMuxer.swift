//
//  FFmpegMuxer.swift
//  Common
//
//  Created by Kojirou on 2018/9/22.
//

import Foundation

public final class FFmpegMuxer: Converter {
    
    public static let executable = "ffmpeg"
    
    public let input: String
    
    public let output: String
    
    public init(input: String, output: String) {
        self.input = input
        self.output = output
    }
    
    public enum CopyMode {
        case copyAll, videoOnly, audioOnly
    }
    
    public func convert() throws {
        try convert(mode: .copyAll)
    }
    
    public func convert(mode: CopyMode) throws {
        try checkPath()
        printTask()
        let arguments: [String]
        switch mode {
        case .audioOnly:
            arguments = ["-v", "quiet", "-nostdin", "-y", "-i", input, "-c", "copy", "-vn", "-sn", output]
        case .copyAll:
            arguments = ["-v", "quiet", "-nostdin", "-y", "-i", input, "-c", "copy", output]
        case .videoOnly:
            arguments = ["-v", "quiet", "-nostdin", "-y", "-i", input, "-c", "copy", "-an", "-sn", output]
        }
        let p = try! Process.init(executableName: "ffmpeg", arguments: arguments)
        p.launchUntilExit()
        try p.checkTerminationStatus()
    }
    
}
