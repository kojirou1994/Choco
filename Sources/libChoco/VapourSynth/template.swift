import Foundation
import mustache

func generateScript(encodeScript: String, filePath: String, trackIndex: Int, cropInfo: CropInfo, encoderDepth: Int) throws -> String {
//  let template = try String(contentsOfFile: templatePath)
  let parser = MustacheParser()
  let tree = parser.parse(string: encodeScript)
  let dic = [
    "filePath": "r\"" + filePath + "\"",
//    "trackIndex": trackIndex,
    "cropLeft": cropInfo.left,
    "cropRight": cropInfo.right,
    "cropTop": cropInfo.top,
    "cropBottom": cropInfo.bottom,
    "encoderDepth": encoderDepth
  ] as [String : Any]
  let result = tree.render(object: dic)
  return result
}
