import Foundation
import Executable
import MediaUtility
import MediaTools

struct AudioConverter: Executable {
    let input: URL
    let output: URL
    let preference: BDRemuxerConfiguration.AudioPreference
    let channelCount: Int
    let trackIndex: Int

    static var executableName: String { fatalError() }

    var executableName: String {
        switch preference.codec {
        case .flac:
            return FlacEncoder.executableName
        case .opus:
            return "opusenc"
        }
    }

    var bitrate: Int {
        channelCount * preference.channelBitrate
    }

    var arguments: [String] {
        switch preference.codec {
        case .flac:
            var flac = FlacEncoder(input: input.path, output: output.path)
            flac.level = 8
            flac.forceOverwrite = true
            return flac.arguments
        case .opus:
            return ["--bitrate", bitrate.description, "--discard-comments", input.path, output.path]
        }
    }
}
