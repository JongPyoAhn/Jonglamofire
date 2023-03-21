//
//  Protected.swift
//  Jonglamofire
//
//  Created by 안종표 on 2023/03/21.
//

import Foundation

private protocol Lock{
    func lock()
    func unlock()
}

extension Lock {
    //스레드의 안전성을 보장해주는 함수
    //lock하고 closure를 실행하고 defer를 통해 구문이 전부 끝났을 때 unlock()
    
    //반환값이 있는 클로저에 사용
    func around<T>(_ closure: () throws -> T) rethrows -> T{
        lock()
        defer { unlock() }
        return try closure()
    }
    
    func around(_ closure: () throws -> Void) rethrows {
        lock()
        defer {unlock()}
        try closure()
    }
}


