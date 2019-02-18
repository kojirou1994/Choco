//
//  Flac.swift
//  Common
//
//  Created by Kojirou on 2018/9/22.
//

import Foundation

public final class Flac: Converter {
    public var arguments: [String] {
        return [input, "--totally-silent", "-f", "-o", output]
    }
    
    
    public static let executableName: String = "flac"
    
    public let input: String
    
    public let output: String
    
    public init(input: String, output: String) {
        self.input = input
        self.output = output
    }
    
}

public struct FlacMD5 {
    
    public static func calculate(inputs: [String]) throws -> [String] {
        let p = try Process.init(executableName: "metaflac", arguments: ["--no-filename", "--show-md5sum"] + inputs)
        let pipe = Pipe.init()
        p.standardOutput = pipe
        p.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        try p.checkTerminationStatus()
        return Array(String.init(data: data, encoding: .utf8)!.components(separatedBy: .newlines).dropLast())
    }
    
}
