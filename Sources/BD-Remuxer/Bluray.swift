//
//  Bluray.swift
//  Remuxer
//
//  Created by Kojirou on 2018/9/24.
//

import Foundation
import CLibbluray

func getBlurayTitle(path: String, useLibbluray: Bool) -> String {
    guard useLibbluray else {
        return path.filename
    }
    guard let bd = bd_open(path, nil),
        bd_set_player_setting_str(bd, BLURAY_PLAYER_SETTING_MENU_LANG.rawValue, "jpn") == 1,
        let meta = bd_get_meta(bd),
        let name = meta.pointee.di_name else {
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
