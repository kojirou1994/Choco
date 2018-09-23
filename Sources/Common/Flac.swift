//
//  Flac.swift
//  Common
//
//  Created by Kojirou on 2018/9/22.
//

import Foundation

public final class Flac: Converter {
    
    public static let executable = "flac"
    
    public let input: String
    
    public let output: String
    
    public init(input: String, output: String) {
        self.input = input
        self.output = output
    }
    
    public func convert() throws {
        try checkPath()
        printTask()
        let p = try Process.init(executableName: "flac", arguments: [input, "--totally-silent", "-f", "-o", output])
        p.launchUntilExit()
        try p.checkTerminationStatus()
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
