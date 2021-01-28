import TSCBasic
import class Foundation.Operation
import TSCLibc
import MediaTools
import ExecutableLauncher

class AudioConvertOperation: Operation {

  let process: Process
  let converter: AudioConverter
  let errorHandler: (Error) -> Void

  init(converter: AudioConverter, errorHandler: @escaping (Error) -> Void) {
    self.process = try! converter
      .generateProcess(use: TSCExecutableLauncher(outputRedirection: .collect))
    self.converter = converter
    self.errorHandler = errorHandler
  }

  override func main() {
    do {
      try process.launch()
      let result = try process.waitUntilExit()
      if result.exitStatus != .terminated(code: 0) {
        print("error while converting flac file! \(converter.input)")
      }
    } catch {
      errorHandler(error)
    }
  }

  override func cancel() {
    process.signal(SIGTERM)
    super.cancel()
  }
}
