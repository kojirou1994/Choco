import MediaUtility

extension Chapter {
    public init<C>(mplsChapters: C) where C: Collection, C.Element == MplsChapter {
        self.init(timestamps: mplsChapters.map {$0.relativeTimestamp})
    }
}

extension Timestamp {
    public init(mpls time: UInt64) {
        self.init(ns: time * 1000000 / 45)
    }
}
