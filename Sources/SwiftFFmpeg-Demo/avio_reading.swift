//
//  avio_reading.swift
//  SwiftFFmpeg-Demo
//
//  Created by Kojirou on 2019/4/17.
//

import Foundation
import SwiftFFmpeg

struct buffer_data {
    var ptr: [UInt8]
    var size: size_t ///< size left in the buffer
}

func readPacket(opaque: OpaquePointer, buf: inout [UInt8], buf_size: CInt) {
    
}
