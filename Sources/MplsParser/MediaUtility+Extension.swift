import MediaUtility

extension Chapter {
  public init<C>(mplsChapters: C) where C: Collection, C.Element == MplsChapter {
    self.init(timestamps: mplsChapters.map {$0.relativeTimestamp})
  }
}

extension Timestamp {
  public init(mpls time: UInt32) {
    self.init(ns: UInt64(time) * 1000000 / 45)
  }
}
