import Foundation
import mustache

func generateScript(filePath: String, encodeScript: String) throws -> String {
//  let template = try String(contentsOfFile: templatePath)
  let parser = MustacheParser()
  let tree = parser.parse(string: encodeScript)
  let dic = [
    "filePath": "r\"" + filePath + "\""
  ]
  let result = tree.render(object: dic)
  return result
}
