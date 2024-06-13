import class Foundation.Operation
import MediaTools
import PosixExecutableLauncher
import SystemUp

final class AudioConvertOperation: Operation, @unchecked Sendable {

  var process: PosixExecutableLauncher.Process.ChildProcess
  let converter: AudioConverter
  let errorHandler: (Error) -> Void

  init(converter: AudioConverter, errorHandler: @escaping (Error) -> Void) {
    self.process = try! converter.executable
      .generateProcess(use: .posix)
      .spawn()

    self.converter = converter
    self.errorHandler = errorHandler
  }

  override func main() {
    do {
      let result = try process.waitOutput()
      if result.status != .exited(0) {
        print("error while converting flac file! \(converter.input)")
      }
    } catch {
      errorHandler(error)
    }
  }

  override func cancel() {
    Signal.terminate.send(to: .processID(process.pid))
    super.cancel()
  }
}
