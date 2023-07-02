//
//  TargetFunctionTypeMetadata.swift
//  SwiftSource
//
//  Created by 陈晶泊 on 2023/6/19.
//

import Foundation
struct TargetFunctionTypeMetadata{
    var kind: Int // isa
    var flags: Int //函数的类型
    var resultType: UnsafeRawPointer // 返回值类型
    var arguments: ArgumentsBuffer<Any.Type> // 参数类型列表
    // 获取参数个数
    func numberArguments() -> Int {
        return self.flags & 0x0000FFFF
    }
    
    struct ArgumentsBuffer<Element>{
        var element: Element

        mutating func buffer(n: Int) -> UnsafeBufferPointer<Element> {
            return withUnsafePointer(to: &self) {
                let ptr = $0.withMemoryRebound(to: Element.self, capacity: 1) { start in
                    return start
                }
                return UnsafeBufferPointer(start: ptr, count: n)
            }
        }

        mutating func index(of i: Int) -> UnsafeMutablePointer<Element> {
            return withUnsafePointer(to: &self) {
                return UnsafeMutablePointer(mutating: UnsafeRawPointer($0).assumingMemoryBound(to: Element.self).advanced(by: i))
            }
        }
    }

}
