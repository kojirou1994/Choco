import Signals
import Foundation
import Common

let mpls = try Mpls.init(filePath: "/Volumes/E/BD/[BDMV][Code Geass Boukoku no Akito][Vol.1-Vol.5 Fin]/[BDMV][130129][Code Geass Boukoku no Akito][Vol.01]/BDMV/PLAYLIST/00001.mpls")
print(mpls.remuxMode)

let remuxer = try Remuxer.init(arguments: Array(CommandLine.arguments.dropFirst()))

Signals.trap(signals: [.quit, .int, .kill, .term, .abrt]) { (_) in
    print("bye-bye")
    remuxer.runningProcess?.terminate()
    exit(0)
}

try remuxer.start()
