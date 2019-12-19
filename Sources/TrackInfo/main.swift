import Foundation
import TrackExtension

guard CommandLine.argc > 1 else {
    print("No inputs!")
    exit(1)
}

func trackinfo(_ file: String) {
    do {
        let info = try MkvmergeIdentification(filePath: file)
        print(file)
        for track in info.tracks {
            print(track.remuxerInfo)
        }
        print("\n\n")
    } catch {
        print("Failed to read \(file), error: \(error)")
    }
}

CommandLine.arguments[1...].forEach(trackinfo(_:))
