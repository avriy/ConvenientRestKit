import Foundation
import SwiftyJSON

public protocol DomainProtocol {
    var baseURL: URL { get }
}

public struct URLDomain: DomainProtocol {
    public let baseURL: URL
}

public enum RequestContent {
    case json(JSON), none
    
    public init(dictionary: [String: AnyObject]) {
        self = .json(JSON(dictionary))
    }

    fileprivate var httpHeaderField: String {
        switch self {
        case .json(_):
            return "application/json"
        case .none:
            fatalError("Can not apply httpHeaderField for RequestContent.none")
        }
    }
}

public enum HTTPMethodType: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public extension URLRequest {

    static func request(url: URL, method: HTTPMethodType, contentType: RequestContent, etag: String? = nil) throws -> URLRequest {
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        switch contentType {
        case .json(let jsonValue):
            request.addValue(contentType.httpHeaderField, forHTTPHeaderField: "Content-Type")
            request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
            request.httpBody = try jsonValue.rawData()
        case .none:
            break
        }
        if let etag = etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
            request.cachePolicy = .reloadIgnoringLocalCacheData
        }
        return request
    }
}

public extension RequestConfigurationProtocol where ResultType: JSONInitializable {
    
    static func processResponse(response: HTTPURLResponse, data: Data?) throws -> ResultType {
        guard let data = data else {
            throw ConvenientRestKitError.noDataInResponse
        }
        let json = JSON(data: data)
        return try ResultType(json: json)
    }
}

public extension RequestConfigurationProtocol {
    
    func urlRequest() throws -> URLRequest {
        let url = apiPath.isEmpty ? domain.baseURL : domain.baseURL.appendingPathComponent(apiPath)
        return try URLRequest.request(url: url, method: methodType, contentType: content)
    }
    
    func dataTask(errorHandler eh: @escaping (Error) -> Void, successHandler sh: @escaping (Self.ResultType) -> Void) throws -> URLSessionDataTask {
        let request = try urlRequest()
        return session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                return eh(error)
            }
            
            let response = response as! HTTPURLResponse
            do {
                let result = try Self.processResponse(response: response, data: data)
                sh(result)
            } catch {
                eh(error)
            }
        }
    }
    
    func performTask(errorHandler eh: @escaping (Error) -> Void, successHandler sh: @escaping (Self.ResultType) -> Void) {
        do {
            let task = try dataTask(errorHandler: eh, successHandler: sh)
            task.resume()
        } catch {
            eh(error)
        }
        
    }
}
