// //
////  main.swift
////  SwiftSource
////
////  Created by 陈晶泊 on 2023/3/26.
////
//
//import Foundation
//struct HeapObject {
//    var metadata: UnsafeRawPointer // 定义一个未知类型的指针
//    var refCounts: UInt32 // 引用计数
//}
//struct Metadata {
//    var kind: Int
//    var superClass: Any.Type
//    var cacheData: (Int, Int)
//    var data: Int
//    var classFlags: Int32
//    var instanceAddressPoint: UInt32
//    var instanceSize: UInt32
//    var instanceAlignmentMask: UInt16
//    var reserved: UInt16
//    var classSize: UInt32
//    var classAddressPoint: UInt32
//    var typeDescriptor: UnsafeMutableRawPointer
//    var iVarDestroyer: UnsafeRawPointer
//}
//
//struct TargetClassDescriptor{
//
//    //继承至TargetContextDescriptor
//    var flags: UInt32
//    var parent: UInt32
//
//    //继承至TargetTypeContextDescriptor
//    var name: Int32   // class/struct/enum 的名称
//    var accessFunctionPointer: Int32
//    var fieldDescriptor: Int32
//
//    //TargetClassDescriptor具有的
//    var superClassType: Int32
//    var metadataNegativeSizeInWords: UInt32
//    var metadataPositiveSizeInWords: UInt32
//    var numImmediateMembers: UInt32
//    var numFields: UInt32
//    var fieldOffsetVectorOffset: UInt32
//    var Offset: UInt32
////     var size: UInt32
//    // V-Table  (methods)
//}
//
//struct FieldDescriptor {
//    var MangledTypeName:Int32 // 混写后的类型名称
//    var Superclass:Int32
//    var Kind:uint16
//    var FieldRecordSize:uint16
//    var NumFields:uint32 // 属性个数
//    var FieldRecords:[FieldRecord]  // 记录了每个属性的信息
//}
//
//struct FieldRecord{
//    var Flags:uint32 // 标志位
//    var MangledTypeName:Int32 // 属性的类型名称
//    var FieldName:Int32 // 属性名称
//}
//class Circle {
//    var radius:Int = 9
////     diameter:Int = 18
//}
//
//let circle = Circle()
//// 通过Unmanaged指定内存管理，类似于OC与CF的交互方式（所有权的转换 __bridge）
//// passUnretained 不增加引用计数，即不需要获取所有权
//// passRetained 增加引用技术，即需要获取所有权
//// toOpaque 不透明的指针
//let ptr = Unmanaged.passUnretained(circle).toOpaque()
//// bindMemory更改当前UnsafeMutableRawPointer的指针类型，绑定到具体类型值
//// - 如果没有绑定，则绑定
//// - 如果已经绑定，则重定向到 HeapObject类型上
//let heapObject = ptr.bindMemory(to: HeapObject.self, capacity: 1)
//print(heapObject.pointee.metadata)
//print(heapObject.pointee.refCounts)
//let metadataPtr = heapObject.pointee.metadata.bindMemory(to: Metadata.self, capacity: 1)
//print(metadataPtr.pointee)
//let targetClassDescriptor = metadataPtr.pointee.typeDescriptor.bindMemory(to: TargetClassDescriptor.self, capacity: 1)
//print(targetClassDescriptor.pointee)
//print(targetClassDescriptor.pointee)

class Person {
    var name = "验证Metadata"
    var age = 18
    var time = 15.4
}

let person = Person() // 创建一个Person实例
var pClazz = Person.self // 拿到类对象
// 拿到ClassMetadata指针
print(MemoryLayout<Person.Type>.size,MemoryLayout<Any.Type>.size)
let classMetadata_ptr = unsafeBitCast(pClazz, to: UnsafeMutablePointer<TargetClassMetadata>.self)

