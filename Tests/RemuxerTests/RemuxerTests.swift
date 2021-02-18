import XCTest
@testable import libChoco

final class RemuxerTests: XCTestCase {
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
}
