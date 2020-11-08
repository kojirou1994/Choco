import XCTest
@testable import MplsParser

final class MplsParserTests: XCTestCase {
  func testDecode() throws {
    try """
    /Users/kojirou/Projects/BDRemuxer/multi_angle_PLAYLIST/00000.mpls
    /Users/kojirou/Projects/BDRemuxer/multi_angle_PLAYLIST/00003.mpls
    /Users/kojirou/Projects/BDRemuxer/multi_angle_PLAYLIST/00004.mpls
    /Users/kojirou/Projects/BDRemuxer/multi_angle_PLAYLIST/00005.mpls
    /Users/kojirou/Projects/BDRemuxer/BIG
    /Users/kojirou/Projects/BDRemuxer/UHD.mpls
    """.components(separatedBy: .newlines).forEach { path in
      XCTAssertNoThrow(try MplsPlaylist.parse(mplsURL: URL(fileURLWithPath: path)))
      dump(try! MplsPlaylist.parse(mplsURL: URL(fileURLWithPath: path)))
    }
  }
}
