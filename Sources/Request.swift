//
//  Request.swift
//  Jonglamofire
//
//  Created by 안종표 on 2023/03/15.
//

import Foundation
public class Request{
    //Request를 위한 unique identifier를 제공하는 UUID
    public let id: UUID
    //모든 내부의 비동기 액션들을 위한 Serial Queue
    public let underlyingQueue: DispatchQueue
    //underlyingQueue를 타겟으로하는 Serial Queue
    //직렬화 액션에 사용되는 큐
    public let serializationQueue: DispatchQueue
    
    init
    (
        id: UUID,
        underlyingQueue: DispatchQueue,
        serializationQueue: DispatchQueue
    )
    {
        self.id = id
        self.underlyingQueue = underlyingQueue
        self.serializationQueue = serializationQueue
    }
    func task(for request: URLRequest, using session: URLSession) -> URLSessionTask{
        fatalError("반드시 서브클래싱해야됨")
    }
}

//MARK: -
public class DataRequest: Request{
    public let convertible: URLRequestConvertible
    
    init
    (
        id: UUID = UUID(),
        convertible: URLRequestConvertible,
        underlyingQueue: DispatchQueue,
        serializationQueue: DispatchQueue
    )
    {
        self.convertible = convertible
        
        super.init(id: id, underlyingQueue: underlyingQueue, serializationQueue: serializationQueue)
    }
    
    override func task(for request: URLRequest, using session: URLSession) -> URLSessionTask {
        let copiedRequest = request
        return session.dataTask(with: copiedRequest)
    }

}
