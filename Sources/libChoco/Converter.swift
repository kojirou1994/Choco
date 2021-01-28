import MediaTools
import Foundation
import ExecutableDescription

public struct Converter {
  let inputDescription: String
  let outputURL: URL
  let executable: AnyExecutable
}

extension Converter {
  init(_ ff: FFmpegCopyMuxer) {
    executable = ff.eraseToAnyExecutable()
    inputDescription = ff.input
    outputURL = URL(fileURLWithPath: ff.output)
  }

  init(_ ff: FlacEncoder) {
    executable = ff.eraseToAnyExecutable()
    inputDescription = ff.input
    outputURL = URL(fileURLWithPath: ff.output)
  }

  init(_ ff: MkvMerge) {
    executable = ff.eraseToAnyExecutable()
    inputDescription = ff.inputs.map{ URL(fileURLWithPath: $0.file).lastPathComponent }.joined(separator: "+\n")
    outputURL = URL(fileURLWithPath: ff.output)
  }

}
