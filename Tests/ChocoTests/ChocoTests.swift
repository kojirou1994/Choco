import XCTest
import libChoco

final class ChocoTests: XCTestCase {
  func testScriptTemplate() throws {
    _ = "/Volumes/Source/Sample.mp4"
    _ = """
    import vapoursynth as vs
    core = vs.get_core()
    v = core.ffms2.Source({{{filePath}}}, fpsnum=30000, fpsden=1001, format=vs.YUV420P{{{encoderDepth}}})
    v = core.vivtc.VFM(clip=v, order=1)
    v = core.vivtc.VDecimate(clip=v)
    v.set_output()
    """
//    print(try generateScript(encodeScript: encodeScript, filePath: filePath, encoderDepth: 10))
  }

  func testLanguageSetArgumentParsing() {

    let singleArgumentInput = "chi"
    XCTAssertNotNil(LanguageFilter(argument: singleArgumentInput))
    let singleParsed = LanguageFilter(argument: singleArgumentInput)!
    XCTAssertTrue(singleParsed.languages == Set([.chi]))

    let multiArgumentInput = "chi,jpn"
    XCTAssertNotNil(LanguageFilter(argument: multiArgumentInput))
    let parsed = LanguageFilter(argument: multiArgumentInput)!
    XCTAssertTrue(parsed.languages == Set([.chi, .jpn]))
  }

  func testLanguagePreference() {
    print(LanguageFilter.default)
    let preference = ChocoCommonOptions.LanguageOptions(primaryLanguage: nil, preventNoAudio: false, all: nil, audio: .included(languages: [.ger]), subtitles: nil)

    let v = preference.shouldMuxTrack(trackLanguage: .ger, trackType: .audio, primaryLanguage: .eng, forcePrimary: false)
    print(v)

    print(LanguageFilter(argument: "chi,jpn")!)
    print(LanguageFilter(argument: "!chi,jpn")!)
  }

  func testCrop() throws {
    let str = "1920:1024:0:28"
    let info = try CropInfo(ffmpegOutput: str)
    XCTAssertEqual(info, .absolute(width: 1920, height: 1024, x: 0, y: 28))
    XCTAssertEqual(info.ffmpegArgument, "crop=" + str)
  }

  func testAudioBitrate() {
    let bitratePerChannel = 128
    for channelCount in 1...8 {
      let normalBitrate = audioBitrate(bitratePerChannel: bitratePerChannel, channelCount: channelCount, reduceBitrate: false)
      let reducedBitrate = audioBitrate(bitratePerChannel: bitratePerChannel, channelCount: channelCount, reduceBitrate: true)
      print(channelCount, normalBitrate, reducedBitrate, reducedBitrate / channelCount)
    }
  }
}
