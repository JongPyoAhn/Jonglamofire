//
//  Request.swift
//  Jonglamofire
//
//  Created by 안종표 on 2023/03/15.
//

import Foundation
public class Request{
    //네트워크 Request 상태
    //mutableState를 통해 보호되는 멀티스레드 환경에서 변경될것이다.
    //Alamofire는 State값을 기반으로 적절한 처리를 수행한다.
    public enum State {
        //요청이 초기화되었을 때
        case initialized
        //요청이 실행되었을 때
        case resumed
        //요청이 일시 중지되었을 때
        case suspended
        //요청이 취소되었을 때
        case cancelled
        //요청이 완료되었을 때
        case finished
        //원하는 상태로 변경할 수 있는지 확인하는 함수
        func canTransitionTo(_ state: State) -> Bool {
            switch (self, state) {
            case (.initialized, _):
                return true
            case (_, .initialized), (.cancelled, _), (.finished, _):
                return false
            case (.resumed, .cancelled), (.suspended, .cancelled), (.resumed, .suspended), (.suspended, .resumed):
                return true
            case (.suspended, .suspended), (.resumed, .resumed):
                return false
            case (_, .finished):
                return true
            }
        }
    }
    //Request의 State를 변경하기위한 구조체
    //MutableState는 변경될 수 있는 요청의 상태를 추적하고 요청의 현재 상태를 나태낼 수 있는 프로퍼티들을 보유한다.
    struct MuatbleState{
        //Request의 상태
        var state: State = .initialized
        //Request 객체에서 생성된 모든 URLReuqest들을 추적하고 처리한다.
        var requests: [URLRequest] = []
        //Request가 URLRequest를 생성할 때 호출되는 closure와 해당 closure가 실행되는 DispatchQueue를 저장합니다.
        var urlRequestHandler: (queue: DispatchQueue, handler: (URLRequest) -> Void)?
        //네트워크 요청을 처리하는데 사용되는 핸들러중 하나이며, 요청의 작동, 요청헤더, 바디를 쉽게확인할 수 있어서 디버깅에 유용하다.
        //네트워크 요청을 처리할 때 cURL명령어로 변환하여 저장
        var cURLHandler: (queue: DispatchQueue, handler: (String) -> Void)?
        //모든 URLSessionTask들을 저장
        var tasks: [URLSessionTask] = []
        //response 파싱하는 Serialization response
        var responseSerializers: [() -> Void] = []
        //responseSerializer과정이 끝낫는지 아닌지를 확인하기 위한 프로퍼티
        var responseSerializerProcessingFinished = false
        //response Serialization 완료 시 실행되는 completion Closure. 모든 response Serialization이 완료된 후에 실행된다.
        var responseSerializerCompletions: [() -> Void] = []
        //DataRequest객체가 finish()메서드를 호출하여 요청이 완료되었는지 여부를 나타내는데 사용된다.
        var isFinishing = false
        //요청이 완료될 때 실행할 작업, 동시성 지원에 사용된다.
        var finishHandlers: [() -> Void] = []
    }
    
    @Protected
    fileprivate var mutableState = MuatbleState()
    
    func didCreadteInitialURLRequest(_ request: URLRequest){
        dispatchPrecondition(condition: .onQueue(underlyingQueue))
        
        $mutableState.write { $0.requests.append(request) }
    }
    
    func withState(perform: (State) -> Void){
        //멀티스레드 환경에서 state값을 안전하게 읽기위한 함수
        $mutableState.withState(perform: perform)
    }
    
    func didCreateURLRequest(_ request: URLRequest){
        dispatchPrecondition(condition: .onQueue(underlyingQueue))
        //
        $mutableState.read { state in
            //비동기로 처리하여 메인스레드가 블로킹되지 않게함
            state.urlRequestHandler?.queue.async {state.urlRequestHandler?.handler(request)}
        }
    }
    @discardableResult
    public func resume() -> Self{
        $mutableState.write { mutableState in
            //상태를 resume으로 변경가능한지 확인
            guard mutableState.state.canTransitionTo(.resumed) else {return}
            //상태 변경
            mutableState.state = .resumed
            //현재 진행중인 request를 resume()하는거니까 task의 가장 마지막에 추가된게 확실하고, task가 완수된 상태면 그만하는게 맞다.
            guard let task = mutableState.tasks.last, task.state != .completed else {return}
            task.resume()
        }
        return self
    }
  
    
    //Request를 위한 unique identifier를 제공하는 UUID
    public let id: UUID
    //모든 내부의 비동기 액션들을 위한 Serial Queue
    public let underlyingQueue: DispatchQueue
    //underlyingQueue를 타겟으로하는 Serial Queue
    //직렬화 액션에 사용되는 큐
    public let serializationQueue: DispatchQueue
    //외부에서 읽기만 가능하고 내부에서는 읽/쓰
    //RequestDelegate: 객체의 요청 수행 중 다양한 이벤트와 상태변경을 감지하고 처리하기 위한 프로토콜
    public private(set) weak var delegate:RequestDelegate?
    
    
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
    //HTTP 요청에 대한 응답 데이터를 저장하는 데 사용됩니다.
    public var data: Data? {mutableData}
    
