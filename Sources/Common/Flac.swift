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
    
    public var alternative: [Converter]? { return nil }
    
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
        struct ShowMD5: Executable {
            static let executableName = "metaflac"
            
            let arguments: [String]
            
            init(inputs: [String]) { arguments = ["--no-filename", "--show-md5sum"] + inputs }
        }
        let md5 = try ShowMD5(inputs: inputs).runAndCatch(checkNonZeroExitCode: true)
        return Array(String.init(decoding: md5.stdout, as: UTF8.self).components(separatedBy: .newlines).dropLast())
    }
    
}
