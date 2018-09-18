//
//  Flac.swift
//  Remuxer
//
//  Created by Kojirou on 2018/9/17.
//

import Foundation
import Kwift

extension Process {
    func launchUntilExit() {
        launch()
        while isRunning {
            sleep(1)
        }
    }
    
    func checkTerminationStatus() throws {
        if terminationStatus != 0 {
            throw RemuxerError.processError(code: terminationStatus)
        }
    }
}

class Flac {
    let input: String
    let output: String
    
    init(input: String, output: String) {
        self.input = input
        self.output = output
    }
    
    func convert() throws {
        let p = try Process.init(executableName: "flac", arguments: [input, "-f", "-o", output])
        p.launchUntilExit()
        try p.checkTerminationStatus()
    }

}

struct FlacMD5 {
    static func calculate(inputs: [String]) throws -> [String] {
        let p = try Process.init(executableName: "metaflac", arguments: ["--no-filename", "--show-md5sum"] + inputs)
        let pipe = Pipe.init()
        p.standardOutput = pipe
        p.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        try p.checkTerminationStatus()
        return Array(String.init(data: data, encoding: .utf8)!.components(separatedBy: .newlines).dropLast())
    }
}
