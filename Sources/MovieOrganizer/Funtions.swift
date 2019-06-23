//
//  File.swift
//  
//
//  Created by Kojirou on 2019/6/8.
//

import Foundation
import MovieDatabase
import ArgumentParser


let supportedFormats = ["mkv", "mp4"]



extension OMDB.Response.MovieType: OptionValue {
    public init(argument: String) throws {
        guard let v = OMDB.Response.MovieType.init(rawValue: argument) else {
            throw ArgumentParserError.invalidOptionValue(argument, "MovieType")
        }
        self = v
    }
}

public class Organizer {
    
    private let workdingMode: OMDB.Response.MovieType
    
    private let fm = FileManager.default
    
    private let rawInputs: [String]
    
    private let outputDir: String?
    
    private let tag: String?
    
    private let omdb = OMDB()
    
    private let tvdb = TVDB(token: nil, lang: .en)
    
    @available(OSX 10.9, *)
    public init<S>(arguments: S) throws where S: Sequence, S.Element == String {
        var inputs: [String] = []
        var mode: OMDB.Response.MovieType = .movie
        var outputDir: String?
        var tag: String?
        let modeA = Option.init(name: "--mode", requireValue: true, description: "work mode") { (v) in
            mode = try .init(argument: v)
        }
        let outA = Option.init(name: "--output", anotherName: "-O", requireValue: true, description: "output dir") { (v) in
            outputDir = v
        }
        let tagA = Option.init(name: "--tag", requireValue: true, description: "tag for inputs") { (v) in
            tag = v
        }
        let parser = ArgumentParser.init(usage: "", options: [modeA, outA, tagA]) { (input) in
            inputs.append(input)
        }
        try parser.parse(arguments: arguments)
        
        self.workdingMode = mode
        self.rawInputs = inputs
        self.outputDir = outputDir
        self.tag = tag
    }
    
