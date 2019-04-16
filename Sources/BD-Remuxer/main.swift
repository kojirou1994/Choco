import Signals
import Foundation
import Common

let remuxer = try Remuxer.init()

Signals.trap(signals: [.quit, .int, .kill, .term, .abrt]) { (_) in
    print("bye-bye")
    remuxer.clear()
    exit(0)
}

remuxer.run()
