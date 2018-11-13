import XCTest

import SwiftFFmpegTests
import RemuxerTests

var tests = [XCTestCaseEntry]()
tests += SwiftFFmpegTests.allTests()
tests += RemuxerTests.allTests()
XCTMain(tests)
