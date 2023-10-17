import Foundation
import mustache


public func generateScript(encodeScript: String, filePath: String, trackIndex: Int, cropInfo: CropInfo?, encoderDepth: Int) throws -> String {
//  let template = try String(contentsOfFile: templatePath)
  let parser = MustacheParser()
  let tree = parser.parse(string: encodeScript)
  var dic = [
    "filePath": "r\"" + filePath + "\"",
    "filePath_WIN": "r\"" + filePath.replacingOccurrences(of: "/", with: "\\") + "\"",
//    "trackIndex": trackIndex,
    // default crop props, make py happy
    "cropTop": 0,
    "cropBottom": 0,
    "cropWidth": 0,
    "cropHeight": 0,
    "cropLeft": 0,
    "cropRight": 0,
    "encoderDepth": encoderDepth
  ] as [String : Any]

  /*
   if "{{{cropMode}}}" == "relative":
     src = core.std.Crop(src, {{{cropLeft}}}, {{{cropRight}}}, {{{cropTop}}}, {{{cropBottom}}})
   elif "{{{cropMode}}}" == "absolute":
     src = core.std.CropAbs(src, {{{cropWidth}}}, {{{cropHeight}}}, {{{cropLeft}}}, {{{cropTop}}})
   */

  enum CropMode: String, CustomStringConvertible {
    case none
    case relative
    case absolute

    var description: String { rawValue }
  }

  switch cropInfo {
  case .relative(let top, let bottom, let left, let right):
    dic["cropMode"] = CropMode.relative
    dic["cropLeft"] = left
    dic["cropRight"] = right
    dic["cropTop"] = top
    dic["cropBottom"] = bottom
  case .absolute(let width, let height, let x, let y):
    dic["cropMode"] = CropMode.absolute
    dic["cropWidth"] = width
    dic["cropHeight"] = height
    dic["cropLeft"] = x
    dic["cropTop"] = y
  case nil:
    dic["cropMode"] = CropMode.none
  }
  let result = tree.render(object: dic)
  return result
}
