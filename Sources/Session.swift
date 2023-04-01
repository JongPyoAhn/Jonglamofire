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
    public let delegate: SessionDelegate
    public let rootQueue: DispatchQueue
    public let requestQueue: DispatchQueue
    public let serializationQueue: DispatchQueue
    public let startRequestsImmediately: Bool
    
    var requestTaskMap = RequestTaskMap()
    var activeRequests: Set<Request> = []
    //URLSessionTask에 대한 CompletionHandler를 저장한다.
    //RequestTaskMap에서 URLSessionTask의 completion 이벤트를 처리하기 전에 URLSessionTask에 대한 comletionHandler를 저장하는데 사용된다.
    var waitingCompletions: [URLSessionTask: () -> Void] = [:]
    
    public init
    (
        session: URLSession,
        delegate: SessionDelegate,
        rootQueue: DispatchQueue,
        requestQueue: DispatchQueue? = nil,
        serializationQueue: DispatchQueue? = nil,
        startRequestsImmediately: Bool = true
    )
    {
        
        precondition(session.configuration.identifier == nil, "Jonglamofire는 백그라운드 URLSessionConfiguration을 지원하지 않습니다. 쓰지마십쇼")
//        precondition(session.delegateQueue.underlyingQueue == rootQueue, "URLSession의 delegateQueue는 rootQueue에서 처리되어야 한다.")
        self.session = session
        self.delegate = delegate
        self.rootQueue = rootQueue
        self.requestQueue = requestQueue ?? DispatchQueue(label: "\(rootQueue.label).requestQueue", target: rootQueue)
        self.serializationQueue = serializationQueue ?? DispatchQueue(label: "\(rootQueue.label).serializationQueue", target: rootQueue)
        self.startRequestsImmediately = startRequestsImmediately
        delegate.stateProvider = self
    }
    
    public convenience init
    (
        configuration: URLSessionConfiguration = URLSessionConfiguration.jf.default,
        delegate: SessionDelegate = SessionDelegate(),
        rootQueue: DispatchQueue = DispatchQueue(label: "jonglamofire.rootQueue"),
        requestQueue: DispatchQueue? = nil,
        serializationQueue: DispatchQueue? = nil,
        startRequestsImmediately: Bool = true
    )
    {
        precondition(configuration.identifier == nil, "Jonglamofire는 백그라운드 URLSessionConfiguration을 지원하지 않습니다. 쓰지마십쇼")
        
        let serialRootQueue = (rootQueue === DispatchQueue.main) ? rootQueue : DispatchQueue(label: rootQueue.label, target: rootQueue)
        
        let delegateQueue = OperationQueue()
        delegateQueue.maxConcurrentOperationCount = 1
        delegateQueue.underlyingQueue = serialRootQueue
        delegateQueue.name = "\(serialRootQueue.label).sessionDelegate"
    
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
        self.init(session: session, delegate: delegate, rootQueue: serialRootQueue, startRequestsImmediately: startRequestsImmediately)
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
            serializationQueue: serializationQueue,
            delegate: self
        )
        perform(request)
        return request
    }
    
    
    //MARK: -perform
    func perform(_ request: Request)
    {
        rootQueue.async {
            self.activeRequests.insert(request)
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
        
        request.didCreateURLRequest(urlRequest)
        let task = request.task(for: urlRequest, using: session)
        requestTaskMap[request] = task
        request.didCreateTask(task)
        updateStatesForTask(task, request: request)
    }

    func updateStatesForTask(_ task: URLSessionTask, request: Request){
        dispatchPrecondition(condition: .onQueue(rootQueue))
        
        //멀티스레드 환경에서 state값을 안전하게 읽기위한 함수
        request.withState { state in
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
//MARK: - RequestDelegate
extension Session: RequestDelegate {
    public var sessionConfiguration: URLSessionConfiguration {
        session.configuration
    }
    
    public var startImmediately: Bool {
        startRequestsImmediately
    }
    
    public func cleanup(after request: Request) {
        activeRequests.remove(request)
    }
}

//MARK: - SessionStateProvider
extension Session: SessionStateProvider{
    //task에 해당하는 Request객체를 찾아서 반환한다.
    func request(for task: URLSessionTask) -> Request? {
        dispatchPrecondition(condition: .onQueue(rootQueue))
        
        return requestTaskMap[task]
    }
    
    //주어진 URLSessionTask 객체에 대한 처리가 완료되었음을 나타낸다.
    func didCompleteTask(_ task: URLSessionTask, completion: @escaping () -> Void) {
        dispatchPrecondition(condition: .onQueue(rootQueue))
        //task가 완료된 delegate시점에서 호출된것이라, metrics도 수집한 상태면 true리턴
        let didDisassociate = requestTaskMap.disassociateIfNecessaryAfterCompletingTask(task)
        
        if didDisassociate{
            //모든것이 정상적으로 완료된 시점
            completion()
        }else {
            //metrics가 아직 수집되지 않은시점(어떤경우지?)
            waitingCompletions[task] = completion
        }
    }
    
    
    func didGatherMetricsForTask(_ task: URLSessionTask){
        dispatchPrecondition(condition: .onQueue(rootQueue))
        
        //요청이 이미 완료되었으면 메모리에서 해제하기 위함이고, 이미 metrics를 수집했는데 또 수집한다면(?) fatalError
        //둘다아니면 정상적으로 false를 받음
        let didDisassociate = requestTaskMap.disassociateIfNecessaryAfterGatheringMetricsForTask(task)
        
        if didDisassociate{
            waitingCompletions[task]?()
            waitingCompletions[task] = nil
        }
    }

}


