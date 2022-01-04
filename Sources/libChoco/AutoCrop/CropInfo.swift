import Precondition

public enum CropInfo: Equatable {
  case relative(top: Int32, bottom: Int32, left: Int32, right: Int32)
  case absolute(width: Int32, height: Int32, x: Int32, y: Int32)

  public init<S: StringProtocol>(chocoOutput string: S) throws {
    let numbers = try string
      .split(separator: "/")
      .map { try Int32($0).unwrap("Invalid number in crop info: \($0), full string: \(string)") }

    try preconditionOrThrow(numbers.count == 4, "CropInfo must have 4 numbers")
    self = .relative(top: numbers[0], bottom: numbers[1], left: numbers[2], right: numbers[3])
  }

  public init<S: StringProtocol>(ffmpegOutput string: S) throws {
    let numbers = try string
      .split(separator: ":")
      .map { try Int32($0).unwrap("Invalid number in crop info: \($0), full string: \(string)") }

    try preconditionOrThrow(numbers.count == 4, "CropInfo must have 4 numbers")
    self = .absolute(width: numbers[0], height: numbers[1], x: numbers[2], y: numbers[3])
  }

  public var ffmpegArgument: String {
    switch self {
    case .relative(let top, let bottom, let left, let right):
      return "crop=in_w-\(left + right):in_h-\(top + bottom):\(left):\(top)"
    case .absolute(let width, let height, let left, let top):
      return "crop=\(width):\(height):\(left):\(top)"
    }
  }

//  public var plaInt32ext: String {
//    "\(top)/\(bottom)/\(left)/\(right)"
//  }
}