//类的名字
let name_ptr = classMetadata_ptr.pointee.typeDescriptor.pointee.name.getmeasureRelativeOffset()
print(String(cString: name_ptr)) // Person
// 属性个数
let numFileds = classMetadata_ptr.pointee.typeDescriptor.pointee.numFields
print(numFileds)  // 2
// 拿到首个属性偏移地址信息
let offsets = classMetadata_ptr.pointee.typeDescriptor.pointee.getFieldOffsets(UnsafeRawPointer(classMetadata_ptr))
print(offsets,classMetadata_ptr.pointee.typeDescriptor.pointee.fieldOffsetVectorOffset,classMetadata_ptr)
print("size",classMetadata_ptr.pointee.typeDescriptor.pointee.fieldDescriptor.getmeasureRelativeOffset().pointee.fieldRecordSize)
for i in 0..<numFileds {
    // 获取属性名
    let fieldName = classMetadata_ptr.pointee.typeDescriptor.pointee.fieldDescriptor.getmeasureRelativeOffset().pointee.fields.index(of: Int(i)).pointee.fieldName.getmeasureRelativeOffset()
    print("fieldName：\(String(cString: fieldName))")
    
    // 混写过的类型名称
    let mangledTypeName = classMetadata_ptr.pointee.typeDescriptor.pointee.fieldDescriptor.getmeasureRelativeOffset().pointee.fields.index(of: Int(i)).pointee.mangledTypeName.getmeasureRelativeOffset()
    print("mangledTypeName：\(String(cString: mangledTypeName))")
    
    // 泛型向量
    let genericVector = UnsafeRawPointer(classMetadata_ptr).advanced(by: classMetadata_ptr.pointee.typeDescriptor.pointee.genericArgumentOffset * MemoryLayout<UnsafeRawPointer>.size).assumingMemoryBound(to: Any.Type.self)
    
    // 获取属性类型:
    // 新建C文件，声明这个函数 （CAPI.h）
//    let fieldType = swift_getTypeByMangledNameInContext(mangledTypeName,
//                                                        256,
//                                                        UnsafeRawPointer(classMetadata_ptr.pointee.typeDescriptor),
//                                                        UnsafeRawPointer(genericVector)?.assumingMemoryBound(to: Optional<UnsafeRawPointer>.self))
    let fieldType = _getTypeByMangledNameInContext(mangledTypeName,
                                                  256,
                                                  genericContext: UnsafeRawPointer(classMetadata_ptr.pointee.typeDescriptor),
                                                  genericArguments: UnsafeRawPointer(genericVector)?.assumingMemoryBound(to: Optional<UnsafeRawPointer>.self))!
//    let realType = unsafeBitCast(fieldType, to: Any.Type.self)
    print("realType: \(fieldType)")
    
    // 狡猾地把真实类型信息，保存到protocol的metadata，再通过Self.self获取真实类型
    let protocolType = getBitCast(type: fieldType)
    print("fieldType: \(protocolType)")
    // 对象的起始地址
    let instanceAddress = Unmanaged.passUnretained(person).toOpaque() // Teacher()的起始地址
    // 每个属性的偏移量
    let fieldOffset = offsets[Int(i)]
    
    // 获取属性的值
    let value = protocolType.get(from: instanceAddress.advanced(by: Int(fieldOffset)))
    
    print("fieldValue: \(value)")

    
    /*
    // HandyJSON 的方式 通过函数映射 （CApi.swift）
    let fieldType = _getTypeByMangledNameInContext(mangledTypeName,
                                                   256,
                                                   genericContext: UnsafeRawPointer(classMetadata_ptr.pointee.typeDescriptor),
                                                   genericArguments: UnsafeRawPointer(genericVector)?.assumingMemoryBound(to: Optional<UnsafeRawPointer>.self))
    
    print(fieldType as Any)
    */
   
    print("==================")
}
do {
    struct PersonStruct {
        var age:Int = 18
        let name:String = "Test"
        let sex = false
        var address = "SZ-2023"
        var birthday = ("2005", "12", "26")
    }

    print(MemoryLayout<PersonStruct.Type>.size,MemoryLayout<Any.Type>.size)
    var person = PersonStruct()
    let struct_ptr = unsafeBitCast(PersonStruct.self as Any.Type, to: UnsafeMutablePointer<TargetStructMetadata>.self)
    //类名
    let name_ptr = struct_ptr.pointee.typeDescriptor.pointee.name.getmeasureRelativeOffset()
    print(String(cString: name_ptr)) // PersonStruct

    //属性的数量,下面两种方式获取的数量是一致的
    let numFileds = struct_ptr.pointee.typeDescriptor.pointee.numFields
//    let numFileds = struct_ptr.pointee.typeDescriptor.pointee.fieldDescriptor.getmeasureRelativeOffset().pointee.numFields
    print("numFileds: \(numFileds)")
    print("size",struct_ptr.pointee.typeDescriptor.pointee.fieldDescriptor.getmeasureRelativeOffset().pointee.fieldRecordSize)
    
    let bufferPtr = struct_ptr.pointee.typeDescriptor.pointee.getFieldOffsets(UnsafeRawPointer(struct_ptr))
    for i in 0..<numFileds {
        let filedName = struct_ptr.pointee.typeDescriptor.pointee.fieldDescriptor.getmeasureRelativeOffset().pointee.fields.index(of: Int(i)).pointee.fieldName.getmeasureRelativeOffset()
        print("filedName: \(String(cString: filedName))")
        
        // 混写过的mangleTypeName
        let mangledTypeName = struct_ptr.pointee.typeDescriptor.pointee.fieldDescriptor.getmeasureRelativeOffset().pointee.fields.index(of: Int(i)).pointee.mangledTypeName.getmeasureRelativeOffset()
        
        // 泛型向量
        let genericVector = UnsafeRawPointer(struct_ptr).advanced(by: struct_ptr.pointee.typeDescriptor.pointee.genericArgumentOffset * MemoryLayout<UnsafeRawPointer>.size).assumingMemoryBound(to: Any.Type.self)
        
        
        // 获取属性类型:
        let fieldType = _getTypeByMangledNameInContext(mangledTypeName,
                                                       256,
                                                       genericContext: UnsafeRawPointer(classMetadata_ptr.pointee.typeDescriptor),
                                                       genericArguments: UnsafeRawPointer(genericVector)?.assumingMemoryBound(to: Optional<UnsafeRawPointer>.self))!
        // 属性类型 （
        print("filedType: \(fieldType)")
        
        // 对象的起始地址
        let instanceAddress = withUnsafeMutablePointer(to: &person){$0} // Person()的起始地址
        // 每个属性的偏移量
        let fieldOffset = bufferPtr[Int(i)]
        // 真实属性类型
        let realType = getBitCast(type: fieldType) // 把真实类型信息，保存到protocol的metadata，再通过Self.self获取真实类型
        print("realType: \(realType)")
        let value = realType.get(from: UnsafeRawPointer(UnsafeRawPointer(instanceAddress).advanced(by: numericCast(fieldOffset))))
        print("filedValue: \(value)")
        
        print("========================================")
    }
}

