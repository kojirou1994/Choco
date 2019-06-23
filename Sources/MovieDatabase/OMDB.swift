//
//  File.swift
//  
//
//  Created by Kojirou on 2019/6/7.
//

import Foundation

public class OMDB: Database {
    
    let apikey = "61ab5139"
    
    public init() {
    }
    
    public func get(imdbID: String) throws -> Response {
        guard imdbID.hasPrefix("tt") else {
            throw DatabaseError.invalidImdbID
        }
        return try decodeOMDB(url: "http://www.omdbapi.com/?i=\(imdbID)&plot=full&apikey=\(apikey)")
    }
    
    public func search(title: [String], year: Int?) throws -> OMDB.Response {
        let url: String
        let title = title.joined(separator: "+")
        if let year = year {
            url = "http://www.omdbapi.com/?t=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&plot=full&apikey=\(apikey)&y=\(year)"
        } else {
            url = "http://www.omdbapi.com/?t=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&plot=full&apikey=\(apikey)"
        }
        return try decodeOMDB(url: url)
    }
    
    func decodeOMDB(url: String) throws -> Response {
        let data = try Data.init(contentsOf: URL.init(string: url)!)
        let dic = try JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
        let response = (dic["Response"] as! String) == "True"
        if response {
            return try JSONDecoder().decode(Response.self, from: data)
        } else {
            throw DatabaseError.serverError(dic["Error"] as! String)
        }
    }
    
    public struct Response: Codable {
        
        public let language: String
        
        public let website: String?
        
        public let boxOffice: String?
        
        public let actors: String
        
        public let metascore: String
        
        public let released: String
        
        public let dvd: String?
        
        public let genre: String
        
        public let type: MovieType
        
        public enum MovieType: String, Codable, CustomStringConvertible {
            case series
            case movie
            
            public var description: String { rawValue }
        }
        
        public let imdbRating: String
        
        public let poster: String
        
        public let plot: String
        
        public let runtime: String
        
        public let country: String
        
        public let production: String?
        
        public let title: String
        
        public let imdbVotes: String
        
        public let writer: String
        
        public let rated: String
        
        public let awards: String
        
        public let director: String
        
        public let year: String
        
        public struct Ratings: Codable {
            
            public let value: String
            
            public let source: String
            
            private enum CodingKeys: String, CodingKey {
                case source = "Source"
                case value = "Value"
            }
            
        }
        
        public let ratings: [Ratings]
        
        public let imdbID: String
        
        private enum CodingKeys: String, CodingKey {
            case imdbRating
            case title = "Title"
            case imdbVotes
            case dvd = "DVD"
            case plot = "Plot"
            case released = "Released"
            case awards = "Awards"
            case director = "Director"
            case metascore = "Metascore"
            case actors = "Actors"
            case language = "Language"
            case rated = "Rated"
            case genre = "Genre"
            case website = "Website"
            case ratings = "Ratings"
            case production = "Production"
            case country = "Country"
            case year = "Year"
            case writer = "Writer"
            case type = "Type"
            case runtime = "Runtime"
            case boxOffice = "BoxOffice"
            case imdbID
            case poster = "Poster"
        }
        
    }
    
}
