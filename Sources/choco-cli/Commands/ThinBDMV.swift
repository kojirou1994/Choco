import ArgumentParser
import Logging
import SystemPackage
import SystemUp
import SystemFileManager

struct ThinBDMV: ParsableCommand {

  @Option(name: .shortAndLong, help: "Output root directory.")
  var output: String = "./"

  @Option(name: .shortAndLong, help: "Maximum copy bytes.")
  var size: Int = 50 * 1024 * 1024

  @Argument(help: "BDMV path")
  var inputs: [String]

  func run() throws {
    let logger = Logger(label: "thin-bdmv")
    inputs.forEach { input in
      logger.info("START: \(input)")

      var buffer = [UInt8](repeating: 0, count: size)

      func copyLimitedFile(src: FilePath, dst: FilePath) throws {
        let srcFD = try FileDescriptor.open(src, .readOnly)
        defer {
          try? srcFD.close()
        }
        let dstFD = try FileDescriptor.open(dst, .writeOnly, options: [.create, .exclusiveCreate], permissions: .fileDefault)
        defer {
          try? dstFD.close()
        }
        try buffer.withUnsafeMutableBytes { buffer in
          let size = try srcFD.read(into: buffer)
          try dstFD.writeAll(UnsafeRawBufferPointer(rebasing: buffer.prefix(size)))
        }
      }

      do {
        let inputPath = try FileSyscalls.realPath(FilePath(input))
        let inputName = try inputPath.lastComponent.unwrap().string
        logger.info("Directory Name: \(inputName)")

        let outputRootPath = FilePath(output).appending(inputName)

        try Fts.open(path: inputPath, options: .physical).get()
          .closeAfter { stream in
            while let entry = stream.read() {
              if entry.name.hasPrefix(".") {
                continue
              }
              if ![.file, .directoryPre].contains(entry.info) {
                continue
              }
              let newPath = outputRootPath.appending(entry.path.components.dropFirst(inputPath.components.count))
              print(entry.path, "--->", newPath)
              do {
                switch entry.fileStatus!.pointee.fileType {
                case .regular:
                  print("copy")
                  try copyLimitedFile(src: entry.path, dst: newPath)
                case .directory:
                  print("mkdir")
                  try SystemFileManager.createDirectoryIntermediately(.absolute(newPath))
                default:
                  print("skipped file type: \(entry.fileStatus!.pointee.fileType)")
                }
              } catch {
                print("file failed: \(error)")
              }
            }
          }
      } catch {
        logger.error("ERROR: \(error)")
      }
    }
  }

}