//MARK: - Mirror
do {
    class Person {
        var num = 0
        var name = "Tome"
        
        func say() {
            print("say hi")
        }
    }

    let mirr = Mirror(reflecting: Person())
    print(mirr.displayStyle)
    print(mirr.subjectType)
    for (label,value) in mirr.children {
        print(label,value)
    }
    func test(_ value: Any) {
        print(type(of: value))
    }

    func getKeyValue(_ mirrorObj: Any) -> Any {
        let mirror = Mirror(reflecting: mirrorObj)
        guard !mirror.children.isEmpty else{ return mirrorObj }
        var result: [String: Any] = [:]
        for child in mirror.children{
            if let key = child.label{
                result[key] = getKeyValue(child.value)
            }else{
                print("No Keys")
            }
        }
        return result
    }
    print(getKeyValue(Person()))
}

//MARK: 结构体
do {
    enum TerminalChar {
        case plain(Bool)
        case bold(Int)
        case empty
        case cursor
    }
    print(MemoryLayout<TerminalChar.Type>.size,MemoryLayout<Any.Type>.size)
    let enumMetadata_ptr = unsafeBitCast(TerminalChar.self as Any.Type, to: UnsafeMutablePointer<TargetEnumMetadata>.self)
    let namePtr = enumMetadata_ptr.pointee.typeDescriptor.pointee.name.getmeasureRelativeOffset()
    print(String(cString: namePtr))
    
    print(enumMetadata_ptr.pointee.typeDescriptor.pointee.NumPayloadCasesAndPayloadSizeOffset) // 2
    print(enumMetadata_ptr.pointee.typeDescriptor.pointee.NumEmptyCases) // 2

    // 拿到属性描述器指针
    let fieldDesc_ptr = enumMetadata_ptr.pointee.typeDescriptor.pointee.fieldDescriptor.getmeasureRelativeOffset()
//    let mangledName = fieldDesc_ptr.pointee.mangledTypeName.getmeasureRelativeOffset()
    
    let genericVector = UnsafeRawPointer(enumMetadata_ptr).advanced(by: enumMetadata_ptr.pointee.typeDescriptor.pointee.genericArgumentOffset * MemoryLayout<UnsafeRawPointer>.size).assumingMemoryBound(to: Any.Type.self)
    
    
    let dss = fieldDesc_ptr.pointee.superclass.getmeasureRelativeOffset()
    print(String(cString: fieldDesc_ptr.pointee.superclass.getmeasureRelativeOffset()))
    print(fieldDesc_ptr.pointee.kind) // 3
    print(fieldDesc_ptr.pointee.fieldRecordSize) // 12
    print(fieldDesc_ptr.pointee.numFields) // 4
    let mangledName = fieldDesc_ptr.pointee.fields.index(of: 0).pointee.mangledTypeName.getmeasureRelativeOffset()
    let fieldType = _getTypeByMangledNameInContext(mangledName,
                                                   256,
                                                   genericContext: UnsafeRawPointer(enumMetadata_ptr.pointee.typeDescriptor),
                                                   genericArguments: UnsafeRawPointer(genericVector)?.assumingMemoryBound(to: Optional<UnsafeRawPointer>.self))!
    print(fieldType)
    print(String(cString: fieldDesc_ptr.pointee.fields.index(of: 0).pointee.fieldName.getmeasureRelativeOffset())) // plain

}

do {
    func swift_add(_ a: Double, _ b: Double) -> Int {
        return Int(a + b)
    }

    print(type(of: swift_add))
    //引用类型
    var a: (Double, Double) -> Int = swift_add
    let z = withUnsafePointer(to: &a) { $0}
    let ds = UnsafeRawPointer(bitPattern: UnsafeRawPointer(z).load(as: Int.self))
    print(a(10, 20))

    var b = a
    let z1 = withUnsafePointer(to: &b) { $0 }
    print(b(20 ,30))
    let functionType = type(of: swift_add)
    let functionPointer = unsafeBitCast(functionType as Any.Type, to: UnsafeMutablePointer<TargetFunctionTypeMetadata>.self)
    print(functionPointer.pointee.numberArguments())//2
    print(functionPointer.pointee.arguments.index(of: 0).pointee) // Double
    print(unsafeBitCast(functionPointer.pointee.resultType, to: Any.Type.self))
}


