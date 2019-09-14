import MediaTools
import Foundation

public protocol Converter: Executable {
    
    var inputDescription: String {get}
    
    var outputURL: URL {get}
    
}

extension FFmpegMuxer: Converter {
    public var inputDescription: String {
        input
    }
    
    public var outputURL: URL {
        URL(fileURLWithPath: output)
    }
}

extension FlacEncoder: Converter {
    public var inputDescription: String {
        input
    }
    
    public var outputURL: URL {
        URL(fileURLWithPath: output)
    }
}

extension Mkvmerge: Converter {
    
    public var inputDescription: String {
        inputs.map {$0.file}.joined(separator: "+\n")
    }
    
    public var outputURL: URL {
        return URL(fileURLWithPath: output)
    }
    
}

extension Converter {
    
    public func convert() throws -> Process {
        printTask()
        return try generateProcess()
    }
    
    public func printTask() {
        print("\n\(Self.executableName):\n\(inputDescription)\n->\n\(outputURL.path)")
    }
    
}
