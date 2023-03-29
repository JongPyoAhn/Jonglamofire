//
//  SessionDelegate.swift
//  Jonglamofire
//
//  Created by 안종표 on 2023/03/29.
//

import Foundation
//URLSession에서 발생하는 이벤트를 처리한다.
open class SessionDelegate: NSObject{
    weak var stateProvider: SessionStateProvider?
    
    func request<R: Request>(for task: URLSessionTask, as type: R.Type) -> R? {
        guard let provider = stateProvider else {
            assertionFailure("StateProvider is nil")
            return nil
        }
        return provider.request(for: task) as? R
    }
    
}

extension SessionDelegate: URLSessionDataDelegate{
    //데이터 작업에서 새로운 데이터를 수신할 때 마다 호출된다.
    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        if let request = request(for: dataTask, as: DataRequest.self) {
            request.didReceive(data: data)
        }else{
            assertionFailure("dataTask did not find DataRequest in didReceive")
            return
        }
    }
}

//Alamofire에서 세션의 상태를 추적하고 세션에서 처리중인 모든 요청을 추적한다.
protocol SessionStateProvider: AnyObject{
    func request(for task: URLSessionTask) -> Request?
}
