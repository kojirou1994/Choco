//
//  Flac.swift
//  Common
//
//  Created by Kojirou on 2018/9/22.
//

import Executable

public struct FlacMD5 {
    
    public static func calculate(inputs: [String]) throws -> [String] {
        struct ShowMD5: Executable {
            static let executableName = "metaflac"
            
            let arguments: [String]
            
            init(inputs: [String]) { arguments = ["--no-filename", "--show-md5sum"] + inputs }
        }
        let md5 = try ShowMD5(inputs: inputs).runAndCatch(checkNonZeroExitCode: true)
        return md5.stdout.split(separator: UInt8.init(ascii: "\n")).map {String(decoding: $0, as: UTF8.self)}
//        return Array(String.init(decoding: md5.stdout, as: UTF8.self).components(separatedBy: .newlines).dropLast())
    }
    
}
