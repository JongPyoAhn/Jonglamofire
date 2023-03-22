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
    public init
    (
        session: URLSession,
        rootQueue: DispatchQueue,
        requestQueue: DispatchQueue? = nil,
        serializationQueue: DispatchQueue? = nil
    )
    {
        
        precondition(session.configuration.identifier == nil, "Jonglamofire는 백그라운드 URLSessionConfiguration을 지원하지 않습니다. 쓰지마십쇼")
//        precondition(session.delegateQueue.underlyingQueue == rootQueue, "URLSession의 delegateQueue는 rootQueue에서 처리되어야 한다.")
        self.session = session
        self.rootQueue = rootQueue
        self.requestQueue = requestQueue ?? DispatchQueue(label: "\(rootQueue.label).requestQueue", target: rootQueue)
        self.serializationQueue = serializationQueue ?? DispatchQueue(label: "\(rootQueue.label).serializationQueue", target: rootQueue)
    }
    public convenience init
    (
        configuration: URLSessionConfiguration = URLSessionConfiguration.jf.default,
        rootQueue: DispatchQueue = DispatchQueue(label: "jonglamofire.rootQueue"),
        requestQueue: DispatchQueue? = nil,
        serializationQueue: DispatchQueue? = nil
    )
    {
        precondition(configuration.identifier == nil, "Jonglamofire는 백그라운드 URLSessionConfiguration을 지원하지 않습니다. 쓰지마십쇼")
        
        let serialRootQueue = (rootQueue === DispatchQueue.main) ? rootQueue : DispatchQueue(label: rootQueue.label, target: rootQueue)
        let session = URLSession(configuration: configuration)
        self.init(session: session, rootQueue: serialRootQueue)
    }
    
    deinit{
        //finishRequestsForDeinit()
        session.invalidateAndCancel()
    }
    struct RequestConvertible: URLRequestConvertible{
        let url: URLConvertible
        let method: String
        
        func asURLRequest() throws -> URLRequest {
            let request = try URLRequest(url: url, method: method)
            return request
        }
    }
    
    open func request(_ convertible: URLConvertible) -> DataRequest{
        let convertible = RequestConvertible(url: convertible, method: "GET")
        return request(convertible)
    }
    
    open func request(_ convertible: URLRequestConvertible) -> DataRequest
    {
        let request = DataRequest(
            convertible: convertible,
            underlyingQueue: rootQueue,
            serializationQueue: serializationQueue
        )
        perform(request)
        return request
    }
    
    
    //MARK: -perform
    func perform(_ request: Request)
    {
        rootQueue.async {
            self.requestQueue.async{
                guard let dataRequest = request as? DataRequest else {return}
                self.performDataRequest(dataRequest)
            }
        }
    }
    
    func performDataRequest(_ request: DataRequest){
        dispatchPrecondition(condition: .onQueue(requestQueue))
        performSetupOperations(for: request, convertible: request.convertible)
    }
    
    func performSetupOperations(for request: Request,
                                convertible: URLRequestConvertible){
        dispatchPrecondition(condition: .onQueue(requestQueue))
        
        let initialRequest: URLRequest = try! convertible.asURLRequest()
         
        rootQueue.async { request.didCreateURLRequest(initialRequest) }
        
        rootQueue.async {
            self.didCreateURLRequest(initialRequest, for: request)
        }

    }
    
    
    func didCreateURLRequest(_ urlRequest: URLRequest, for request: Request){
        dispatchPrecondition(condition: .onQueue(rootQueue))
        
        let task = request.task(for: urlRequest, using: session)
        updateStatesForTask(task, request: request)
    }

    func updateStatesForTask(_ task: URLSessionTask, request: Request){
        dispatchPrecondition(condition: .onQueue(rootQueue))
        
        //멀티스레드 환경에서 state값을 안전하게 읽기위한 함수
        request.withState { state in
            print(state)
            switch state{
            case .initialized, .finished:
                break
            case .resumed:
                task.resume()
            case .suspended:
                task.suspend()
            case .cancelled:
                task.resume()
                task.cancel()
            }
        }
    }
}



