//
//  TargetStructMetadata.swift
//  SwiftSource
//
//  Created by 陈晶泊 on 2023/6/11.
//

import Foundation

struct TargetStructDescriptor {
    var flags: UInt32
    var parent: TargetRelativeDirectPointer<UnsafeRawPointer>
    var name: TargetRelativeDirectPointer<CChar> // 类名
    var accessFunctionPointer: TargetRelativeDirectPointer<UnsafeRawPointer>
    var fieldDescriptor: TargetRelativeDirectPointer<FieldDescriptor> // 属性描述器
    var numFields: UInt32
    var fieldOffsetVectorOffset: UInt32 // 每一个属性值距离当前实例对象地址的偏移量
    
    // 泛型参数的偏移量 - 源码里是经过一系列计算 而HandyJSON直接给2
    var genericArgumentOffset: Int { return 2 }
    
    func getFieldOffsets(_ metadata: UnsafeRawPointer) -> UnsafePointer<UInt32> {
        let offset:Int = numericCast(self.fieldOffsetVectorOffset)
        //int是8字节，偏移，则是8 * offset =FieldOffsets - metadata地址
        return UnsafeRawPointer(metadata.assumingMemoryBound(to: Int.self).advanced(by: offset)).assumingMemoryBound(to: UInt32.self)
    }
    
}

struct TargetStructMetadata {
    var Kind: Int
     // 结构体描述器 (TargetStructDescriptor是解析后的自定义的，它可以替代TargetValueTypeDescriptor)
    var typeDescriptor: UnsafeMutablePointer<TargetStructDescriptor>
}
