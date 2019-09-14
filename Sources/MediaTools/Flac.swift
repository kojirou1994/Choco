public struct FlacEncoder: Executable {
    
    public static let executableName: String = "flac"
    
    public let input: String
    
    public let output: String
    
    public var level: Int8 = 5
    
    public var silent: Bool = false
    
    public var forceOverwrite: Bool = false
    
    public init(input: String, output: String) {
        self.input = input
        self.output = output
    }
    
    public var arguments: [String] {
        let realLevel: Int8
        if level < 0 {
            realLevel = 0
        } else if level > 8 {
            realLevel = 8
        } else {
            realLevel = level
        }
        var arg =  ["-\(realLevel)",
                    "-o",
                    output,
                    input]
        if silent {
            arg.append("-s")
        }
        if forceOverwrite {
            arg.append("-f")
        }
        return arg
    }
    
}


public struct FlacMD5 {
    
    public static func calculate(inputs: [String]) throws -> [String] {
        let md5 = try AnyExecutable(executableName: "metaflac", arguments: ["--no-filename", "--show-md5sum"] + inputs).runAndCatch(checkNonZeroExitCode: true)
        return md5.stdout.split(separator: UInt8.init(ascii: "\n")).map {String(decoding: $0, as: UTF8.self)}
    }
    
}
