extension CaseIterable where Self: RawRepresentable, RawValue == String {
  static var availableValues: String {
    "available: " + allCases.map(\.rawValue).joined(separator: ", ")
  }
}
