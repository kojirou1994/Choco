//
//  MplsPlayItem.swift
//  BD_Chapters_MOD
//
//  Created by Kojirou on 2019/2/5.
//

import Foundation

public struct MplsPlayItem: CustomStringConvertible {
    public let clipId: String
    let connectionCondition: UInt8
    let stcId: UInt8
    let inTime: Timestamp
    let outTime: Timestamp
    let relativeInTime: Timestamp
    public let stn: MplsPlayItemStn
    public let multiAngle: MultiAngle
    
    var duration: Timestamp {
        return outTime - inTime
    }
    
    public var description: String {
        return """
        \(clipId).m2ts
        inTime: \(inTime.timestamp)
        outTime: \(outTime.timestamp)
        relativeInTime: \(relativeInTime.timestamp)
        duration: \(duration.timestamp)
        \(multiAngle)
        """
    }
}
