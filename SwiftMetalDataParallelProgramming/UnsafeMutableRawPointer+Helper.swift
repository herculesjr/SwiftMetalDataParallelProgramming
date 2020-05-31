//
//  UnsafeMutableRawPointer+Helper.swift
//  SwiftMetalDataParallelProgramming
//
//  Created by Hercules Farnesi da Costa Cunha Junior on 31-05-20.
//  Copyright © 2020 Farnesi. All rights reserved.
//

import Foundation

extension UnsafeMutableRawPointer {
    func toArray<T>(of type: T.Type, capacity count: Int) -> [T] {
        let pointer = bindMemory(to: type, capacity: count)
        return Array(UnsafeBufferPointer(start: pointer, count: count))
    }
}
