//
//  Mkvmerge.swift
//  Remuxer
//
//  Created by Kojirou on 2018/9/17.
//

import Foundation
import Kwift

class Mkvmerge {
    let input: String
    let output: String
    let audioLanguages: Set<String>
    let subtitleLanguages: Set<String>
    let chapterPath: String?
    
    init(input: String, output: String, audioLanguages: Set<String> = Set(),
         subtitleLanguages: Set<String> = Set(), chapterPath: String? = nil) {
        self.input = input
        self.output = output
        self.audioLanguages = audioLanguages
        self.subtitleLanguages = subtitleLanguages
        if let path = chapterPath, !path.isEmpty {
            self.chapterPath = path
        } else {
            self.chapterPath = nil
        }
    }
    
    func mux() throws {
        print("Mkvmerge:\n\(input)\n->\n\(output)\n")
        var arguments = ["-q", "--output", output]
        if audioLanguages.count > 0 {
            arguments.append("-a")
            arguments.append(audioLanguages.joined(separator: ","))
        }
        if subtitleLanguages.count > 0 {
            arguments.append("-s")
            arguments.append(subtitleLanguages.joined(separator: ","))
        }
        
        arguments.append(input)
        
        if chapterPath != nil {
            arguments.append(contentsOf: ["--chapters", chapterPath!])
        }
        let p = try Process.init(executableName: "mkvmerge", arguments: arguments)
        p.launchUntilExit()
        try p.checkTerminationStatus()
    }
}

class FFmpegMerge {
    let input: String
    let output: String
    
    init(input: String, output: String) {
        self.input = input
        self.output = output
    }
    
    enum CopyMode {
        case copyAll, videoOnly, audioOnly
    }
    
    func mux(mode: CopyMode = .copyAll) throws {
        print("FFmpeg:\n\(input)\n->\n\(output)\n")
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
