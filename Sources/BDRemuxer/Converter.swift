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
    inputs.map{ URL(fileURLWithPath: $0.file).lastPathComponent }.joined(separator: "+\n")
  }

  public var outputURL: URL {
    return URL(fileURLWithPath: output)
  }

}
