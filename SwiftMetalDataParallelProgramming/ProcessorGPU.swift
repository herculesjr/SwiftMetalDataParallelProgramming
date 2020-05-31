//
//  ProcessorGPU.swift
//  SwiftMetalDataParallelProgramming
//
//  Created by Hercules Farnesi da Costa Cunha Junior on 31-05-20.
//  Copyright © 2020 Farnesi. All rights reserved.
//

import Foundation
import Metal

class ProcessorGPU: Processor {
    private static let functionNameAddArrayItem = "add_array_item"
    private static let functionNameCompareArrayItem = "compare_array_item"
    private static let functionNameAllTrueArray = "all_true_array"
    
    private let device: MTLDevice
    private let addFunctionPipeline: MTLComputePipelineState
    private let compareArrayItemFunctionPipeline: MTLComputePipelineState
    private let allTrueArrayFunctionPipeline: MTLComputePipelineState
    private let commandQueue: MTLCommandQueue
    
    var type: String {
        return "METAL"
    }
    
    init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
            let defaultLibrary = device.makeDefaultLibrary(),
            let addFunction = defaultLibrary.makeFunction(name: ProcessorGPU.functionNameAddArrayItem),
            let compareArrayItemFunction = defaultLibrary.makeFunction(name: ProcessorGPU.functionNameCompareArrayItem),
            let allTrueArrayFunction = defaultLibrary.makeFunction(name: ProcessorGPU.functionNameAllTrueArray),
            let addFunctionPipeline = try? device.makeComputePipelineState(function: addFunction),
            let compareArrayItemFunctionPipeline = try? device.makeComputePipelineState(function: compareArrayItemFunction),
            let allTrueArrayFunctionPipeline = try? device.makeComputePipelineState(function: allTrueArrayFunction),
            let commandQueue = device.makeCommandQueue() else { return nil }
        self.device = device
        self.addFunctionPipeline = addFunctionPipeline
        self.compareArrayItemFunctionPipeline = compareArrayItemFunctionPipeline
        self.allTrueArrayFunctionPipeline = allTrueArrayFunctionPipeline
        self.commandQueue = commandQueue
    }
    
    func addArrays(_ a: [Float], _ b: [Float], completionHandler: @escaping ([Float]) -> Void) {
        assert(a.count == b.count)
        let length = a.count
        let floatStride = MemoryLayout<Float>.stride
        let byteCount = a.count * floatStride
        
        // Filling GPU memory with array content
        var bufferA: MTLBuffer?
        var bufferB: MTLBuffer?
        a.withUnsafeBytes { pointer in
            bufferA = createBuffer(from: pointer.baseAddress, length: byteCount)
        }
        b.withUnsafeBytes { pointer in
            bufferB = createBuffer(from: pointer.baseAddress, length: byteCount)
        }
        let bufferResult = createBuffer(from: nil, length: byteCount)
        
        let gridSize = MTLSizeMake(length, 1, 1)
        //set number of threads
        var threadCount = addFunctionPipeline.maxTotalThreadsPerThreadgroup
        if threadCount > length {
            threadCount = length
        }
        let threadsPerThreadgroup = MTLSizeMake(threadCount, 1, 1)
        run(pipeline: addFunctionPipeline,
            arguments: [
                (buffer: bufferA, offset: 0, index: 0),
                (buffer: bufferB, offset: 0, index: 1),
                (buffer: bufferResult, offset: 0, index: 2),
            ],
            gridSize: gridSize,
            threadsPerThreadgroup: threadsPerThreadgroup) { _ in
                let result = bufferResult?.contents().toArray(of: Float.self, capacity: length)
                completionHandler(result!)
        }
    }
    
    func compareArrays(_ a: [Float], _ b: [Float], completionHandler: @escaping (Bool) -> Void) {
        assert(a.count == b.count)
        let length = a.count
        let floatStride = MemoryLayout<Float>.stride
        let boolStride = MemoryLayout<Bool>.stride
        let floatBytes = a.count * floatStride
        let boolBytes = a.count * boolStride
        
        // Filling GPU memory with array content
        var bufferA: MTLBuffer?
        var bufferB: MTLBuffer?
        a.withUnsafeBytes { pointer in
            bufferA = createBuffer(from: pointer.baseAddress, length: floatBytes)
        }
        b.withUnsafeBytes { pointer in
            bufferB = createBuffer(from: pointer.baseAddress, length: floatBytes)
        }
        let bufferResult = createBuffer(from: nil, length: boolBytes)
        
        let gridSize = MTLSizeMake(length, 1, 1)
        //set number of threads
        var threadCount = compareArrayItemFunctionPipeline.maxTotalThreadsPerThreadgroup
        if threadCount > length {
            threadCount = length
        }
        let threadsPerThreadgroup = MTLSizeMake(threadCount, 1, 1)
        
        run(pipeline: compareArrayItemFunctionPipeline,
            arguments: [
                (buffer: bufferA, offset: 0, index: 0),
                (buffer: bufferB, offset: 0, index: 1),
                (buffer: bufferResult, offset: 0, index: 2),
            ],
            gridSize: gridSize,
            threadsPerThreadgroup: threadsPerThreadgroup) { [weak self] _ in
                let result = bufferResult?.contents().toArray(of: Bool.self, capacity: length)
                self?.allTrueArray(result, completionHandler: completionHandler)
        }
    }
}

private extension ProcessorGPU {
    func allTrueArray(_ array: [Bool]?, completionHandler: @escaping (Bool) -> Void) {
        var buffer: MTLBuffer?
        array?.withUnsafeBytes { pointer in
            buffer = createBuffer(from: pointer.baseAddress, length: pointer.count)
        }
        let bufferResult = createBuffer(from: nil, length: MemoryLayout<Bool>.stride)
        let gridSize = MTLSizeMake(1, 1, 1)
        //set number of threads
        let threadsPerThreadgroup = MTLSizeMake(1, 1, 1)
        run(pipeline: allTrueArrayFunctionPipeline,
            arguments: [
                (buffer: buffer, offset: 0, index: 0),
                (buffer: bufferResult, offset: 0, index: 1),
            ],
            gridSize: gridSize,
            threadsPerThreadgroup: threadsPerThreadgroup) { _ in
                let result = bufferResult?.contents().load(fromByteOffset: 0, as: Bool.self) ?? false
                completionHandler(result)
        }
    }
    
    func createBuffer(from bytes: UnsafeRawPointer?, length: Int) -> MTLBuffer? {
        let buffer = device.makeBuffer(length: length, options: .storageModeShared)
        if let bytes = bytes {
            buffer?.contents().copyMemory(from: bytes, byteCount: length)
        }
        return buffer
    }
    
    func run(pipeline: MTLComputePipelineState,
             arguments: [(buffer: MTLBuffer?, offset: Int, index: Int)],
             gridSize: MTLSize,
             threadsPerThreadgroup: MTLSize,
             completionHandler: @escaping MTLCommandBufferHandler) {
        //create action
        let commandBuffer = commandQueue.makeCommandBuffer()
        let computeEncoder = commandBuffer?.makeComputeCommandEncoder()
        computeEncoder?.setComputePipelineState(pipeline)
        for item in arguments {
            computeEncoder?.setBuffer(item.buffer, offset: item.offset, index: item.index)
        }
        //setting amount of threads
        computeEncoder?.dispatchThreads(gridSize, threadsPerThreadgroup: threadsPerThreadgroup)
        //compile shader
        computeEncoder?.endEncoding()
        
        commandBuffer?.addCompletedHandler(completionHandler)
        
        //execute
        commandBuffer?.commit()
    }
}
