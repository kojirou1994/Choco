import Foundation
import mustache


public func generateScript(encodeScript: String, filePath: String, trackIndex: Int, cropInfo: CropInfo?, encoderDepth: Int) throws -> String {
//  let template = try String(contentsOfFile: templatePath)
  let parser = MustacheParser()
  let tree = parser.parse(string: encodeScript)
  var dic = [
    "filePath": "r\"" + filePath + "\"",
//    "trackIndex": trackIndex,
    "encoderDepth": encoderDepth
  ] as [String : Any]

  /*
   if {{{cropLeft}}} == "":
     src = core.std.CropAbs(src, {{{cropWidth}}}, {{{cropHeight}}}, {{{cropLeft}}}, {{{cropTop}}})
   else:
     src = core.std.Crop(src, {{{cropLeft}}}, {{{cropRight}}}, {{{cropTop}}}, {{{cropBottom}}})
   */
  switch cropInfo {
  case .relative(let top, let bottom, let left, let right):
    dic["cropLeft"] = left
    dic["cropRight"] = right
    dic["cropTop"] = top
    dic["cropBottom"] = bottom
  case .absolute(let width, let height, let x, let y):
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
