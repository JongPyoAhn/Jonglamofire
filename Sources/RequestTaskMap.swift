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
    //completed: task가 완료되면 true로 설정
    //metricsGathered: task의 측정항목이 수집되면 true로 설정
    private typealias Events = (completed: Bool, metricsGathered: Bool)
    
    private var tasksToRequests: [URLSessionTask: Request]
    private var requestsToTasks: [Request: URLSessionTask]
    private var taskEvents: [URLSessionTask: Events]

    init(tasksToRequests: [URLSessionTask : Request] = [:],
         requestsToTasks: [Request : URLSessionTask] = [:],
         taskEvents: [URLSessionTask: (completed: Bool, metricsGathered: Bool)] = [:]) {
        self.tasksToRequests = tasksToRequests
        self.requestsToTasks = requestsToTasks
        self.taskEvents = taskEvents
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
                taskEvents.removeValue(forKey: task)
                return
            }
            requestsToTasks[request] = newValue
            tasksToRequests[newValue] = request
            taskEvents[newValue] = (completed: false, metricsGathered: false)
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
                taskEvents.removeValue(forKey: task)
                
                return
            }
            tasksToRequests[task] = newValue
            requestsToTasks[newValue] = task
            taskEvents[task] = (completed: false, metricsGathered: false)
        }
    }
    
    mutating func disassociateIfNecessaryAfterGatheringMetricsForTask(_ task: URLSessionTask) -> Bool{
        //URLRequest가 만들어졌을 때, didCreateURLRequest함수에서 request에 대한 taskEvents를 subscript의 set을 통해 설정해줌.
        guard let events = taskEvents[task] else {
            fatalError("RequestTaskMap consistency error: no events corresponding to task found.")
        }

        switch (events.completed, events.metricsGathered){
        case (_, true):
            fatalError("RequestTaskMap consistency error: duplicate metricsGatheredForTask call.")
        case (false, false):
            //해당 함수가 didFinishCollecting delegate가 호출될 때  사용되서 metricsGathered는 true가 된다.
            taskEvents[task] = (completed: false, metricsGathered: true)
            return false
        case (true, false):
            //RequestTask가 완료되었을 때
            //메모리에서 해제
            self[task] = nil
            return true
        }
        
    }
    
    
    mutating func disassociateIfNecessaryAfterCompletingTask(_ task: URLSessionTask) -> Bool{
        guard let events = taskEvents[task] else{
            fatalError("RequestTaskMap consistency error: no events corresponding to task found.")
        }
        switch (events.completed, events.metricsGathered) {
        case (true, _):
            fatalError("RequestTaskMap consistency error: duplicate completionReceivedForTask call.")
        case (false, false):
            taskEvents[task] = (completed: true, metricsGathered: false)
            return false
        case (false, true):
            self[task] = nil
            return true
        }
    }
}
