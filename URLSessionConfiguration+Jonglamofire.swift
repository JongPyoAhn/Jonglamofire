//
//  URLSessionConfiguration+Jonglamofire.swift
//  Jonglamofire
//
//  Created by 안종표 on 2023/03/15.
//

import Foundation
extension URLSessionConfiguration: JonglamofireExtended{}
extension JonglamofireExtension where ExtendedType: URLSessionConfiguration{
    public static var `default`: URLSessionConfiguration{
        let configuration = URLSessionConfiguration.default
        return configuration
    }
    public static var ephemeral: URLSessionConfiguration{
        let configuration = URLSessionConfiguration.ephemeral
        return configuration
    }
}
