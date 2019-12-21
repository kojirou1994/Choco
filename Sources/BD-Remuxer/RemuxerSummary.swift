import Foundation

struct RemuxerWorkItem {
    let input: URL
    let result: Result<Summary, RemuxerError>
}

struct Summary {
    internal init(sizeBefore: UInt64, sizeAfter: UInt64, startDate: Date, endDate: Date) {
        self.sizeBefore = sizeBefore
        self.sizeAfter = sizeAfter
        self.startDate = startDate
        self.endDate = endDate
    }

    let sizeBefore: UInt64
    let sizeAfter: UInt64
    let startDate: Date
    let endDate: Date
}

public enum RemuxerError: Error {
    case errorReadingFile
    case noPlaylists
    case sameFilename
    case outputExist
    case noOutputFile(URL)
    case directoryInFileMode
    case inputNotExists
    case mkvmergeIdentification(Error)
    case ffmpegExtractAudio(Error)
    case validateFlacMD5(Error)
    case mkvmergeMux(Error)
    case parseBDMV(Error)
    case mplsToMKV(WorkTask, Error)
    case terminated
}

func sizeString(_ v: UInt64) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(v), countStyle: .file)
}

let timeFormat: DateComponentsFormatter = {
    let f = DateComponentsFormatter()
    f.allowedUnits = [.minute, .second]
    f.unitsStyle = .short
    return f
}()

func printSummary(workItems: [RemuxerWorkItem]) {
    print("Summary:")
    for workItem in workItems {
        print("Input: \(workItem.input.path)")
        switch workItem.result {
        case .success(let summary):
            print("Successed!")
            print("""
            Start date: \(summary.startDate)
            Totally used: \(timeFormat.string(from: summary.startDate, to: summary.endDate) ?? "\(summary.endDate.timeIntervalSince(summary.startDate))")
            Old size: \(sizeString(summary.sizeBefore))
            New size: \(sizeString(summary.sizeAfter))
            """)
        case .failure(let error):
            print("Failed!")
            print("Error info: \(error)")
        }
    }
}
