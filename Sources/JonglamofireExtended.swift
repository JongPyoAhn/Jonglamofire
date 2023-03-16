//
//  JonglamofireExtended.swift
//  Jonglamofire
//
//  Created by 안종표 on 2023/03/15.
//

import Foundation

public struct JonglamofireExtension<ExtendedType>{
    public private(set) var type: ExtendedType
    public init(_ type: ExtendedType) {
        self.type = type
    }
}

public protocol JonglamofireExtended{
    associatedtype ExtendedType
    static var jf: JonglamofireExtension<ExtendedType>.Type {get set}
    var jf: JonglamofireExtension<ExtendedType> {get set}
}

extension JonglamofireExtended{
    public static var jf: JonglamofireExtension<Self>.Type{
        get{ JonglamofireExtension<Self>.self}
        set {}
    }
    public var jf: JonglamofireExtension<Self>{
        get {JonglamofireExtension(self)}
        set {}
    }
}



