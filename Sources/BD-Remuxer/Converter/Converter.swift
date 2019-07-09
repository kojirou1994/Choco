import Path
import MediaTools

public protocol Converter: Executable {
    
    var inputPaths: [Path] {get}
    
    var outputPath: Path {get}
    
}

extension FFmpegMuxer: Converter {
    public var inputPaths: [Path] {
        [Path(url: URL(fileURLWithPath: input))!]
    }
    
    public var outputPath: Path {
        Path(url: URL(fileURLWithPath: output))!
    }
}

extension FlacConverter: Converter {
    public var inputPaths: [Path] {
        [Path(url: URL(fileURLWithPath: input))!]
    }
    
    public var outputPath: Path {
        Path(url: URL(fileURLWithPath: output))!
    }
}
extension MkvmergeMuxer: Converter {
    public var inputPaths: [Path] {
        input.map {Path(url: URL(fileURLWithPath: $0))!}
    }
    
    public var outputPath: Path {
        Path(url: URL(fileURLWithPath: output))!
    }
}

import Foundation

//public protocol Converter: Executable {
//
//    var input: String {get}
//
//    var output: String {get}
//
////    var alternative: [Converter]? {get}
//
//    init(input: String, output: String)
//
//}

extension Converter {
    
    public func convert() throws -> Process {
        //        try checkPath()
        printTask()
        return try generateProcess()
    }
    
    //    func checkPath() throws {
    //        if input == output {
    //            throw RemuxerError.sameFilename
    //        }
    //    }
    
    public func printTask() {
        print("\n\(Self.executableName):\n\(inputPaths)\n->\n\(outputPath)")
    }
    
}
