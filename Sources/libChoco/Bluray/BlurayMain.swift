import CBluray

enum BlurayError: Error {
  case bdopen
  case notFoundMain
}

func getMainPlaylist(at path: String) throws -> UInt32 {
  guard let bd = bd_open(path, nil) else {
    throw BlurayError.bdopen
  }
  
  defer {bd_close(bd)}
  let count = bd_get_titles(bd, UInt8(TITLES_RELEVANT), 0)

  for i in 0..<count {
    let ti = bd_get_title_info(bd, i, 0)
    bd_free_title_info(ti)
  }

  let mainTitle = UInt32(bd_get_main_title(bd))
  //    print(mainTitle)

  for i in 0..<count {
    let ti = bd_get_title_info(bd, i, 0)
    defer {bd_free_title_info(ti)}
    if ti?.pointee.idx == mainTitle {
      //            print(ti!.pointee)
      return ti!.pointee.playlist
    }
  }
  throw BlurayError.notFoundMain

}
