//
//  AVDictionary.swift
//  SwiftFFmpeg
//
//  Created by Kojirou on 2019/4/13.
//

import Foundation
import CFFmpeg

public struct FFmpegDictionary {
    
    internal var metadata: OpaquePointer?
    
    internal init(metadata: OpaquePointer?) {
        self.metadata = metadata
    }
    
    public static func parse(metadata: OpaquePointer?) -> [String : String] {
        var dict = [String: String]()
        var previousEntry: UnsafeMutablePointer<AVDictionaryEntry>?
        while let nextEntry = av_dict_get(metadata, "", previousEntry, AV_DICT_IGNORE_SUFFIX) {
            dict[String(cString: nextEntry.pointee.key)] = String(cString: nextEntry.pointee.value)
            previousEntry = nextEntry
        }
        return dict
    }
    
    public init(dictionary: [String : String]) {
        var p: OpaquePointer?
        
        for (k, v) in dictionary {
            av_dict_set(&p, k, v, 0)
        }
        
        self.metadata = p
    }
    
    public var dictionary: [String: String] {
        return FFmpegDictionary.parse(metadata: metadata)
    }
    
    public subscript(key: String) -> String? {
        get {
            if let value = av_dict_get(metadata, key, nil, 0) {
                return String.init(cString: value.pointee.value)
            } else {
                return nil
            }
        }
        set {
            av_dict_set(&metadata, key, newValue, 0)
        }
    }
    
    public mutating func free() {
        av_dict_free(&metadata)
    }
}
