public protocol Converter: Executable {
    
    var input: [String] {get}
    
    var output: String {get}
    
    init(input: String, output: String)
    
}
