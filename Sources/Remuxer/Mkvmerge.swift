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
    
    init(input: String, output: String, audioLanguages: Set<String>, subtitleLanguages: Set<String>) {
        self.input = input
        self.output = output
        self.audioLanguages = audioLanguages
        self.subtitleLanguages = subtitleLanguages
    }
    
    func mux() throws {
        var arguments = ["--output", output]
        if audioLanguages.count > 0 {
            arguments.append("-a")
            arguments.append(audioLanguages.joined(separator: ","))
        }
        if subtitleLanguages.count > 0 {
            arguments.append("-s")
            arguments.append(subtitleLanguages.joined(separator: ","))
        }
        arguments.append(input)
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
    
    func mux() throws {
        let p = try Process.init(executableName: "ffmpeg", arguments: ["-nostdin", "-y", "-i", input, "-c", "copy", output])
        p.launchUntilExit()
        try p.checkTerminationStatus()
    }
}
