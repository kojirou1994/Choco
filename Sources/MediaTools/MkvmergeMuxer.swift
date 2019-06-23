//
//  MkvmergeMuxer.swift
//  Common
//
//  Created by Kojirou on 2018/9/22.
//

import Foundation

public struct MkvmergeMuxer: Converter {
    
    public static let executableName: String = "mkvmerge"    
    
    public let input: [String]
    
    public let output: String
    
    public var alternative: [Converter]?
    
    let audioLanguages: Set<String>
    
    let subtitleLanguages: Set<String>
    
    let chapterPath: String?
    
    var extraArguments: [String]
    
    let cleanInputChapter: Bool
    
    public init(input: String, output: String) {
        self.input = [input]
        self.output = output
        self.audioLanguages = []
        self.subtitleLanguages = []
        self.chapterPath = nil
        self.extraArguments = []
        self.cleanInputChapter = false
    }
    
    public init(input: [String], output: String, audioLanguages: Set<String>,
                subtitleLanguages: Set<String>, chapterPath: String? = nil, extraArguments: [String] = [], cleanInputChapter: Bool = false) {
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
        self.cleanInputChapter = cleanInputChapter
    }
    
    public var arguments: [String] {
        var arguments = ["-q", "--output", output]
        if audioLanguages.count > 0 {
            arguments.append("-a")
            arguments.append(audioLanguages.joined(separator: ","))
        }
        if subtitleLanguages.count > 0 {
            arguments.append("-s")
            arguments.append(subtitleLanguages.joined(separator: ","))
        }
        
        if cleanInputChapter {
            arguments.append("--no-chapters")
        }
        arguments.append(input[0])
        if input.count > 1 {
            input[1...].forEach { (i) in
                if cleanInputChapter {
                    arguments.append("--no-chapters")
                }
                arguments.append("+")
                arguments.append(i)
            }
        }
        
        if chapterPath != nil {
            arguments.append(contentsOf: ["--chapters", chapterPath!])
        }
        
        arguments.append(contentsOf: extraArguments)
        
        return arguments
    }
    
}
