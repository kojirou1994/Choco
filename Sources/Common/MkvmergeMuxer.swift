//
//  MkvmergeMuxer.swift
//  Common
//
//  Created by Kojirou on 2018/9/22.
//

import Foundation

public final class MkvmergeMuxer: Converter {
    
    public static let executable = "mkvmerge"    
    
    public let input: String
    
    public let output: String
    
    let audioLanguages: Set<String>
    
    let subtitleLanguages: Set<String>
    
    let chapterPath: String?
    
    let extraArguments: [String]
    
    public init(input: String, output: String) {
        self.input = input
        self.output = output
        self.audioLanguages = []
        self.subtitleLanguages = []
        self.chapterPath = nil
        self.extraArguments = []
    }
    
    public init(input: String, output: String, audioLanguages: Set<String>,
         subtitleLanguages: Set<String>, chapterPath: String? = nil, extraArguments: [String] = []) {
        self.input = input
        self.output = output
        self.audioLanguages = audioLanguages
        self.subtitleLanguages = subtitleLanguages
        if let path = chapterPath, !path.isEmpty {
            self.chapterPath = path
        } else {
            self.chapterPath = nil
        }
        self.extraArguments = extraArguments
    }
    
    public func convert() throws {
        try checkPath()
        printTask()
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
