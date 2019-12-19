import TSCBasic
import class Foundation.Operation
import TSCLibc
import MediaTools

final class FlacConvertOperation: Operation {

    let process: Process
    let flac: FlacEncoder

    public init(flac: FlacEncoder) {
        self.process = try! flac.generateTSCProcess(outputRedirection: .collect, startNewProcessGroup: false)
        self.flac = flac
    }

    override public func main() {
        try! process.launch()
        let result = try! process.waitUntilExit()
        if result.exitStatus != .terminated(code: 0) {
            print("error while converting flac file! \(flac.input)")
        }
    }

    override public func cancel() {
        process.signal(SIGTERM)
    }
}
