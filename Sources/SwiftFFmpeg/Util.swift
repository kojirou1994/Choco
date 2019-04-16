//
//  Util.swift
//  SwiftFFmpeg
//
//  Created by sunlubo on 2018/7/9.
//
import CFFmpeg

internal func dumpUnrecognizedOptions(_ dict: OpaquePointer?) {
    var tag: UnsafeMutablePointer<AVDictionaryEntry>?
    while let next = av_dict_get(dict, "", tag, AV_DICT_IGNORE_SUFFIX) {
        print("Warning: Option `\(String(cString: next.pointee.key))` not recognized.")
        tag = next
    }
}

@usableFromInline
internal func readArray<P, T>(pointer: UnsafePointer<P>?, stop: (P) -> Bool, transform: (P) -> T) -> [T] {
    guard let p = pointer else {
        return []
    }
    var result = [T]()
    for i in 0..<Int.max {
        let v = p[i]
        if stop(v) {
            break
        } else {
            result.append(transform(v))
        }
    }
    return result
}
