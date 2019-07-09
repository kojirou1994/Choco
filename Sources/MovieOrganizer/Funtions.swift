//
//  File.swift
//  
//
//  Created by Kojirou on 2019/6/8.
//

import Foundation
import MovieDatabase
import ArgumentParser
import Path

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
    
    private let outputDir: Path?
    
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
        if let v = outputDir {
            self.outputDir = Path(url: URL(fileURLWithPath: v))!
        } else {
            self.outputDir = nil
        }
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
        let outputDir = self.outputDir ?? input.path.parent
        switch mode {
        case .series:
            try organizeSeries(input, outputDir: outputDir)
        case .movie:
            try organizeMovie(input, outputDir: outputDir)
        }
    }
    
    private func organizeSeries(_ seriesInput: OrgInput, outputDir: Path) throws {
        let contents = try seriesInput.path.ls().map {$0.path}.filter(checkExtension(filename:))
        if contents.isEmpty {
            throw OrganizerError.emptyFolder
        }
        var episodeIndexes = Set<Int>()
        let parsedTitle = try TitleUtility.parse(seriesInput.path.basename(), type: .series)
        guard let titleSeason = parsedTitle.season else {
            throw OrganizerError.noSeasonNumber
        }
        let episodes = try contents.map { (episode) -> InputEpisode in
            let thisEpisode: Int
            if case let number = episode.basename(dropExtension: true).components(separatedBy: .whitespacesAndNewlines)[0],
                number.hasPrefix("EP"), let episodeNumber = Int(number[2...]) {
                thisEpisode = episodeNumber
            } else if let numberRange = episode.string.range(of: "s\\d\\de\\d\\d", options: [String.CompareOptions.caseInsensitive, String.CompareOptions.regularExpression], range: nil, locale: nil) {
                let number = String(episode.string[numberRange])
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
            return .init(path: episode, episodeNumber: thisEpisode)
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
        if let imdb = seriesInput.imdb {
            omdbInfo = try omdb.get(imdbID: imdb)
            precondition(omdbInfo.imdbID == imdb)
        } else {
            omdbInfo = try omdb.search(title: parsedTitle.titleParts, year: nil)
        }
        if omdbInfo.type != .series {
            throw OrganizerError.wrongResponse
        }
        print("Got OMDB Info: \(omdbInfo.title)")
        let tvdbInfo = try tvdb.get(imdbID: omdbInfo.imdbID, lang: seriesInput.tvdbLang)
        let episodeInfo = try tvdb.getEpisodes(id: tvdbInfo.id, season: titleSeason, lang: seriesInput.tvdbLang).data.sorted()
        if episodeInfo.count != episodes.count {
            throw OrganizerError.mismatchEpisodeCount(local: episodes.count, server: episodeInfo.count)
        }
        
        let seriesFolderName = tvdbInfo.seriesName.safeFilename().appending(" [\(omdbInfo.imdbID)]")
        
        print("Series folder name: \(seriesFolderName)")
        
        for (local, remote) in zip(episodes, episodeInfo) {
            precondition(local.episodeNumber == remote.airedEpisodeNumber)
            let newFilename = remote.niceTitle(episodeCount: episodes.count)
            if local.path.basename() != newFilename {
                try rename(file: local.path, to: newFilename)
            }
        }
        
        let seriesPath = outputDir.join(omdbInfo.title.first(where: {$0.isLetter})?.uppercased() ?? "#").join(seriesFolderName)
        
        if !FileManager.default.directoryExists(atPath: seriesPath.string) {
            try seriesPath.mkdir()
        }
        let seasonPath = seriesPath.join("S\(titleSeason) \(try TitleUtility.generateSuffix(exampleFile: episodes[0].path.string, tag: seriesInput.tag))")
        print("moving from \(seriesInput.path) to \(seasonPath)")
        if seasonPath.exists {
            throw OrganizerError.outputExists(seasonPath)
        }
        
        try seriesInput.path.move(into: seasonPath)
        let imdbFile = seasonPath.join(imdbIDFilename)
        if !imdbFile.exists {
            try omdbInfo.imdbID.write(toFile: imdbFile.string, atomically: true, encoding: .utf8)
        }
        
        let tagFile = seasonPath.join(tagFilename)
        if !tagFile.exists, let tag = seriesInput.tag {
            try tag.write(toFile: tagFile.string, atomically: true, encoding: .utf8)
        }
    }
    
    private func checkExtension(filename: Path) -> Bool {
        return supportedFormats.contains(filename.extension.lowercased())
    }
    
    private func checkExtension(url: URL) -> Bool {
        return supportedFormats.contains(url.pathExtension.lowercased())
    }
    
    private func organizeMovie(_ movieInput: OrgInput, outputDir: Path) throws {
        let omdbInfo: OMDB.Response
        if let imdb = movieInput.imdb {
            omdbInfo = try omdb.get(imdbID: imdb)
            precondition(omdbInfo.imdbID == imdb)
        } else {
            let parsedTitle = try TitleUtility.parse(movieInput.path.basename(), type: .movie)
            omdbInfo = try omdb.search(title: parsedTitle.titleParts, year: parsedTitle.year)
        }

        let mainMovieFile: Path
        if movieInput.isDir {
            let contents = try fm.contentsOfDirectory(at: URL.init(fileURLWithPath: movieInput.path.string), includingPropertiesForKeys: [.fileSizeKey], options: []).filter(checkExtension(url:))
            if contents.isEmpty {
                throw OrganizerError.emptyFolder
            }
            mainMovieFile = Path(url: try contents.max(by: {try $0.resourceValues(forKeys: [URLResourceKey.fileSizeKey]).fileSize! < $1.resourceValues(forKeys: [URLResourceKey.fileSizeKey]).fileSize!})!)!
        } else {
            mainMovieFile = movieInput.path
        }
        
        let newFoldername = omdbInfo.title.safeFilename().appending(" [\(omdbInfo.imdbID)]").appending(try TitleUtility.generateSuffix(exampleFile: mainMovieFile.string, tag: movieInput.tag))
            
        print(newFoldername)
        let newMainFileTitle = omdbInfo.title.safeFilename()
        let year = omdbInfo.year
        let yearPath = outputDir.join(year)
        
        try create(directory: yearPath)
        let moviePath = yearPath.join(newFoldername)
        if moviePath.exists {
            print("\(moviePath) already exists!")
            throw OrganizerError.outputExists(moviePath)
        }
        print("Move \(movieInput.path) to \(moviePath)")
            
        if movieInput.isDir {
            if mainMovieFile.basename(dropExtension: true) != newMainFileTitle {
                try rename(file: mainMovieFile, to: newMainFileTitle)
            }
            try movieInput.path.move(to: moviePath)
        } else {
            try moviePath.mkdir()
            try movieInput.path.move(to: moviePath.join("\(newMainFileTitle).\(movieInput.path.extension)"))
        }
        let imdbFile = moviePath.join(imdbIDFilename)
        if !imdbFile.exists {
            try omdbInfo.imdbID.write(toFile: imdbFile.string, atomically: true, encoding: .utf8)
        }
        
        let tagFile = moviePath.join(tagFilename)
        if !tagFile.exists, let tag = movieInput.tag {
            try tag.write(toFile: tagFile.string, atomically: true, encoding: .utf8)
        }
    }
    
    private func rename(file atPath: Path, to filename: String) throws {
        if atPath.basename(dropExtension: true) == filename {
            return
        }
        let ext = atPath.extension
        print("rename from:\n\(atPath.basename())\nto:\n\(filename).\(ext)")
        try atPath.rename(to: "\(filename).\(ext)")
    }

    private func create(directory: Path) throws {
        if !directory.exists {
            try directory.mkdir()
        }
    }
}

enum OrganizerError: Error {
    case emptyFolder
    case outputExists(Path)
    case noSeasonNumber
    case inputNotExist
    case wrongResponse
    case mismatchSeasonNumber
    case mismatchEpisodeCount(local: Int, server: Int)
    case episodeNotComplete([Int])
    case duplicateEpisodeNumber(number: Int, filename: Path)
    case invalidEpisodeFilename(Path)
}

let imdbIDFilename = ".imdb"
let tagFilename = ".tag"
let tvdbLangFilename = ".tvdb"

struct OrgInput {
    let path: Path
    let isDir: Bool
    let imdb: String?
    let tag: String?
    let tvdbLang: TVDBLanguage?
    
    init(input: String, imdb: String? = nil, tag: String?) throws {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: input, isDirectory: &isDir) else {
            throw OrganizerError.inputNotExist
        }
        let path = Path(url: URL(fileURLWithPath: input))!
        self.path = path
        self.isDir = isDir.boolValue
        if let imdb = imdb {
            self.imdb = imdb
        } else if isDir.boolValue, case let imdbFilepath = path.join(imdbIDFilename), imdbFilepath.exists {
            self.imdb = try String.init(contentsOfFile: imdbFilepath.string).trimmingCharacters(in: .whitespacesAndNewlines)
            print("Using existing imdb from .imdb: \(self.imdb!)")
        } else {
            self.imdb = nil
        }
        
        if case let tagFilepath = path.join(tagFilename),
            tagFilepath.exists {
            self.tag = try String.init(contentsOfFile: tagFilepath.string).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            self.tag = tag
        }
        
        if case let tvdbFilepath = path.join(tvdbLangFilename),
            tvdbFilepath.exists {
            self.tvdbLang = TVDBLanguage.init(rawValue: try String.init(contentsOfFile: tvdbFilepath.string).trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
            self.tvdbLang = nil
        }
    }
}

struct InputEpisode: Comparable {
    static func < (lhs: InputEpisode, rhs: InputEpisode) -> Bool {
        return (lhs.episodeNumber, lhs.path) < (rhs.episodeNumber, rhs.path)
    }
    
    let path: Path
    let episodeNumber: Int
}

extension TVDB.Episodes.Data {
    func niceTitle(episodeCount: Int) -> String { "EP\(String.init(format: "%0\(episodeCount.description.count)d", airedEpisodeNumber))\(episodeName == nil ? "" : " \(episodeName!)")".safeFilename("") }
}
