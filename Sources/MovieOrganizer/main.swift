import Foundation
import Kwift
import MediaTools
import MovieDatabase
import ArgumentParser

#if DEBUG
let f = try LibraryObject.MediaFile.init(path: "/Volumes/TOSHIBA_WORK/Downloads/yasuoman.flv")
print(f)
//let tvdb = TVDB()
//let i = try tvdb.get(imdbID: "tt9253866", lang: .en)
//dump(i)
//let e = try tvdb.getEpisodes(id: i.id, season: 1, lang: .ja)
//dump(e)
exit(0)
#endif
let worker = try Organizer.init(arguments: CommandLine.arguments.dropFirst())
worker.start()
