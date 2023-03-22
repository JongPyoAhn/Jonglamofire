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
    
    
//    내가 생각했을 때 아직까지는 필요성을 느낄 수 없는 기능(필요하다고 생각 시 작성)
//    private func callCURLHandlerIfNecessary(){
//
//    }
    
    
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
