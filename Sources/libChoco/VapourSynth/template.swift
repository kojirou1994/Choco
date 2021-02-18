import Foundation
import mustache

func generateScript(encodeScript: String, filePath: String, encoderDepth: Int) throws -> String {
//  let template = try String(contentsOfFile: templatePath)
  let parser = MustacheParser()
  let tree = parser.parse(string: encodeScript)
  let dic = [
    "filePath": "r\"" + filePath + "\"",
    "encoderDepth": encoderDepth
  ] as [String : Any]
  let result = tree.render(object: dic)
  return result
}
