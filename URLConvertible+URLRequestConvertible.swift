//
//  URLConvertible+URLRequestConvertible.swift
//  Jonglamofire
//
//  Created by 안종표 on 2023/03/15.
//

import Foundation

public protocol URLConvertible{
    func asURL() throws -> URL
}

extension String: URLConvertible{
    public func asURL() throws -> URL
    {
        //임시 에러
        guard let url = URL(string: self) else {throw NSError(domain: "String -> URL 변경 error", code: 1004)}
        return url
    }
}

extension URL: URLConvertible{
    public func asURL() throws -> URL { self }
}

extension URLComponents: URLConvertible{
    public func asURL() throws -> URL{
        guard let url = url else {throw NSError(domain: "URLComponents.url -> URL 변경 error", code: 1004)}
        return url
    }
}

//MARK: - URLRequestConvertible
public protocol URLRequestConvertible
{
    func asURLRequest() throws -> URLRequest
}

extension URLRequestConvertible
{
    public var urlRequest: URLRequest? {try? asURLRequest()}
}

extension URLRequest: URLRequestConvertible
{
    public func asURLRequest() throws -> URLRequest { self }
}

extension URLRequest
{
    public init(url: URLConvertible, method: String) throws {
        let url = try url.asURL()
        
        self.init(url: url)
        
        httpMethod = method
    }
}
