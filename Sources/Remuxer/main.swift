let remuxer = try Remuxer.init(arguments: Array(CommandLine.arguments.dropFirst()))

try remuxer.start()
