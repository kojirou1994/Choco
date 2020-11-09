import Precondition

public struct CropInfo {
  public let top: Int
  public let bottom: Int
  public let left: Int
  public let right: Int

  public init<S: StringProtocol>(str: S) throws {
    let numbers = try str.split(separator: "/").map { try Int($0).unwrap("Invalid number: \($0)") }
    try preconditionOrThrow(numbers.count == 4, "CropInfo must have 4 numbers")
    top = numbers[0]
    bottom = numbers[1]
    left = numbers[2]
    right = numbers[3]
  }

  public var ffmpegArgument: String {
    "crop=in_w-\(left + right):in_h-\(top + bottom):\(left):\(top)"
  }

  public var plainText: String {
    "\(top)/\(bottom)/\(left)/\(right)"
  }
}
