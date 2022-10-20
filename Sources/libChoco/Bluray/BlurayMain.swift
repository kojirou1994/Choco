import TSCExecutableLauncher

func getMainPlaylist(at path: String) throws -> UInt32 {
  let result = try AnyExecutable(executableName: "bd-utility", arguments: ["main-playlist", path])
    .launch(use: TSCExecutableLauncher())

  let string = try result.utf8Output().trimmingCharacters(in: .whitespacesAndNewlines)

  return try UInt32(string).unwrap("invalid main playlist output: \(string)")
}
