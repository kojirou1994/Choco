public struct FlacMD5 {
    
    public static func calculate(inputs: [String]) throws -> [String] {
        let md5 = try AnyExecutable(executableName: "metaflac", arguments: ["--no-filename", "--show-md5sum"] + inputs).runAndCatch(checkNonZeroExitCode: true)
        return md5.stdout.split(separator: UInt8.init(ascii: "\n")).map {String(decoding: $0, as: UTF8.self)}
    }
    
}
