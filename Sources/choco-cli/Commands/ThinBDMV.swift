import ArgumentParser
import Logging
import SystemPackage
import SystemUp
import SystemFileManager

struct ThinBDMV: ParsableCommand {

  @Option(name: .shortAndLong, help: "Output root directory.")
  var output: String = "./"

  @Flag
  var dry: Bool = false

  @Option(name: .shortAndLong, help: "Maximum copy bytes.")
  var size: Int = 50 * 1024 * 1024

  @Argument(help: "BDMV path")
  var inputs: [String]

  func run() throws {
    let logger = Logger(label: "thin-bdmv")
    let outputPath = try FileSyscalls.realPath(FilePath(output))
    var buffer = [UInt8](repeating: 0, count: size)

    inputs.forEach { input in
      logger.info("START: \(input)")

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

        let outputRootPath = outputPath.appending(inputName)
        try SystemFileManager.createDirectoryIntermediately(.absolute(outputRootPath))

        let allContents = try SystemFileManager.subpathsOfDirectory(atPath: inputPath)
        print("Total items: \(allContents.count)")
        allContents.forEach { relativePath in
          let absolutePath = inputPath.appending(relativePath.components)
          let newPath = outputRootPath.appending(relativePath.components)
          print(absolutePath, "--->", newPath)
          if dry {
            print("DRY RUN")
            return
          }
          do {
            let fileType = try SystemFileManager.fileStatus(.absolute(absolutePath)).get().fileType
            switch fileType {
            case .regular:
              print("copy")
              try copyLimitedFile(src: absolutePath, dst: newPath)
            case .directory:
              print("mkdir")
              try SystemFileManager.createDirectoryIntermediately(.absolute(newPath))
            default:
              print("warning: skipped file type: \(fileType)")
            }
          } catch {
            print("file failed: \(error)")
          }
        }
      } catch {
        logger.error("ERROR: \(error)")
      }
    }
  }

}
