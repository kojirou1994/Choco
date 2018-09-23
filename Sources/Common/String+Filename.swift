//
//  String+Filename.swift
//  Common
//
//  Created by Kojirou on 2018/9/22.
//

import Foundation


extension String {
    
    public var filenameWithoutExtension: String {
        return lastPathComponent.deletingPathExtension
    }
    
    public var filename: String {
        return lastPathComponent
    }
    
}
