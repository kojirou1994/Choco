//
//  MplsSubPath.swift
//  BD_Chapters_MOD
//
//  Created by Kojirou on 2019/2/6.
//

import Foundation

enum SubPathType: UInt8 {
    case reserved1 = 0
    case reserved2 = 1
    case primary_audio_of_browsable_slideshow       = 2
    case interactive_graphics_presentation_menu     = 3
    case text_subtitle_presentation                 = 4
    case out_of_mux_synchronous_elementary_streams  = 5
    case out_of_mux_asynchronous_picture_in_picture = 6
    case in_mux_synchronous_picture_in_picture      = 7
    
    case extended = 0xff
    
    init(value: UInt8) throws {
        if let v = SubPathType.init(rawValue: value) {
            self = v
        } else {
            print("Unknown SubPathType: \(value), set it to extended")
            self = .extended
//            throw MplsReadError.invalidSubPathType(value)
        }
    }
}

struct MplsSubPath {
    let type: SubPathType
    let isRepeatSubPath: Bool
    let items: [SubPlayItem]
}

struct SubPlayItem {
    let clpiFilename: String
    let codecId: String
    let connectionCondition: UInt8
    let syncPlayItemId: UInt16
    let refToStcId: UInt8
    let isMultiClipEntries: Bool
    let inTime, outTime: Timestamp
    let syncStartPtsOfPlayItem: Timestamp
    let clips: [SubPlayItemClip]
}

struct SubPlayItemClip {
    let clpiFilename: String
    let codecId: String
    let refToStcId: UInt8
    
    init(clpiFilename: String, codecId: String, refToStcId: UInt8) {
        self.clpiFilename = clpiFilename
        self.codecId = codecId
        self.refToStcId = refToStcId
    }
}
