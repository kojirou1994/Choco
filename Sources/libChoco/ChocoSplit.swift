public enum ChocoSplit {
  case everyChap(Int)
  case eachChap([Int])

  public init?(argument: String) {
    guard let sepIndex = argument.firstIndex(of: ":") else {
      return nil
    }
    let type = argument[..<sepIndex]
    let body = argument[sepIndex...].dropFirst()
    switch type {
    case "everyChap":
      guard let count = Int(body) else {
        return nil
      }
      self = .everyChap(count)
    case "eachChap":
      var chaps = [Int]()
      for str in body.split(separator: ",") {
        guard let int = Int(str) else {
          return nil
        }
        chaps.append(int)
      }
      self = .eachChap(chaps)
    default:
      return nil
    }
  }
}
