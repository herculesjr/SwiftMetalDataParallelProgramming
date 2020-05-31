//
//  Processor.swift
//  SwiftMetalDataParallelProgramming
//
//  Created by Hercules Farnesi da Costa Cunha Junior on 31-05-20.
//  Copyright © 2020 Farnesi. All rights reserved.
//

import Foundation

protocol Processor {
    var type: String { get }
    func addArrays(_ a: [Float], _ b: [Float], completionHandler: @escaping ([Float]) -> Void)
    func compareArrays(_ a: [Float], _ b: [Float], completionHandler: @escaping (Bool) -> Void)
}
