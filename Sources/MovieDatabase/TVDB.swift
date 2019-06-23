//
//  File.swift
//  
//
//  Created by Kojirou on 2019/6/7.
//

import Foundation
import FoundationEnhancement

public enum TVDBLanguage: String {
    case en
    case sv
    case no
    case da
    case fi
    case nl
    case de
    case it
    case es
    case fr
    case pl
    case hu
    case el
    case tr
    case ru
    case he
    case ja
    case pt
    case zh
    case cs
    case sl
    case hr
    case ko
}

let authString = """
{
"apikey": "FA08YM2KBUVHN10M",
"userkey": "49AXIAGA0SD34UVI",
"username": "kojirouhtclut"
}
"""

public class TVDB: Database {
    
    let urlSession = URLSession.shared
    
    let token: String
    
    let lang: TVDBLanguage
    
    func request(url: URL, body: String? = nil, post: Bool = false, lang: TVDBLanguage? = nil) -> URLRequest {
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = [
            "Accept" : "application/json",
            "Authorization" : "Bearer \(token)",
            "Content-Type" : "application/json",
            "Accept-Language": "\(lang ?? self.lang)"
        ]
        req.httpBody = body?.data(using: .utf8)
        if post {
            req.httpMethod = "POST"
        }
        return req
    }
    
    public init(token: String? = nil, lang: TVDBLanguage = .en) {
        if let token = token {
            self.token = token
        } else {
            
            struct Token: Decodable {
                let token: String
            }
            
            var req = URLRequest.init(url: URL.init(string: "https://api.thetvdb.com/login")!)
            req.httpMethod = "POST"
            req.allHTTPHeaderFields = [
                "Accept" : "application/json",
                "Content-Type" : "application/json"
            ]
            req.httpBody = Data(authString.utf8)
            let result: Token = try! urlSession.syncCodableTask(with: req)
            
            self.token = result.token
            print("Got TVDB token: \(self.token)")
        }
        self.lang = lang
    }
    
    public func search(title: [String], year: Int?) throws -> TVDB.Response {
        fatalError()
    }
    
    public struct Response: Codable {
        
        public let aliases: [String]
        
        public let id: Int
        
        public let network: String
        
        public let firstAired: String
        
        public let slug: String
        
        public let banner: String
        
        public let status: String
        
        public let overview: String?
        
        public let seriesName: String
        
        private enum CodingKeys: String, CodingKey {
            case aliases
            case id
            case network
            case overview
            case slug
            case banner
            case seriesName
            case firstAired
            case status
        }
        
    }
    
    public struct SearchIMDB: Codable {
        
        
        public let data: [Response]
        
        private enum CodingKeys: String, CodingKey {
            case data
        }
        
    }

    public struct Episodes: Codable {
        
        public struct Data: Codable, Comparable {
            public static func < (lhs: TVDB.Episodes.Data, rhs: TVDB.Episodes.Data) -> Bool {
                return lhs.airedEpisodeNumber < rhs.airedEpisodeNumber
            }
            
            public let thumbWidth: String?
            
            public let episodeName: String?
            
            public let directors: [String]
            
            public let writers: [String]
            
            public let imdbId: String
            
            public let thumbAuthor: Int
            
            public let director: String
            
            public let airedSeason: Int
            
            public let firstAired: String
            
            public let showUrl: String
            
            public let filename: String
            
            public let lastUpdatedBy: Int
            
            public let overview: String?
            
            public let thumbHeight: String?
            
            public let airsAfterSeason: Int?
            
            public let seriesId: Int
            
            public let dvdEpisodeNumber: Int?
            
            public let airsBeforeSeason: Int?
            
            public let airsBeforeEpisode: Int?
            
            public let airedEpisodeNumber: Int
            
            public let airedSeasonID: Int
            
            public struct Language: Codable, Equatable {
                
                public let episodeName: String
                
                public let overview: String
                
                private enum CodingKeys: String, CodingKey {
                    case overview
                    case episodeName
                }
                
            }
            
            public let language: Language
            
            public let guestStars: [String]
            
            public let siteRatingCount: Int
            
            public let dvdSeason: Int?
            
            public let lastUpdated: Int
            
            public let productionCode: String
            
            public let thumbAdded: String
            
            public let absoluteNumber: Int?
            
            public let dvdChapter: Int?
            
            public let dvdDiscid: String
            
            public let siteRating: Double
            
            public let id: Int
            
            private enum CodingKeys: String, CodingKey {
                case dvdDiscid
                case productionCode
                case absoluteNumber
                case lastUpdatedBy
                case dvdChapter
                case siteRatingCount
                case thumbHeight
                case firstAired
                case dvdEpisodeNumber
                case writers
                case thumbWidth
                case overview
                case director
                case thumbAuthor
                case seriesId
                case airsBeforeEpisode
                case siteRating
                case language
                case id
                case airedSeason
                case thumbAdded
                case imdbId
                case airsBeforeSeason
                case dvdSeason
                case airsAfterSeason
                case guestStars
                case directors
                case lastUpdated
                case airedEpisodeNumber
                case showUrl
                case episodeName
                case filename
                case airedSeasonID
            }
            
        }
        
        public let data: [Data]
        
        public struct Links: Codable {
            
            public let prev: Int?
            
            public let next: Int?
            
            public let last: Int
            
            public let first: Int
            
            private enum CodingKeys: String, CodingKey {
                case first
                case prev
                case next
                case last
            }
            
        }
        
        public let links: Links
        
        private enum CodingKeys: String, CodingKey {
            case links
            case data
        }
        
    }
    
    public func get(imdbID: String) throws -> TVDB.Response {
        return try get(imdbID: imdbID, lang: nil)
    }

    public func get(imdbID: String, lang: TVDBLanguage?) throws -> TVDB.Response {
        let searchResult = try urlSession.syncCodableTask(with: request(url: URL.init(string: "https://api.thetvdb.com/search/series?imdbId=\(imdbID)")!, lang: lang)) as SearchIMDB
//        precondition(searchResult.data.count <= 1)
        if let data = searchResult.data.first {
            return data
        } else {
            throw DatabaseError.serverError(String.init(describing: searchResult))
        }
        
    }
    
    public func getEpisodes(id: Int, season: Int, lang: TVDBLanguage? = nil) throws -> Episodes {
        let episodes = try urlSession.syncCodableTask(with: request(url: URL.init(string: "https://api.thetvdb.com/series/\(id)/episodes/query?airedSeason=\(season)")!, lang: lang)) as Episodes
        return episodes
    }
    
}
