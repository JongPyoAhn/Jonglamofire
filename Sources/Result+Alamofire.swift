//
//  Result+Alamofire.swift
//  Jonglamofire
//
//  Created by 안종표 on 2023/03/28.
//

import Foundation
//네트워크 요청이 성공적으로 완료되었는지, 실패했는지 또는 요청을 취소했는지를 나타내는 값 중 하나를 가집니다.
public typealias AFResult<Success> = Result<Success, AFError>

extension Result{
    
    var isSuccess: Bool{
        guard case .success = self else {return false}
        return true
    }
    
    var isFailure: Bool{
        !isSuccess
    }
    //성공했을 때 value값
    var success: Success? {
        guard case let .success(value) = self else {return nil}
        return value
    }
    //실패했을 때 error
    var failure: Failure? {
        guard case let .failure(error) = self else {return nil}
        return error
    }
    
    init(value: Success, error: Failure?){
        if let error = error{
            self = .failure(error)
        }else{
            self = .success(value)
        }
    }
}