    //읽기 쓰기가 가능하고 thread-safe하게 접근가능한 mutableData
    @Protected
    private var mutableData: Data? = nil
    
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
    //응답데이터를 처리 할 Serializer를 등록하는 역할
    //Serializer: 응답데이터를 파싱하여 사용하기 적합한 형태로 변환해주는 객체
    func appendResponseSerializer(_ closure: @escaping () -> Void){
        $mutableState.write { mutableState in
            mutableState.responseSerializers.append(closure)
            
            //DataRequest객체가 이전에 완료되었다가 다시 시작되는 경우를 처리
            if mutableState.state == .finished {
                mutableState.state = .resumed
            }
            //Serializer 처리가 끝낫다고 되있으면 다음 Serializer를 찾아봄.
            if mutableState.responseSerializerProcessingFinished{
                underlyingQueue.async {
                    self.processNextResponseSerializer()
                }
            }
            //resume상태로 변경 가능하다는 것은 resume()이 가능하다는 것이다. 따라서 startImmediately를 확인하여 다른작업을 먼저할게 없다면 resume()
            if mutableState.state.canTransitionTo(.resumed){
                underlyingQueue.async {
                    if self.delegate?.startImmediately == true {self.resume()}
                }
            }
            
        }
    }
    //DataRequest 객체에서 다음 response Serializer를 실행하는 역할
    func processNextResponseSerializer() {
        //다음에 실행할 Serializer가 있으면
        guard let responseSerializer = nextResponseSerializer() else {
            //다음에 실행할 Serializer가 없으면
            //모든 response Serialization closure를 실행하고 삭제한다.
            var completions: [() -> Void] = []
            
            $mutableState.write { mutableState in
                completions = mutableState.responseSerializerCompletions
                mutableState.responseSerializers.removeAll()
                mutableState.responseSerializerCompletions.removeAll()
                
                if mutableState.state.canTransitionTo(.finished) {
                    mutableState.state = .finished
                }
                
                mutableState.responseSerializerProcessingFinished = true
                mutableState.isFinishing = false
            }
            //mutableState에 responseSerializerCompletions를 모두 실행
            completions.forEach{$0()}
            
            cleanup()
            return
        }
        serializationQueue.async { responseSerializer() }
    }
    
    
    //DataRequest 객체에서 아직 처리되지 않은 다음 response Serializer를 반환하는 역할
    func nextResponseSerializer() -> (() -> Void)? {
        var responseSerializer: (() -> Void)?
        
        //responseSerializerCompletions가 완료된것들 저장하는 곳인데, responseSerializerIndex가 responseSerializers.count보다 작다는것은 아직 완료되지않은 Serializer가 있는것이므로 완료된것 다음번의것을 실행하는 의미의 구문
        $mutableState.write { mutableState in
            let responseSerializerIndex = mutableState.responseSerializerCompletions.count
            if responseSerializerIndex < mutableState.responseSerializers.count{
                responseSerializer = mutableState.responseSerializers[responseSerializerIndex]
            }
        }
        return responseSerializer
    }
    
    func cleanup(){
        delegate?.cleanup(after: self)
        let handlers = $mutableState.finishHandlers
        //요청이 완료될때 실행할 작업을 실행
        handlers.forEach{$0()}
        $mutableState.write { mutableState in
            mutableState.finishHandlers.removeAll()
        }
    }
}
//DataRequest 객체가 SessionDelegate 객체와 통신할 때 사용하는 프로토콜
public protocol RequestDelegate: AnyObject {
    //URLSessionTask을 구성하기 위한 configuration
    var sessionConfiguration: URLSessionConfiguration {get}
    //Request객체가 처음 response Handler를 추가할 때 자동으로 resume() 메소드를 호출해야하는지 여부를 결정한다. true이면, 요청객체가 만들어지는 즉시 서버로 전송된다.
    var startImmediately: Bool {get}
    //Request가 완료되었을 때, Request가 사용한 자원들을 해제하기 위한 역할을 수행한다.
    func cleanup(after request: Request)
}
