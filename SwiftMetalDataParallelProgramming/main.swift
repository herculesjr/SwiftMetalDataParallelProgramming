//
//  main.swift
//  SwiftMetalDataParallelProgramming
//
//  Created by Hercules Farnesi da Costa Cunha Junior on 31-05-20.
//  Copyright © 2020 Farnesi. All rights reserved.
//

// Metal Reference: https://metalbyexample.com/the-book/

import Foundation

let arrayLength = 1 << 24 // 16.777.216 items -> 64MB each array
var processors: [Processor] = [ProcessorCPU()]
if let gpuProcessor = ProcessorGPU() {
    processors.append(gpuProcessor)
}

let semaphore = DispatchSemaphore(value: 0)

log("Loading 2 arrays with \(arrayLength) random items each...")
var startTime = CFAbsoluteTimeGetCurrent()
var arrayA = [Float]()
var arrayB = [Float]()
arrayA.reserveCapacity(arrayLength)
arrayB.reserveCapacity(arrayLength)
arrayA.append(contentsOf: stride(from: Float(0.0), to: Float(arrayLength), by: 1.0))
arrayB.append(contentsOf: stride(from: Float(arrayLength), to: Float(0.0), by: -1.0))
log("Loaded \(humanSizeBytes(arrayLength * 2 * MemoryLayout<Float>.size)) of data in \(CFAbsoluteTimeGetCurrent() - startTime) seconds")


var addResults = [[Float]]()

for processor in processors {
    log("Using \(processor.type) for data processing...")
    startTime = CFAbsoluteTimeGetCurrent()
    processor.addArrays(arrayA, arrayB) { result in
        addResults.append(result)
        log("Finished in \(CFAbsoluteTimeGetCurrent() - startTime) seconds")
        semaphore.signal()
    }
    semaphore.wait()
}

for processor in processors {
    log("Validating results from CPU and GPU using \(processor.type)...")
    startTime = CFAbsoluteTimeGetCurrent()
    processor.compareArrays(addResults[0], addResults[1]) { result in
        log("It took \(CFAbsoluteTimeGetCurrent() - startTime) seconds to compare CPU and GPU results using \(processor.type): They are \(result ? "matching" : "not matching")")
        semaphore.signal()
    }
    semaphore.wait()
}

// Helper functions
func log(_ message: String) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm:ss.SSSS"
    print("[\(dateFormatter.string(from: Date()))] \(message)")
}

func humanSizeBytes(_ length: Int) -> String {
    return ByteCountFormatter.string(fromByteCount: Int64(length), countStyle: .memory)
}
