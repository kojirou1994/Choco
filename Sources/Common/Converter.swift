//
//  Converter.swift
//  Common
//
//  Created by Kojirou on 2018/9/22.
//

public protocol Converter {
    
    static var executable: String {get}
    
    var input: String {get}
    
    var output: String {get}
    
    init(input: String, output: String)
    
    func convert() throws
    
}

extension Converter {
    
    func checkPath() throws {
        if input == output {
            throw RemuxerError.sameFilename
        }
    }
    
    func printTask() {
        print("\n\(Self.executable):\n\(input)\n->\n\(output)")
    }
    
}
