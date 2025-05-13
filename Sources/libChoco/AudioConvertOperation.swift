import class Foundation.Operation
import MediaTools
import PosixExecutableLauncher
import SystemUp
import Command

final class AudioConvertOperation: Operation, @unchecked Sendable {

  var process: Command.ChildProcess
  let converter: AudioConverter
  let errorHandler: (Error) -> Void

  init(converter: AudioConverter, errorHandler: @escaping (Error) -> Void) {
    self.process = try! Command(executable: converter.executable)
      .spawn()

    self.converter = converter
    self.errorHandler = errorHandler
  }

  override func main() {
    do {
      let result = try process.waitOutput()
      if !result.status.isSuccess {
        print("error while converting flac file! \(converter.input)")
      }
    } catch {
      errorHandler(error)
    }
  }

  override func cancel() {
    Signal.kill.send(to: .processID(process.pid))
    super.cancel()
  }
}
