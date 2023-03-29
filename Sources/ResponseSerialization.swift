//
//  ResponseSerialization.swift
//  Jonglamofire
//
//  Created by 안종표 on 2023/03/28.
//

import Foundation

extension DataRequest {
    
    @discardableResult
    public func response(queue: DispatchQueue = .main, completionHandler: @escaping (AFDataResponse<Data?>) -> Void) -> Self{
        appendResponseSerializer {
            //현재 Request한 상태에 error가 없으면 Success, 있으면 Failure가 된다.
            //SerializationQueue에서 실행 시작
            let result = AFResult<Data?>(value: self.data, error: self.error)
            //SerializationQueue에서 실행 끝
            
            self.underlyingQueue.async {
                let response = DataResponse(
                    request: self.request,
                    response: self.response,
                    data: self.data,
                    serialliaztionDuration: 0,
                    result: result
                )
                //해당 serializer를 responseSerializerCompletions에 추가하고, processNextResponseSerializer()함수로 다음 serializer를 실행하는 역할 이런 방식으로 serializer를 차례대로 수행할 수 있음.
                self.responseSerializerDidComplete { queue.async { completionHandler(response) } }
            }
        }
        return self
    }
    
    
    
}
