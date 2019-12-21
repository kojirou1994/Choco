import Signals
import Foundation

let remuxer = try Remuxer(config: .parse())

Signals.trap(signals: [.quit, .int, .kill, .term, .abrt]) { (_) in
    print("Terminating current task...")
    remuxer.terminate()
}

remuxer.start()
