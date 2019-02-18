//
//  MultiAngle.swift
//  BD_Chapters_MOD
//
//  Created by Kojirou on 2019/2/5.
//

import Foundation

public enum MultiAngle: CustomStringConvertible {
    case no
    case yes(MultiAngleData)
    
    public var description: String {
        switch self {
        case .no:
            return "Multi Angle: none"
        case .yes(let d):
            return "Multi Angle: \n\(d)"
        }
    }
}

public struct MultiAngleData: CustomStringConvertible {
    public let isDifferentAudio: Bool
    public let isSeamlessAngleChange: Bool
    
    public let angles: [Angle]
    
    public struct Angle {
        let clipId: String
        let clipCodecId: String
        let stcId: UInt8
    }
    
    public var description: String {
        return """
        isDifferentAudio: \(isDifferentAudio)
        isSeamlessAngleChange: \(isSeamlessAngleChange)
        angles: \(angles.map {$0.clipId}.joined(separator: " "))
        """
    }
}
