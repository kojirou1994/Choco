//
//  Chapter.swift
//  MplsReader
//
//  Created by Kojirou on 2019/2/16.
//

import Foundation

public struct Chapter {
    
    /// 00:00:00.000 ChapterName
    public struct Node {
        public var title: String
        public var timestamp: Timestamp
        
        public init(title: String, timestamp: Timestamp) {
            self.title = title
            self.timestamp = timestamp
        }
    }
    
    public var nodes: [Node]
    
    /// self use
    ///
    /// - Parameter file: <#file description#>
    /// - Throws: <#throws value description#>
    public init(file: String) throws {
        let content = try String.init(contentsOfFile: file)
        nodes = content.split(separator: "\n").compactMap({ (line) -> Node? in
            if line.isEmpty {
                return nil
            } else {
                let parts = line.split(separator: " ")
                //                let time = parts[0].split(separator: ":")
                return .init(title: String(parts[1]), timestamp: Timestamp(String(parts[0]))!)
            }
        })
    }
    
    public init(nodes: [Node]) {
        self.nodes = nodes
    }
    
    public init<C>(timestamps: C) where C: Collection, C.Element == Timestamp {
        self.nodes = timestamps.enumerated().map {Node.init(title: String.init(format: "Chapter %02d", $0.offset+1), timestamp: $0.element)}
    }
    
    public init<C>(mplsChapters: C) where C: Collection, C.Element == MplsChapter {
        self.init(timestamps: mplsChapters.map {$0.relativeTimestamp})
    }
    
    private func padding(number: Int) -> String {
        if number < 10 {
            return "0\(number)"
        } else {
            return .init(describing: number)
        }
    }
    
    enum ReadError: Error {
        case empty
        case extraLine(String)
        case wrongFormat(String)
    }
    
    public init(ogmFile: String) throws {
        let str = try String.init(contentsOfFile: ogmFile)
        let lines = str.split(separator: "\n")
        guard lines.count > 0 else {
            throw ReadError.empty
        }
        guard lines.count % 2 == 0 || !lines.last!.isEmpty else {
            throw ReadError.extraLine(String(lines.last!))
        }
        nodes = .init()
        let nodesCount = lines.count/2
        nodes.reserveCapacity(nodesCount)
        for index in 0..<nodesCount {
            let timestamp = String(lines[index*2])
            let title = String(lines[index*2 + 1])
            nodes.append(.init(title: String(title[14...]), timestamp: Timestamp(String(timestamp[10...]))!))
        }
    }
    
    public func exportOgm() -> String {
        return nodes.enumerated().map { node -> String in
            let index = padding(number: node.offset+1)
            return """
            CHAPTER\(index)=\(node.element.timestamp.description)
            CHAPTER\(index)NAME=\(node.element.title)
            """
            }.joined(separator: "\n")
    }
    
//    public func exportTTXT() -> String {
//        
//    }
    
}
