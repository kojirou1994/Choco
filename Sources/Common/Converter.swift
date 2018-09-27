//
//  Converter.swift
//  Common
//
//  Created by Kojirou on 2018/9/22.
//

import Foundation
import Kwift

public protocol Converter {
    
    static var executable: String {get}
    
    var input: String {get}
    
    var output: String {get}
    
    init(input: String, output: String)
    
    var arguments: [String] {get}
    
    func convert() throws -> Process
    
}

extension Converter {
    
    public func convert() throws -> Process {
        try checkPath()
        printTask()
        let p = try Process.init(executableName: Self.executable, arguments: arguments)
        return p
    }
    
    func checkPath() throws {
        if input == output {
            throw RemuxerError.sameFilename
        }
    }
    
    func printTask() {
        print("\n\(Self.executable):\n\(input)\n->\n\(output)")
    }
    
}
