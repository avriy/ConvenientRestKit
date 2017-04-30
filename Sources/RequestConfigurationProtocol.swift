import Foundation

public protocol RequestConfigurationProtocol {
    associatedtype ResultType
    associatedtype DomainType: DomainProtocol
    
    var domain: DomainType { get }
    var apiPath: String { get }
    
    var methodType: HTTPMethodType { get }
    var content: RequestContent { get }
    func urlRequest() throws -> URLRequest
    static func processResponse(response: HTTPURLResponse, data: Data?) throws -> ResultType
    var session: URLSession { get }
}


public protocol GetRequestConfigurationProtocol: RequestConfigurationProtocol {
    
    static func parseResult(from data: Data) throws -> ResultType
    
}

public extension GetRequestConfigurationProtocol {
    
    var methodType: HTTPMethodType {
        return .get
    }
    
    var content: RequestContent {
        return .none
    }
    
    static func processResponse(response: HTTPURLResponse, data: Data?) throws -> ResultType {
        guard response.statusCode == 201 || response.statusCode == 200 else {
            fatalError()
        }
        
        guard let data = data else {
            throw ConvenientRestKitError.noDataInResponse
        }
        
        return try parseResult(from: data)
    }
    
}
