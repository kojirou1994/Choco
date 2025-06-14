import Precondition

public enum CropInfo: Equatable {
  case relative(top: Int32, bottom: Int32, left: Int32, right: Int32)
  case absolute(Absolute)

  public init<S: StringProtocol>(chocoOutput string: S) throws {
    let numbers = try string
      .split(separator: "/")
      .map { try Int32($0).unwrap("Invalid number in crop info: \($0), full string: \(string)") }

    try preconditionOrThrow(numbers.count == 4, "CropInfo must have 4 numbers")
    self = .relative(top: numbers[0], bottom: numbers[1], left: numbers[2], right: numbers[3])
  }

  public init<S: StringProtocol>(mkvProperty string: S) throws {
    let numbers = try string
      .split(separator: ",")
      .map { try Int32($0).unwrap("Invalid number in crop info: \($0), full string: \(string)") } // it's UInt actually

    try preconditionOrThrow(numbers.count == 4, "CropInfo must have 4 numbers")
    self = .relative(top: numbers[1], bottom: numbers[3], left: numbers[0], right: numbers[2])
  }

  public var ffmpegArgument: String {
    switch self {
    case .relative(let top, let bottom, let left, let right):
      return "crop=in_w-\(left + right):in_h-\(top + bottom):\(left):\(top)"
    case .absolute(let absolute):
      return "crop=\(absolute.width):\(absolute.height):\(absolute.x):\(absolute.y)"
    }
  }

//  public var plaInt32ext: String {
//    "\(top)/\(bottom)/\(left)/\(right)"
//  }

  public struct Absolute: Equatable, BitwiseCopyable {
    public var width: Int32, height: Int32, x: Int32, y: Int32

    public init(width: Int32, height: Int32, x: Int32, y: Int32) {
      self.width = width
      self.height = height
      self.x = x
      self.y = y
    }

    public init<S: StringProtocol>(ffmpegOutput string: S) throws {
      let numbers = try string
        .split(separator: ":")
        .map { try Int32($0).unwrap("Invalid number in crop info: \($0), full string: \(string)") }

      try preconditionOrThrow(numbers.count == 4, "CropInfo must have 4 numbers")
      self.init(width: numbers[0], height: numbers[1], x: numbers[2], y: numbers[3])
    }
  }
}
