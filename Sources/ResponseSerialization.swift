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
            
        }
    }
    
    
    
}
