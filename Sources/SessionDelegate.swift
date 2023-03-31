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

//Alamofire에서 세션의 상태를 추적하고 세션에서 처리중인 모든 요청을 추적한다.
protocol SessionStateProvider: AnyObject{
    func request(for task: URLSessionTask) -> Request?
    func didCompleteTask(_ task: URLSessionTask, completion: @escaping () -> Void)
    func didGatherMetricsForTask(_ task: URLSessionTask)
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

extension SessionDelegate: URLSessionTaskDelegate{
    //URLSessionTaskMetrics: URLSessionTask의 성능과 관련된 정보 제공하는 객체
    //URLSessionTask와 관련된 측정항목 수집하고, 해당 정보를 처리하는 역할
    open func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        
        stateProvider?.request(for: task)?.didGatherMetrics(metrics)
        
        stateProvider?.didGatherMetricsForTask(task)
    }
    open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        let request = stateProvider?.request(for: task)
        
        stateProvider?.didCompleteTask(task) {
            request?.didCompleteTask(task, with: error as? AFError)
        }
    }
    
    
}
