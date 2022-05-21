import ArgumentParser
import libChoco

struct Bitrate: ParsableCommand {

  @Flag
  var reduce: Bool = false

  @Argument
  var channelsCount: Int

  @Argument
  var bitrate: Int

  func run() throws {
    let b = audioBitrate(bitratePerChannel: bitrate, channelCount: channelsCount, reduceBitrate: reduce)
    print("\(b) kB/s")
  }

}
