import Foundation
import ArgumentParser
import KwiftUtility
import Foundation
import KwiftUtility
import libChoco
import MediaUtility
import Logging

extension ChocoMuxer.TimeSummary {
  #if canImport(Darwin)
  static let timeFormatter: DateComponentsFormatter = {
    let f = DateComponentsFormatter()
    f.allowedUnits = [.minute, .second]
    f.unitsStyle = .short
    return f
  }()
  #endif

  private var simpleTimeString: String {
    Timestamp(hour: 0, minute: 0, second: UInt64(endTime.timeIntervalSince(startTime)), milesecond: 0, nanosecond: 0)
      .description
  }

  var usedTimeString: String {
    #if canImport(Darwin)
    return Self.timeFormatter.string(from: startTime, to: endTime) ?? simpleTimeString
    #else
    return simpleTimeString
    #endif
  }
}

struct ChocoCli: ParsableCommand {

  static var muxer: ChocoMuxer?

  static let configuration: CommandConfiguration =
    .init(
      abstract: "Automatic remux blu-ray disc or media files.",
      subcommands: [
        TrackInfo.self,
        TrackHash.self,
        DumpBDMV.self,
        ThinBDMV.self,
        Crop.self,
        MuxFile.self,
        MuxBDMV.self,
        MkvToMp4.self,
        MplsCommand.self,
        TestFilter.self,
        Verify.self,
        Explain.self,
      ]
    )
}

ChocoCli.main()
