//
//  extensions.swift
//  Remuxer
//
//  Created by Kojirou on 2019/4/11.
//

import Foundation

extension Array where Element: Equatable {
    
    //    func countValue(_ v: Element) -> Int {
    //        return self.reduce(0, { (result, current) -> Int in
    //            if current == v {
    //                return result + 1
    //            } else {
    //                return result
    //            }
    //        })
    //    }
    
    func indexes(of v: Element) -> [Index] {
        var r = [Index]()
        for (index, current) in enumerated() {
            if current == v {
                r.append(index)
            }
        }
        return r
    }
    
}

extension Sequence {
    func count(where predicate: (Element) throws -> Bool) rethrows -> Int {
        var count = 0
        for element in self {
            if try predicate(element) {
                count += 1
            }
        }
        return count
    }
}
