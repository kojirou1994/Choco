//
//  Process+Extension.swift
//  Common
//
//  Created by Kojirou on 2018/9/22.
//

import Foundation

public extension Process {
    
    func launchUntilExit() {
        launch()
        #if os(macOS)
        waitUntilExit()
        #else
        while isRunning {
            sleep(1)
        }
        #endif
    }
    
    func checkTerminationStatus() throws {
        #if os(macOS)
        waitUntilExit()
        #else
        while isRunning {
            sleep(1)
        }
        #endif
        if terminationStatus != 0 {
            throw RemuxerError.processError(code: terminationStatus)
        }
    }
    
}
