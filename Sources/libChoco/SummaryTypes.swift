import Foundation

extension ChocoMuxer {

  public struct TimeSummary {
    internal init(startTime: Date, endTime: Date = .init()) {
      self.startTime = startTime
      self.endTime = endTime
    }

    public let startTime: Date
    public let endTime: Date
  }

  public struct IOFileInfo {
    internal init(path: URL) {
      self.path = path
      self.size = (try? fm.attributesOfItem(atURL: path)[.size] as? UInt64) ?? 0
    }

    public let path: URL
    public let size: UInt64
  }

  public struct BDMVSummary {
    public struct PlaylistTask {
      public let playlistIndex: Int16
      public let segments: [Int16]
      public let segmentsSize: UInt
      public let output: Result<IOFileInfo, ChocoError>
      public let timeSummary: TimeSummary
    }
    public let input: URL
    public let outputDirectory: URL
    public let timeSummary: TimeSummary
    public let tasks: [PlaylistTask]
  }

  public struct FileSummary {
    public struct FileTask {
      internal init(input: ChocoMuxer.IOFileInfo, output: Result<ChocoMuxer.IOFileInfo, ChocoError>, timeSummary: ChocoMuxer.TimeSummary) {
        self.input = input
        self.output = output
        self.timeSummary = timeSummary
      }

      public let input: IOFileInfo
      public let output: Result<IOFileInfo, ChocoError>
      public let timeSummary: TimeSummary
    }
    public let files: [FileTask]
    public let normalFiles: [NormalFileTask]

    public struct NormalFileTask {
      public let input: IOFileInfo
      public let output: Result<IOFileInfo, ChocoError>
    }
  }
}
