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
    "encoderDepth": encoderDepth
  ] as [String : Any]

  /*
   if "{{{cropMode}}}" == "relative":
     src = core.std.Crop(src, {{{cropLeft}}}, {{{cropRight}}}, {{{cropTop}}}, {{{cropBottom}}})
   else:
     src = core.std.CropAbs(src, {{{cropWidth}}}, {{{cropHeight}}}, {{{cropLeft}}}, {{{cropTop}}})
   */
  switch cropInfo {
  case .relative(let top, let bottom, let left, let right):
    dic["cropMode"] = "relative"
    dic["cropWidth"] = "0"
    dic["cropHeight"] = "0"
    dic["cropLeft"] = left
    dic["cropRight"] = right
    dic["cropTop"] = top
    dic["cropBottom"] = bottom
  case .absolute(let width, let height, let x, let y):
    dic["cropMode"] = "absolute"
    dic["cropRight"] = "0"
    dic["cropBottom"] = "0"
    dic["cropWidth"] = width
    dic["cropHeight"] = height
    dic["cropLeft"] = x
    dic["cropTop"] = y
  case nil:
    break
  }
  let result = tree.render(object: dic)
  return result
}
