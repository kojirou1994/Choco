import Foundation
import MplsParser
import URLFileManager

try URLFileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "/Volumes/SAMSUNG_TF_64G/FoundationTest/PLAYLIST"))
    .forEach({ (url) in
        do {
            _ = try MplsPlaylist.parse(mplsURL: url)
        } catch {
            print(error)
        }
    })

pause()
