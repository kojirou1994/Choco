//
//  Converter.swift
//  Common
//
//  Created by Kojirou on 2018/9/22.
//

import Foundation

public protocol Converter: Executable {
    
    var input: String {get}
    
    var output: String {get}
    
    init(input: String, output: String)
    
}

extension Converter {
    
    public func convert() throws -> Process {
        try checkPath()
        printTask()
        return try generateProcess()
    }
    
    func checkPath() throws {
        if input == output {
            throw RemuxerError.sameFilename
        }
    }
    
    func printTask() {
        print("\n\(Self.executableName):\n\(input)\n->\n\(output)")
    }
    
}
