import Foundation

let remuxer = Remuxer.init()

func printUsage() {
    print("Remuxer \(DiscType.allCases.map({$0.rawValue}).joined(separator: "|")) INPUT...")
}

guard CommandLine.argc > 2 else {
    printUsage()
    exit(1)
}

guard let type = DiscType.init(rawValue: CommandLine.arguments[1]) else {
    print("Invalid type: \(CommandLine.arguments[1])")
    printUsage()
    exit(1)
}

try CommandLine.arguments[2...].forEach {
    try remuxer.remux(bdPath:$0, type: type)
}
