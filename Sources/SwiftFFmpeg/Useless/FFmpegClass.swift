//
//  AVClass.swift
//  SwiftFFmpeg
//
//  Created by sunlubo on 2018/7/24.
//

import CFFmpeg

/// This structure stores compressed data.
///
/// It is typically exported by demuxers and then passed as input to decoders,
/// or received as output from encoders and then passed to muxers.
public final class FFmpegClass: CPointerWrapper {
    var _value: UnsafeMutablePointer<AVClass>
    
    init(_ value: UnsafeMutablePointer<AVClass>) {
        _value = value
    }
    
    typealias Pointer = AVClass

    /// The name of the class.
    public var name: String {
        return String(cString: _value.pointee.class_name)
    }

    /// Category used for visualization (like color) This is only set if the category is equal for
    /// all objects using this class.
    public var category: AVClassCategory {
        return _value.pointee.category
    }
}

//extension AVFormatContextWrapper {
//
//    public var avClass: AVClassWrapper {
//        return AVClassWrapper(avformat_get_class())
//    }
//}
//
//extension AVCodecContext {
//
//    public var avClass: AVClassWrapper {
//        return AVClassWrapper(avcodec_get_class())
//    }
//}

//extension AVFrame {
//
//    public var avClass: AVClassWrapper {
//        return AVClassWrapper(clazzPtr: avcodec_get_frame_class())
//    }
//}
