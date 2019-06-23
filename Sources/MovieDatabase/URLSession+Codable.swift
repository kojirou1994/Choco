//
//  URLSession+Codable.swift
//  Rarbg
//
//  Created by Kojirou on 2019/5/2.
//

import Foundation

private let decoder = JSONDecoder()

extension URLSession {
    
    private func convertHandler<T>(_ completionHandler: @escaping (Result<T, Error>) -> Void)
        -> (Data?, URLResponse?, Error?) -> Void where T: Decodable{
        return { (data, response, error) in
            guard error == nil else {
                completionHandler(.failure(error!))
                return
            }
            guard let data = data else {
                // no data
                completionHandler(.failure(NSError()))
                return
            }
            do {
                let result = try decoder.decode(T.self, from: data)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
    
    public func codableTask<T>(with url: URL, completionHandler: @escaping (Result<T, Error>) -> Void) -> URLSessionDataTask where T: Decodable {
        return dataTask(with: url, completionHandler: convertHandler(completionHandler))
    }
    
    public func codableTask<T>(with request: URLRequest, completionHandler: @escaping (Result<T, Error>) -> Void) -> URLSessionDataTask where T: Decodable {
        return dataTask(with: request, completionHandler: convertHandler(completionHandler))
    }
    
    public func syncCodableTask<T>(with request: URLRequest) throws -> T where T: Decodable {
        return try syncDataTask(request: request) { (data, r, error) -> Result<T, Error> in
            guard error == nil else {
                return .failure(error!)
            }
            guard let data = data else {
                // no data
                return .failure(NSError())
            }
            #if DEBUG
            print(String(decoding: data, as: UTF8.self))
            #endif
            do {
                let result = try decoder.decode(T.self, from: data)
                return .success(result)
            } catch {
                return .failure(error)
            }
        }.get()
    }
    
}
