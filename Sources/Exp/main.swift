import Foundation
import MplsParser
import CLibbluray

let bd = bd_open(CommandLine.arguments[1], nil)!
let info = bd_get_disc_info(bd)!.pointee

print(info)
print("disc name: \(String.init(cString: info.disc_name))")
for i in 0..<Int(info.num_titles) {
    let title = info.titles[i]!.pointee
    print(title)
}

let count = bd_get_titles(bd, UInt8(TITLES_RELEVANT), 0)
for i in 0..<count {
    let ti = bd_get_title_info(bd, i, 0)!.pointee
    print(ti)
}

let mainTitle = bd_get_main_title(bd)
print(mainTitle)
