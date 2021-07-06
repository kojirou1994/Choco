import Precondition

public struct CropInfo: Equatable {
  public init(top: Int, bottom: Int, left: Int, right: Int) {
    self.top = top
    self.bottom = bottom
    self.left = left
    self.right = right
  }
  
  public static var zero: Self { .init(top: 0, bottom: 0, left: 0, right: 0) }
  
  public var isZero: Bool {
    self == Self.zero
  }
  
  public let top: Int
  public let bottom: Int
  public let left: Int
  public let right: Int

  public init<S: StringProtocol>(str: S) throws {
    let numbers = try str
      .split(separator: "/")
      .map { try Int($0).unwrap("Invalid number in crop info: \($0), full string: \(str)") }

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
