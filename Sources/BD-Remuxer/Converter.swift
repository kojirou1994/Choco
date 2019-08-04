import MediaTools

public protocol Converter: Executable {
    
    var inputPaths: [URL] {get}
    
    var outputPath: URL {get}
    
}

extension FFmpegMuxer: Converter {
    public var inputPaths: [URL] {
        [URL(fileURLWithPath: input)]
    }
    
    public var outputPath: URL {
        URL(fileURLWithPath: output)
    }
}

extension FlacEncoder: Converter {
    public var inputPaths: [URL] {
        [URL(fileURLWithPath: input)]
    }
    
    public var outputPath: URL {
        URL(fileURLWithPath: output)
    }
}

extension Mkvmerge: Converter {
    public var inputPaths: [URL] {
        return inputs.map { URL(fileURLWithPath: $0.file) }
    }
    
    public var outputPath: URL {
        return URL(fileURLWithPath: output)
    }
    
    
}

//extension MkvmergeMuxer: Converter {
//    public var inputPaths: [Path] {
//        input.map {Path(url: URL(fileURLWithPath: $0))!}
//    }
//
//    public var outputPath: Path {
//        Path(url: URL(fileURLWithPath: output))!
//    }
//}

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
        print("\n\(Self.executableName):\n\(inputPaths.map{$0.path})\n->\n\(outputPath.path)")
    }
    
}
