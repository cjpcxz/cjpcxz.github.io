//
//  TargetEnumMetadata.swift
//  SwiftSource
//
//  Created by 陈晶泊 on 2023/6/14.
//

import Foundation
// 枚举Metadata
struct TargetEnumMetadata {
    var kind: Int
    var typeDescriptor: UnsafeMutablePointer<TargetEnumDescriptor>
}

// 枚举描述器
struct TargetEnumDescriptor {
    var flags: Int32
    var parent: TargetRelativeDirectPointer<UnsafeRawPointer>
    var name: TargetRelativeDirectPointer<CChar>
    var accessFunctionPointer: TargetRelativeDirectPointer<UnsafeRawPointer>
    var fieldDescriptor: TargetRelativeDirectPointer<FieldDescriptor>
    var NumPayloadCasesAndPayloadSizeOffset: UInt32
    var NumEmptyCases: UInt32
    
    var genericArgumentOffset: Int { return 2 }
}

