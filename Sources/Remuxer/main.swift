let remuxer = Remuxer.init()

try CommandLine.arguments[1...].forEach(remuxer.remux(bdPath:))
