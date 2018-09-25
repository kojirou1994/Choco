//
//  Bluray.swift
//  Remuxer
//
//  Created by Kojirou on 2018/9/24.
//

import Foundation
import CLibbluray

func getBlurayTitle(path: String) -> String {
    guard let bd = bd_open(path, nil),
        let info = bd_get_disc_info(bd),
        let name = info.pointee.disc_name else {
            return path.filename
    }
    defer {
        bd_close(bd)
    }
    let discName = String.init(cString: name)
    if discName.isEmpty {
        return path.filename
    } else {
        return discName
    }
}
