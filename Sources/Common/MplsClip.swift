//
//  MplsClip.swift
//  Common
//
//  Created by Kojirou on 2018/9/22.
//

import Foundation
import MplsReader

public struct MplsClip {
    public let fileName: String
    public let duration: Timestamp
    public let trackLangs: [String]
    public let m2tsPath: String
    public let chapterPath: String?
    public let index: Int?
}

extension MplsClip: CustomStringConvertible {
    
    public var description: String {
        return "\(fileName.filename) -> \(m2tsPath.filename) -> \(chapterPath ?? "no chapter file.")"
    }
    
}

extension MplsClip {
    
    public var baseFilename: String {
        if let index = index {
            return "\(index)-\(m2tsPath.filenameWithoutExtension)"
        } else {
            return m2tsPath.filenameWithoutExtension
        }
    }
    
}
