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

final class UnfairLock: Lock{
    private let unfairLock: os_unfair_lock_t
    init() {
        //메모리공간을 1개만 할당하고 1개의 `os_unfair_lock_t`타입의 데이터를 저장할 수 있는 메모리공간을 할당
        unfairLock = .allocate(capacity: 1)
        //할당된 메모리공간에 os_unfair_lock()인스턴스를 초기화
        unfairLock.initialize(to: os_unfair_lock())
    }
    
    deinit{
        //메모리누수가 발생할 위험이 있어서 메모리해제전에 UnsafeMutablePointer로 생성한 메모리공간을 해제한다.
        //initialize로 인해 초기화된 인스턴스 메모리를 해제
        unfairLock.deinitialize(count: 1)
        unfairLock.deallocate()
    }
    
    fileprivate func lock(){
        //unfairLock에 락을 건다.
        os_unfair_lock_lock(unfairLock)
    }
    
    fileprivate func unlock(){
        os_unfair_lock_unlock(unfairLock)
    }
}

@propertyWrapper
@dynamicMemberLookup //동적멤버를 추가하고 접근할 수 있다.
final class Protected<T>{
    private let lock = UnfairLock()
    //Protected class가 보호하려는 값
    private var value: T
    
    init(value: T) {
        self.value = value
    }
    
    var wrappedValue: T {
        get {lock.around { return value }}
        set {lock.around { value = newValue }}
    }
    //$로 wrappedValue에 직접 접근할 수 있게 해준다.
    var projectedValue: Protected<T> { self }
    
    init(wrappedValue: T){
        value = wrappedValue
    }
    
    //T객체에 대한 읽기작업을 수행한다.
    //T객체를 보호하고 여러스레드에서 동시에 접근해도 안전하게 읽을 수 있도록 한다.
    func read<U>(_ closure: (T) throws -> U) rethrows -> U {
        return try lock.around{ try closure(self.value) }
    }
    
    //T객체에 대해 여러스레드에서 동시에 접근해도 안전하게 쓰기작업을 하게 한다.
    @discardableResult
    func write<U>(_ closure: (inout T) throws -> U) rethrows -> U{
        return try lock.around{ try closure(&self.value)}
    }
    
    //value의 프로퍼티에 접근하기 위해서 사용하는 동적멤버
    //WritableKeyPath는 속성값을 설정할 수 있는 키경로
    subscript<Property>(dynamicMember keyPath: WritableKeyPath<T, Property>) -> Property {
        get {lock.around { value[keyPath: keyPath]}}
        set {lock.around { value[keyPath: keyPath] = newValue}}
    }
    
    
    subscript<Property>(dynamicMember keyPath: KeyPath<T, Property>) -> Property{
        get{ lock.around { value[keyPath: keyPath] } }
    }
}
