//
//  MplsPlaylistStn.swift
//  BD_Chapters_MOD
//
//  Created by Kojirou on 2019/2/5.
//

import Foundation

public struct MplsPlayItemStn {
    public let numPrimaryVideo: UInt8
    public let numPrimaryAudio: UInt8
    public let numPg: UInt8
    public let numIg: UInt8
    public let numSecondaryAudio: UInt8
    public let numSecondaryVideo: UInt8
    public let numPipPg: UInt8
    
    public let video: [MplsStream]
    public let audio: [MplsStream]
    public let pg: [MplsStream]
}
