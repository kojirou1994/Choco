import Signals
import Foundation

let remuxer = try Remuxer.init()

Signals.trap(signals: [.quit, .int, .kill, .term, .abrt]) { (_) in
    print("bye-bye")
    remuxer.cancel()
    exit(0)
}

remuxer.run()
