//
//  RequestTaskMap.swift
//  Jonglamofire
//
//  Created by 안종표 on 2023/03/29.
//

import Foundation
//Session에서 실행중인 각 HTTP요청을 효율적으로 관리하고 제어한다.
//이를 통해 여러 개의 요청을 동시에 처리할 수 있다.
struct RequestTaskMap{
    
    private var tasksToRequests: [URLSessionTask: Request]
    private var requestsToTasks: [Request: URLSessionTask]

    init(tasksToRequests: [URLSessionTask : Request] = [:],
         requestsToTasks: [Request : URLSessionTask] = [:]) {
        self.tasksToRequests = tasksToRequests
        self.requestsToTasks = requestsToTasks
    }
    
    subscript(_ request: Request) -> URLSessionTask? {
        get { requestsToTasks[request] }
        set {
            guard let newValue = newValue else {
                guard let task = requestsToTasks[request] else{
                    fatalError()
                }
                
                requestsToTasks.removeValue(forKey: request)
                tasksToRequests.removeValue(forKey: task)
                
                return
            }
            requestsToTasks[request] = newValue
            tasksToRequests[newValue] = request
        }
    }
    
    subscript(_ task: URLSessionTask) -> Request? {
        get {tasksToRequests[task] }
        set {
            guard let newValue = newValue else{
                guard let request = tasksToRequests[task] else {
                    fatalError()
                }
                tasksToRequests.removeValue(forKey: task)
                requestsToTasks.removeValue(forKey: request)
                return
            }
            tasksToRequests[task] = newValue
            requestsToTasks[newValue] = task
        }
    }
}
