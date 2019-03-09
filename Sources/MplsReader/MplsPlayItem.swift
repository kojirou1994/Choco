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
    
    public func clipId(for angleIndex: Int) -> String {
        switch multiAngle {
        case .no:
            return clipId
        case .yes(let data):
            if angleIndex == 0 {
                return clipId
            } else {
                return data.angles[angleIndex-1].clipId
            }
        }
    }
    
    var duration: Timestamp {
        return outTime - inTime
    }
    
    public var description: String {
        return """
        \(clipId).m2ts
        inTime: \(inTime.description)
        outTime: \(outTime.description)
        relativeInTime: \(relativeInTime.description)
        duration: \(duration.description)
        \(multiAngle)
        """
    }
}
