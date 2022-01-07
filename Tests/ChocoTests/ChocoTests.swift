import XCTest
@testable import libChoco

final class ChocoTests: XCTestCase {
  func testScriptTemplate() throws {
    let filePath = "/Volumes/Source/Sample.mp4"
    let encodeScript = """
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
    XCTAssertNotNil(LanguageSet(argument: singleArgumentInput))
    let singleParsed = LanguageSet(argument: singleArgumentInput)!
    XCTAssertTrue(singleParsed.languages == Set([.chi]))

    let multiArgumentInput = "chi,jpn"
    XCTAssertNotNil(LanguageSet(argument: multiArgumentInput))
    let parsed = LanguageSet(argument: multiArgumentInput)!
    XCTAssertTrue(parsed.languages == Set([.chi, .jpn]))
  }

  func testLanguagePreference() {
    let preference = ChocoCommonOptions.LanguageOptions(ignoreInputPrimaryLang: false, includeLangs: .init([.chi, .jpn]), excludeLangs: .init([.eng]), includeAudioLangs: .empty, excludeAudioLangs: .empty, includeSubLangs: .empty, excludeSubLangs: .empty)

    let preferedLanguages = preference.generatePrimaryLanguages(with: [.chi], addUnd: false, logger: nil)

    XCTAssertEqual(preferedLanguages, Set([.chi, .jpn]))
  }

  func testCrop() throws {
    let str = "1920:1024:0:28"
    let info = try CropInfo(ffmpegOutput: str)
    XCTAssertEqual(info, .absolute(width: 1920, height: 1024, x: 0, y: 28))
    XCTAssertEqual(info.ffmpegArgument, "crop=" + str)
  }
}
