public struct FlacConverter: Executable {
    
    public static let executableName: String = "flac"
    
    public var input: String
    
    public var output: String
    
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
