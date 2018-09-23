//
//  RemuxerError.swift
//  Common
//
//  Created by Kojirou on 2018/9/22.
//

import Foundation

public enum RemuxerError: Error {
    case t
    case processError(code: Int32)
    case sameFilename
}