    @available(OSX 10.9, *)
    public func start() {
        rawInputs.forEach { (rawInput) in
            do {
                print("Start reading \(rawInput)")
                try organize(rawInput: rawInput, mode: workdingMode)
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    public func organize(rawInput: String, mode: OMDB.Response.MovieType) throws {
        let input = try OrgInput.init(input: rawInput, tag: tag)
        let outputDir = self.outputDir ?? input.path.deletingLastPathComponent
        switch mode {
        case .series:
            try organizeSeries(input, outputDir: outputDir)
        case .movie:
            try organizeMovie(input, outputDir: outputDir)
        }
    }
    
    private func organizeSeries(_ input: OrgInput, outputDir: String) throws {
        let contents = try FileManager.default.contentsOfDirectory(atPath: input.path).filter(checkExtension(filename:))
        if contents.isEmpty {
            throw OrganizerError.emptyFolder
        }
        var episodeIndexes = Set<Int>()
        let parsedTitle = try TitleUtility.parse(input.path.lastPathComponent, type: .series)
        guard let titleSeason = parsedTitle.season else {
            throw OrganizerError.noSeasonNumber
        }
        let episodes = try contents.map { (episode) -> InputEpisode in
            let thisEpisode: Int
            if case let number = episode.deletingPathExtension.components(separatedBy: .whitespacesAndNewlines)[0],
                number.hasPrefix("EP"), let episodeNumber = Int(number[2...]) {
                thisEpisode = episodeNumber
            } else if let numberRange = episode.range(of: "s\\d\\de\\d\\d", options: [String.CompareOptions.caseInsensitive, String.CompareOptions.regularExpression], range: nil, locale: nil) {
                let number = String(episode[numberRange])
                thisEpisode = Int(number[4...5])!
                
                let thisSeason = Int(number[1...2])!
                if thisSeason != titleSeason {
                    throw OrganizerError.mismatchSeasonNumber
                }
            } else {
                throw OrganizerError.invalidEpisodeFilename(episode)
            }
            
            if !episodeIndexes.insert(thisEpisode).inserted {
                throw OrganizerError.duplicateEpisodeNumber(number: thisEpisode, filename: episode)
            }
            print("\(episode)\n--->\nSeason \(titleSeason) Episode \(thisEpisode)")
            return .init(path: input.path.appendingPathComponent(episode), episodeNumber: thisEpisode)
            }.sorted()
        let minEpisodeNumber = episodeIndexes.min()!
        let maxEpisodeNumber = episodeIndexes.max()!
        if maxEpisodeNumber - minEpisodeNumber + 1 != contents.count {
            throw OrganizerError.episodeNotComplete(
                (minEpisodeNumber...maxEpisodeNumber)
                    .filter { !episodeIndexes.contains($0) })
        }
//        dump(episodes)
        let omdbInfo: OMDB.Response
        if let imdb = input.imdb {
            omdbInfo = try omdb.get(imdbID: imdb)
            precondition(omdbInfo.imdbID == imdb)
        } else {
            omdbInfo = try omdb.search(title: parsedTitle.titleParts, year: nil)
        }
        if omdbInfo.type != .series {
            throw OrganizerError.wrongResponse
        }
        print("Got OMDB Info: \(omdbInfo.title)")
        let tvdbInfo = try tvdb.get(imdbID: omdbInfo.imdbID, lang: input.tvdbLang)
        let episodeInfo = try tvdb.getEpisodes(id: tvdbInfo.id, season: titleSeason, lang: input.tvdbLang).data.sorted()
        if episodeInfo.count != episodes.count {
            throw OrganizerError.mismatchEpisodeCount(local: episodes.count, server: episodeInfo.count)
        }
        
        let seriesFolderName = tvdbInfo.seriesName.safeFilename().appending(" [\(omdbInfo.imdbID)]")
        
        print("Series folder name: \(seriesFolderName)")
        
        for (local, remote) in zip(episodes, episodeInfo) {
            precondition(local.episodeNumber == remote.airedEpisodeNumber)
            let newFilename = remote.niceTitle(episodeCount: episodes.count)
            if local.path.lastPathComponent != newFilename {
                try rename(file: local.path, to: newFilename)
            }
        }
        
        let seriesPath = outputDir.appendingPathComponent(omdbInfo.title.first(where: {$0.isLetter})?.uppercased() ?? "#").appendingPathComponent(seriesFolderName)
        
        if !FileManager.default.directoryExists(atPath: seriesPath) {
            try FileManager.default.createDirectory(atPath: seriesPath, withIntermediateDirectories: true, attributes: nil)
        }
        let seasonPath = seriesPath.appendingPathComponent("S\(titleSeason) \(try TitleUtility.generateSuffix(exampleFile: episodes[0].path, tag: input.tag))")
        print("moving from \(input.path) to \(seasonPath)")
        if FileManager.default.fileExists(atPath: seasonPath) {
            throw OrganizerError.outputExists(seasonPath)
        }
        try FileManager.default.moveItem(atPath: input.path, toPath: seasonPath)
        let imdbFile = seasonPath.appendingPathComponent(imdbIDFilename)
        if !fm.fileExists(atPath: imdbFile, isDirectory: nil) {
            try omdbInfo.imdbID.write(toFile: imdbFile, atomically: true, encoding: .utf8)
        }
        
        let tagFile = seasonPath.appendingPathComponent(tagFilename)
        if !fm.fileExists(atPath: tagFile, isDirectory: nil), let tag = input.tag {
            try tag.write(toFile: tagFile, atomically: true, encoding: .utf8)
        }
    }
    
    private func checkExtension(filename: String) -> Bool {
        return supportedFormats.contains(filename.pathExtension.lowercased())
    }
    
    private func checkExtension(url: URL) -> Bool {
        return supportedFormats.contains(url.pathExtension.lowercased())
    }
    
    private func organizeMovie(_ input: OrgInput, outputDir: String) throws {
        let omdbInfo: OMDB.Response
        if let imdb = input.imdb {
            omdbInfo = try omdb.get(imdbID: imdb)
            precondition(omdbInfo.imdbID == imdb)
        } else {
            let parsedTitle = try TitleUtility.parse(input.path.lastPathComponent, type: .movie)
            omdbInfo = try omdb.search(title: parsedTitle.titleParts, year: parsedTitle.year)
        }

        let mainMovieFile: String
        if input.isDir {
            let contents = try fm.contentsOfDirectory(at: URL.init(fileURLWithPath: input.path), includingPropertiesForKeys: [.fileSizeKey], options: []).filter(checkExtension(url:))
            if contents.isEmpty {
                throw OrganizerError.emptyFolder
            }
            mainMovieFile = try contents.max(by: {try $0.resourceValues(forKeys: [URLResourceKey.fileSizeKey]).fileSize! < $1.resourceValues(forKeys: [URLResourceKey.fileSizeKey]).fileSize!})!.path
        } else {
            mainMovieFile = input.path
        }
        
        let newFoldername = omdbInfo.title.safeFilename().appending(" [\(omdbInfo.imdbID)]").appending(try TitleUtility.generateSuffix(exampleFile: mainMovieFile, tag: input.tag))
            
        print(newFoldername)
        let newMainFileTitle = omdbInfo.title.safeFilename()
        let year = omdbInfo.year
        let yearPath = outputDir.appendingPathComponent(year)
        
        try create(directory: yearPath)
        let moviePath = yearPath.appendingPathComponent(newFoldername)
        if fm.fileExists(atPath: moviePath) {
            print("\(moviePath) already exists!")
            throw OrganizerError.outputExists(moviePath)
        }
        print("Move \(input.path) to \(moviePath)")
            
        if input.isDir {
            if mainMovieFile.lastPathComponent.deletingPathExtension != newMainFileTitle {
                try rename(file: mainMovieFile, to: newMainFileTitle)
            }
            try fm.moveItem(atPath: input.path, toPath: moviePath)
        } else {
            try fm.createDirectory(atPath: moviePath, withIntermediateDirectories: false, attributes: nil)
            try fm.moveItem(atPath: input.path, toPath: moviePath.appendingPathComponent(newMainFileTitle).appendingPathExtension(input.path.pathExtension))
        }
        let imdbFile = moviePath.appendingPathComponent(imdbIDFilename)
        if !fm.fileExists(atPath: imdbFile, isDirectory: nil) {
            try omdbInfo.imdbID.write(toFile: imdbFile, atomically: true, encoding: .utf8)
        }
        
        let tagFile = moviePath.appendingPathComponent(tagFilename)
        if !fm.fileExists(atPath: tagFile, isDirectory: nil), let tag = input.tag {
            try tag.write(toFile: tagFile, atomically: true, encoding: .utf8)
        }
    }
    
    private func rename(file atPath: String, to filename: String) throws {
        if atPath.lastPathComponent.deletingPathExtension == filename {
            return
        }
        let ext = atPath.pathExtension
        print("rename from:\n\(atPath.lastPathComponent)\nto:\n\(filename).\(ext)")
        try FileManager.default.moveItem(atPath: atPath, toPath: atPath.deletingLastPathComponent.appendingPathComponent(filename).appendingPathExtension(ext))
    }

    private func create(directory: String) throws {
        if !fm.directoryExists(atPath: directory) {
            try fm.createDirectory(atPath: directory, withIntermediateDirectories: false, attributes: nil)
        }
    }
}

enum OrganizerError: Error {
    case emptyFolder
    case outputExists(String)
    case noSeasonNumber
    case inputNotExist
    case wrongResponse
    case mismatchSeasonNumber
    case mismatchEpisodeCount(local: Int, server: Int)
    case episodeNotComplete([Int])
    case duplicateEpisodeNumber(number: Int, filename: String)
    case invalidEpisodeFilename(String)
}

let imdbIDFilename = ".imdb"
let tagFilename = ".tag"
let tvdbLangFilename = ".tvdb"

struct OrgInput {
    let path: String
    let isDir: Bool
    let imdb: String?
    let tag: String?
    let tvdbLang: TVDBLanguage?
    
    init(input: String, imdb: String? = nil, tag: String?) throws {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: input, isDirectory: &isDir) else {
            throw OrganizerError.inputNotExist
        }
        self.path = input
        self.isDir = isDir.boolValue
        if let imdb = imdb {
            self.imdb = imdb
        } else if isDir.boolValue, case let imdbFilepath = input.appendingPathComponent(imdbIDFilename), FileManager.default.fileExists(atPath: imdbFilepath) {
            self.imdb = try String.init(contentsOfFile: imdbFilepath).trimmingCharacters(in: .whitespacesAndNewlines)
            print("Using existing imdb from .imdb: \(self.imdb!)")
        } else {
            self.imdb = nil
        }
        
        if case let tagFilepath = input.appendingPathComponent(tagFilename), FileManager.default.fileExists(atPath: tagFilepath) {
            self.tag = try String.init(contentsOfFile: tagFilepath).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            self.tag = tag
        }
        
        if case let tvdbFilepath = input.appendingPathComponent(tvdbLangFilename), FileManager.default.fileExists(atPath: tvdbFilepath) {
            self.tvdbLang = TVDBLanguage.init(rawValue: try String.init(contentsOfFile: tvdbFilepath).trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
            self.tvdbLang = nil
        }
    }
}

struct InputEpisode: Comparable {
    static func < (lhs: InputEpisode, rhs: InputEpisode) -> Bool {
        return (lhs.episodeNumber, lhs.path) < (rhs.episodeNumber, rhs.path)
    }
    
    let path: String
    let episodeNumber: Int
}

extension TVDB.Episodes.Data {
    func niceTitle(episodeCount: Int) -> String { "EP\(String.init(format: "%0\(episodeCount.description.count)d", airedEpisodeNumber))\(episodeName == nil ? "" : " \(episodeName!)")".safeFilename("") }
}
