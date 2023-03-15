//
//  Session.swift
//  Jonglamofire
//
//  Created by 안종표 on 2023/03/14.
//

import Foundation
open class Session{
    public static let `default` = Session()
    public let session: URLSession
    public let rootQueue: DispatchQueue
    public let requestQueue: DispatchQueue
    public let serializationQueue: DispatchQueue
    public init(session: URLSession,
                rootQueue: DispatchQueue,
                requestQueue: DispatchQueue? = nil,
                serializationQueue: DispatchQueue? = nil) {
        
        precondition(session.configuration.identifier == nil, "Jonglamofire는 백그라운드 URLSessionConfiguration을 지원하지 않습니다. 쓰지마십쇼")
        precondition(session.delegateQueue.underlyingQueue == rootQueue, "URLSession의 delegateQueue는 rootQueue에서 처리되어야 한다.")
        self.session = session
        self.rootQueue = rootQueue
        self.requestQueue = requestQueue ?? DispatchQueue(label: "\(rootQueue.label).requestQueue", target: rootQueue)
        self.serializationQueue = serializationQueue ?? DispatchQueue(label: "\(rootQueue.label).serializationQueue", target: rootQueue)
    }
}