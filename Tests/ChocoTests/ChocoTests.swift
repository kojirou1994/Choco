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
    print(try generateScript(encodeScript: encodeScript, filePath: filePath, encoderDepth: 10))
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
    let preference = ChocoConfiguration.LanguagePreference(preferedLanguages: .init(languages: [.chi, .jpn]), excludeLanguages: .init(languages: [.eng]))

    let preferedLanguages = preference.generatePrimaryLanguages(with: [.chi], addUnd: false, logger: nil)

    XCTAssertEqual(preferedLanguages, Set([.chi, .jpn]))
  }
}
