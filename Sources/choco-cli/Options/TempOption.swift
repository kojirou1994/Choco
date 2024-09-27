import ArgumentParser
import SystemPackage
import SystemUp

struct TempOptions: ParsableArguments {
  @Option(help: "Set directory for temp files.")
  private var tmp: String?


  func tmpDirPath(envKey: String = "TMPDIR") -> FilePath {
    FilePath(tmp ?? PosixEnvironment.get(key: "TMPDIR") ?? "/tmp")
  }
}
