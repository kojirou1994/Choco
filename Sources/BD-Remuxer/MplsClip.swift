//
//  MplsClip.swift
//  Common
//
//  Created by Kojirou on 2018/9/22.
//

import Foundation
import MplsReader
import Path

public struct MplsClip {
    public let fileName: Path
    public let duration: Timestamp
    public let trackLangs: [String]
    public let m2tsPath: Path
    public let chapterPath: String?
    public let index: Int?
    
    public init(fileName: Path, duration: Timestamp, trackLangs: [String], m2tsPath: Path, chapterPath: String?, index: Int?) {
        self.fileName = fileName
        self.duration = duration
        self.trackLangs = trackLangs
        self.m2tsPath = m2tsPath
        self.chapterPath = chapterPath
        self.index = index
    }
}

extension MplsClip: CustomStringConvertible {
    
    public var description: String {
        return "\(fileName.basename()) -> \(m2tsPath.lastPathComponent) -> \(chapterPath ?? "no chapter file.")"
    }
    
}


