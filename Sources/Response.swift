//
//  Response.swift
//  Jonglamofire
//
//  Created by 안종표 on 2023/03/28.
//

import Foundation

public typealias AFDataResponse<Success> = DataResponse<Success, AFError>

public struct DataResponse<Success, Failure: Error>{
    //서버로 보낸 URLRequest
    public let request: URLRequest?
    
    //URLRequest에 대한 서버의 응답
    public let response: HTTPURLResponse?
    
    //서버로 부터 리턴받은 데이터
    public let data: Data?
    
    //serialize하는데 걸린 시간
    public let serialliaztionDuration: TimeInterval
    
    //response serialization의 결과
    public let result: Result<Success, Failure>
    
    //만약 결과가 성공이라면 연관된 값을 반환하고, 그렇지 않으면 nil을 반환합니다.
    public var value: Success? {result.success}
    
    //만약 결과가 실패라면 연관된 error를 반환하고, 그렇지 않으면 nil을 반환합니다.
    public var error: Failure? {result.failure}
    
    public init(request: URLRequest?,
                response: HTTPURLResponse?,
                data: Data?,
                serialliaztionDuration: TimeInterval,
                result: Result<Success, Failure>) {
        self.request = request
        self.response = response
        self.data = data
        self.serialliaztionDuration = serialliaztionDuration
        self.result = result
    }
}
