import Signals
import Foundation
import Common

let remuxer = Remuxer.init()

try remuxer.parse()

Signals.trap(signals: [.quit, .int, .kill, .term, .abrt]) { (_) in
    print("bye-bye")
    remuxer.clear()
    exit(0)
}

try remuxer.run()
