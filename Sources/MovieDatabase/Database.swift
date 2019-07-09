//
//  File.swift
//  
//
//  Created by Kojirou on 2019/6/7.
//

import Foundation
import SwiftEnhancement
import MediaTools

//public enum MovieFeature: Hashable {
//    case uhd
//    case custom(String)
//    
//    var string: String {
//        switch self {
//        case .uhd:
//            return "UHD"
//        case .custom(let s):
//            return s
//        }
//    }
//    
//    public func hash(into hasher: inout Hasher) {
//        string.hash(into: &hasher)
//    }
//}

public struct TitleUtility {
    
    public struct ParserResult {
        public let titleParts: [String]
        public let year: Int?
        public let season: Int?
    }
    
    static let endMarks = ["1080p", "2160p", "[UHD]"]
    
    public static func parse(_ str: String, type: OMDB.Response.MovieType) throws -> ParserResult {
        let parts = str.components(separatedBy: CharacterSet.init(charactersIn: ". _()")).filter {!$0.isEmpty}
        if parts.isEmpty {
            throw DatabaseError.invalidFilename
        }
        var endIndex = parts.count
        var year: Int?
        for e in parts.enumerated() {
            if e.element.count == 4, let number = Int(e.element) {
                endIndex = e.offset
                year = number
            } else if TitleUtility.endMarks.contains(e.element) {
                if year == nil {
                    endIndex = e.offset
                }
                break
            }
        }
        if endIndex == 0 {
            endIndex = parts.endIndex
        }
        var season: Int?
        if type == .series {
            let lastPart = parts[endIndex-1]
            if lastPart[0].uppercased() == "S", let v = Int(String(lastPart[1...])) {
                season = v
                endIndex -= 1
            }
        }
        return .init(titleParts: Array(parts[..<endIndex]), year: year, season: season)
    }
    
    public static func generateSuffix(exampleFile: String?, tag: String?) throws -> String {
//        var title = "\(title.safeFilename()) [\(imdbID)]"
        var suffix = ""
        if let exampleFile = exampleFile {
            let isUHD: Bool
            let mkvinfo = try MkvmergeIdentification.init(filePath: exampleFile)
            if let track = mkvinfo.tracks.first(where: {$0.type == .video}),
                let resolution = track.properties.displayDimensions,
                let x = resolution.firstIndex(of: "x"),
                let w = Int(resolution[..<x]), let h = Int(resolution[resolution.index(after: x)...]) {
                isUHD = w > 1920 || h > 1080
            } else {
                isUHD = false
            }
            if isUHD {
                suffix.append(" [UHD]")
            }
        }
        if let tag = tag?.safeFilename("") {
            suffix.append(" [\(tag)]")
        }
        return suffix
    }
}

public enum DatabaseError: Error {
    case invalidFilename
    case inputNotExist
    case outputExists
    case invalidImdbID
    case serverError(String)
}

public protocol Database {
    associatedtype Response
    func get(imdbID: String) throws -> Response
    func search(title: [String], year: Int?) throws -> Response
}

extension Database {
    public func search(fullTitle: String, type: OMDB.Response.MovieType) throws -> Response {
        let parsed = try TitleUtility.parse(fullTitle, type: type)
        #if DEBUG
        print("split result: \(parsed)")
        #endif
        return try search(title: parsed.titleParts, year: parsed.year)
    }
}
