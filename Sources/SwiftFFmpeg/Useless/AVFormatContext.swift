//
//  AVFormatContext.swift
//  SwiftFFmpeg
//
//  Created by sunlubo on 2018/6/29.
//

import CFFmpeg

// MARK: - AVFmt

public struct AVFmt: OptionSet {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    /// Demuxer will use avio_open, no opened file should be provided by the caller.
    public static let noFile = AVFmt(rawValue: AVFMT_NOFILE)
    /// Needs '%d' in filename.
    public static let needNumber = AVFmt(rawValue: AVFMT_NEEDNUMBER)
    /// Show format stream IDs numbers.
    public static let showIDs = AVFmt(rawValue: AVFMT_SHOW_IDS)
    /// Format wants global header.
    public static let globalHeader = AVFmt(rawValue: AVFMT_GLOBALHEADER)
    /// Format does not need / have any timestamps.
    public static let noTimestamps = AVFmt(rawValue: AVFMT_NOTIMESTAMPS)
    /// Use generic index building code.
    public static let genericIndex = AVFmt(rawValue: AVFMT_GENERIC_INDEX)
    /// Format allows timestamp discontinuities. Note, muxers always require valid (monotone) timestamps.
    public static let tsDiscont = AVFmt(rawValue: AVFMT_TS_DISCONT)
    /// Format allows variable fps.
    public static let variableFPS = AVFmt(rawValue: AVFMT_VARIABLE_FPS)
    /// Format does not need width/height.
    public static let noDimensions = AVFmt(rawValue: AVFMT_NODIMENSIONS)
    /// Format does not require any streams.
    public static let noStreams = AVFmt(rawValue: AVFMT_NOSTREAMS)
    /// Format does not allow to fall back on binary search via read_timestamp.
    public static let noBinSearch = AVFmt(rawValue: AVFMT_NOBINSEARCH)
    /// Format does not allow to fall back on generic search.
    public static let noGenSearch = AVFmt(rawValue: AVFMT_NOGENSEARCH)
    /// Format does not allow seeking by bytes.
    public static let noByteSeek = AVFmt(rawValue: AVFMT_NO_BYTE_SEEK)
    /// Format allows flushing. If not set, the muxer will not receive a NULL packet in the write_packet function.
    public static let allowFlush = AVFmt(rawValue: AVFMT_ALLOW_FLUSH)
    /// Format does not require strictly increasing timestamps, but they must still be monotonic.
    public static let tsNonstrict = AVFmt(rawValue: AVFMT_TS_NONSTRICT)
    /// Format allows muxing negative timestamps. If not set the timestamp will be shifted in av_write_frame and
    /// av_interleaved_write_frame so they start from 0.
    /// The user or muxer can override this through AVFormatContext.avoid_negative_ts.
    public static let tsNegative = AVFmt(rawValue: AVFMT_TS_NEGATIVE)
    /// Seeking is based on PTS
    public static let seekToPTS = AVFmt(rawValue: AVFMT_SEEK_TO_PTS)
}

// MARK: - AVFmtFlag

public struct AVFmtFlag: OptionSet {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    /// Generate missing pts even if it requires parsing future frames.
    public static let genPTS = AVFmtFlag(rawValue: AVFMT_FLAG_GENPTS)
    /// Ignore index.
    public static let ignIdx = AVFmtFlag(rawValue: AVFMT_FLAG_IGNIDX)
    /// Do not block when reading packets from input.
    public static let nonBlock = AVFmtFlag(rawValue: AVFMT_FLAG_NONBLOCK)
    /// Ignore DTS on frames that contain both DTS & PTS.
    public static let ignDTS = AVFmtFlag(rawValue: AVFMT_FLAG_IGNDTS)
    /// Do not infer any values from other values, just return what is stored in the container.
    public static let noFillIn = AVFmtFlag(rawValue: AVFMT_FLAG_NOFILLIN)
    /// Do not use AVParsers, you also must set AVFMT_FLAG_NOFILLIN as the fillin code works on frames and
    /// no parsing -> no frames. Also seeking to frames can not work if parsing to find frame boundaries has been
    /// disabled.
    public static let noParse = AVFmtFlag(rawValue: AVFMT_FLAG_NOPARSE)
    /// Do not buffer frames when possible.
    public static let noBuffer = AVFmtFlag(rawValue: AVFMT_FLAG_NOBUFFER)
    /// The caller has supplied a custom AVIOContext, don't avio_close() it.
    public static let customIO = AVFmtFlag(rawValue: AVFMT_FLAG_CUSTOM_IO)
    /// Discard frames marked corrupted.
    public static let discardCorrupt = AVFmtFlag(rawValue: AVFMT_FLAG_DISCARD_CORRUPT)
    /// Flush the AVIOContext every packet.
    public static let flushPackets = AVFmtFlag(rawValue: AVFMT_FLAG_FLUSH_PACKETS)
    /// When muxing, try to avoid writing any random/volatile data to the output.
    /// This includes any random IDs, real-time timestamps/dates, muxer version, etc.
    ///
    /// This flag is mainly intended for testing.
    public static let bitExact = AVFmtFlag(rawValue: AVFMT_FLAG_BITEXACT)
    /// Deprecated, does nothing.
    @available(*, deprecated)
    public static let mp4aLATM = AVFmtFlag(rawValue: AVFMT_FLAG_MP4A_LATM)
    /// Try to interleave outputted packets by dts (using this flag can slow demuxing down).
    public static let sortDTS = AVFmtFlag(rawValue: AVFMT_FLAG_SORT_DTS)
    /// Enable use of private options by delaying codec open (this could be made default once all code is converted).
    public static let privOpt = AVFmtFlag(rawValue: AVFMT_FLAG_PRIV_OPT)
    /// Deprecated, does nothing.
    @available(*, deprecated)
    public static let keepSideData = AVFmtFlag(rawValue: AVFMT_FLAG_KEEP_SIDE_DATA)
    /// Enable fast, but inaccurate seeks for some formats.
    public static let fastSeek = AVFmtFlag(rawValue: AVFMT_FLAG_FAST_SEEK)
    /// Stop muxing when the shortest stream stops.
    public static let shortest = AVFmtFlag(rawValue: AVFMT_FLAG_SHORTEST)
    /// Add bitstream filters as requested by the muxer.
    public static let autoBSF = AVFmtFlag(rawValue: AVFMT_FLAG_AUTO_BSF)
}

// MARK: - AVInputFormat


