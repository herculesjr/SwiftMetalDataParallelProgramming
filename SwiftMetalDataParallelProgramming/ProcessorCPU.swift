//
//  ProcessorCPU.swift
//  SwiftMetalDataParallelProgramming
//
//  Created by Hercules Farnesi da Costa Cunha Junior on 31-05-20.
//  Copyright © 2020 Farnesi. All rights reserved.
//

import Foundation

struct ProcessorCPU: Processor {
    var type: String {
        return "CPU"
    }
    
    func addArrays(_ a: [Float], _ b: [Float], completionHandler: @escaping ([Float]) -> Void) {
        assert(a.count == b.count)
        var result = [Float]()
        result.reserveCapacity(a.count)
        for item in a.enumerated() {
            result.append(a[item.offset] + b[item.offset])
        }
        completionHandler(result)
    }
    
    func compareArrays(_ a: [Float], _ b: [Float], completionHandler: @escaping (Bool) -> Void) {
        assert(a.count == b.count)
        var compareResult = true
        for i in 0 ..< a.count {
            compareResult = compareResult && a[i] == b[i]
        }
        completionHandler(compareResult)
    }
}
