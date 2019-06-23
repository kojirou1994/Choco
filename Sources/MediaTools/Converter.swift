//
//  Converter.swift
//  MediaTools
//
//  Created by Kojirou on 2019/4/30.
//

import Executable

public protocol Converter: Executable {
    
    var input: [String] {get}
    
    var output: String {get}
    
    //    var alternative: [Converter]? {get}
    
    init(input: String, output: String)
    
}
