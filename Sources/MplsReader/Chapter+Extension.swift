extension Chapter {
    
    public init<C>(mplsChapters: C) where C: Collection, C.Element == MplsChapter {
        self.init(timestamps: mplsChapters.map {$0.relativeTimestamp})
    }
    
}
