//
//  TargetClassMetadata.swift
//  SwiftSource
//
//  Created by 陈晶泊 on 2023/6/9.
//

import Foundation
// 类 Metadata
struct TargetClassMetadata {
    var kind: Int
    var superClass: Any.Type
    var cacheData: (Int, Int)
    var data: Int
    
    var classFlags: Int32 // swift特有的标志
    var instanceAddressPoint: UInt32 // 实例独享内存首地址
    var instanceSize: UInt32 // 实例对象内存大小
    var instanceAlignmentMask: UInt16 // 实例对象内存对齐方式
    var reserved: UInt16 // 运行时保留字段
    var classSize: UInt32 // 类的内存大小
    var classAddressPoint: UInt32 //类的内存首地址
    var typeDescriptor: UnsafeMutablePointer<TargetClassDescriptor> // 类型描述器
    var iVarDestroyer: UnsafeRawPointer // 实例销毁器
}

// 类描述器
struct TargetClassDescriptor{
    var flags: UInt32
    var parent: TargetRelativeDirectPointer<UnsafeRawPointer>
    
    var name: TargetRelativeDirectPointer<CChar>   // class/struct/enum 的名称
    var accessFunctionPointer: TargetRelativeDirectPointer<UnsafeRawPointer>
    var fieldDescriptor: TargetRelativeDirectPointer<FieldDescriptor> // 属性描述器
    
    var superClassType: TargetRelativeDirectPointer<CChar> // 父类类型
    var metadataNegativeSizeInWords: UInt32
    var metadataPositiveSizeInWords: UInt32
    var numImmediateMembers: UInt32
    var numFields: UInt32
    var fieldOffsetVectorOffset: UInt32 // 每一个属性值距离当前实例对象地址的偏移量
    //var Offset: UInt32
    // var size: UInt32
    // V-Table  (methods)
    
    func getFieldOffsets(_ metadata: UnsafeRawPointer) -> UnsafePointer<Int> {
        let offset:Int = numericCast(self.fieldOffsetVectorOffset)
        //int是8字节，偏移，则是8 * offset =FieldOffsets - metadata地址
        return metadata.assumingMemoryBound(to: Int.self).advanced(by: offset)
    }
    
    // 泛型参数的偏移量 - 源码里是经过一系列计算 而HandyJSON直接给2
    var genericArgumentOffset: Int { return 2 }
}

// 相对地址信息 - 存储的是偏移量
struct TargetRelativeDirectPointer<Pointee> {
    var offset: Int32
    
    mutating func getmeasureRelativeOffset() -> UnsafeMutablePointer<Pointee>{
        let offset = self.offset
        
        return withUnsafePointer(to: &self) { p in
            /*
             获得self，变为raw，然后+offset
             
             - UnsafeRawPointer(p) 表示this
             - advanced(by: numericCast(offset) 表示移动的步长，即offset
             - assumingMemoryBound(to: T.self) 表示假定类型是T，即自己指定的类型
             - UnsafeMutablePointer(mutating:) 表示返回的指针类型
            */
            let dsds:Int = numericCast(offset)
           return UnsafeMutablePointer(mutating: UnsafeRawPointer(p).advanced(by: dsds).assumingMemoryBound(to: Pointee.self))
        }
    }
}


// 属性描述器
struct FieldDescriptor {
    var mangledTypeName: TargetRelativeDirectPointer<CChar>
    var superclass: TargetRelativeDirectPointer<CChar>
    var kind: UInt16
    var fieldRecordSize: UInt16
    var numFields: UInt32 // 属性个数
    var fields: FiledRecordBuffer<FieldRecord> // 属性列表
}

// 属性
struct FieldRecord {
    var flags: Int32
    var mangledTypeName: TargetRelativeDirectPointer<CChar> // 属性的类型
    var fieldName: TargetRelativeDirectPointer<UInt8> // 属性的名称
}

struct FiledRecordBuffer<Element>{
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


protocol BrigeProtocol {}
extension BrigeProtocol {
    // 获取真实类型信息的值
    static func get(from pointer: UnsafeRawPointer) -> Any {
        return pointer.assumingMemoryBound(to: Self.self).pointee
    }
}

// 协议的Metadata
// 协议见证表
struct ProtocolMetadata { // TargetWitnessTable
    let type: Any.Type // 真实类型
    let witness: Int
}

// 将一个Any.Type转换成BrigeProtocol
func getBitCast(type: Any.Type) -> BrigeProtocol.Type {
    let container = ProtocolMetadata(type: type, witness: 0)
    let bitCast = unsafeBitCast(container, to: BrigeProtocol.Type.self) // 将struct保存到Protocol的Metadata
    return bitCast
}
