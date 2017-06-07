import SwiftyJSON
import Foundation

public protocol KeyCodable {
    var codingKey: String { get }
}

public extension RawRepresentable where RawValue == String {
    var codingKey: String {
        return rawValue
    }
}

enum ConvenientRestKitError: Error {
    case noValueForKey(String)
    
    case wrongDateFormat
    case noDataInResponse
    case unexpectedCode(code: Int, message: Data?)
    case wrongJSONFormat
    
    case failedToInitializeRawRepresentable
    case awkwardURL(String)
}

extension ConvenientRestKitError: LocalizedError {
	var localizedDescription: String {
		switch self {
		case .noValueForKey(let key):
			return "No value for key " + key
		case .wrongDateFormat:
			return "Wrong date format"
		case .noDataInResponse:
			return "No data"
		case .unexpectedCode(code: let code, message: let data):
			if let data = data, let string = String(data: data, encoding: .utf8) {
				return "Unexpected code \(code) with message \(string)"
			} else {
				return "Unexpected code \(code)"
			}
		case .wrongJSONFormat:
			return "Wrong json format"
		case .failedToInitializeRawRepresentable:
			return "Failed to create from raw representable"
		case .awkwardURL(let urlValue):
			return "Awkward url " + urlValue
		}
	}
}

/// Elvis is now helps to throw
func ??<T>(lhs: T?, errorType: Error) throws -> T {
    if let value = lhs {
        return value
    } else {
        throw errorType
    }
}

///  array of JSONInitializable is JSONInitializable
extension Array where Element: JSONInitializable {
    init(json: JSON) throws {
        guard let arrayOfJSONs = json.array else { throw ConvenientRestKitError.wrongJSONFormat }
        self = try arrayOfJSONs.map { try Element(json: $0) }
    }
    
    public init(fileURL url: URL) throws {
        let data = try Data(contentsOf: url)
        let jsonObject = JSON(data: data)
        try self.init(json: jsonObject)
    }
}

extension Array where Element: JSONRepresentable {
    var json: JSON {
        return JSON(self.map({ $0.json }))
    }
    
    public func writeToFile(atURL url: URL) throws {
        let jsonData = try json.rawData()
        try jsonData.write(to: url)
    }
}

extension RequestConfigurationProtocol {
    static func json(forData data: Data?) throws -> JSON {
        return try data.flatMap({ JSON(data: $0) }) ?? ConvenientRestKitError.noDataInResponse
    }
    
    static func parsedObject<T: JSONInitializable>(forData data: Data?) throws -> T {
        return try T(json: json(forData: data))
    }
    
    static func parsedObjects<T: JSONInitializable>(forData data: Data?) throws -> [T] {
        return try [T](json: json(forData: data))
    }
    
    static func parsedObjects<T: JSONInitializable>(forData data: Data?, key: String) throws -> [T] {
        return try [T](json: json(forData: data)[key])
    }
    
    static func parsedObjects<T: JSONInitializable> (forJSON json: JSON, key: String) throws -> [T] {
        return try [T](json: json[key])
    }
    
    static func parsedObjects<T: JSONInitializable> (forJSON json: JSON) throws -> T {
        return try T(json: json)
    }
}

public extension JSON {
    
    init(keyCodables: (key: KeyCodable, value: AnyObject)...) {
        let dictionary = keyCodables.reduce([String : AnyObject]()) { (previousValue, element) in
            var valueCopy = previousValue
            valueCopy[element.key.codingKey] = element.value
            return valueCopy
        }
        self.init(dictionary)
    }
    
    init(keyCodables: [(key: KeyCodable, value: AnyObject)]) {
        let dictionary = keyCodables.reduce([String : AnyObject]()) { (previousValue, element) in
            var valueCopy = previousValue
            valueCopy[element.key.codingKey] = element.value
            return valueCopy
        }
        self.init(dictionary)
    }

    
    func value<T: JSONInitializable>(forKey key: KeyCodable) throws -> T {
        return try T(json: self[key])
    }
    
    func value<T>(forKey key: KeyCodable, jsonModifier: (JSON) -> T?) throws -> T {
        return try jsonModifier(self[key]) ?? ConvenientRestKitError.noValueForKey(key.codingKey)
    }
    
    func stringValue(forKey key: KeyCodable) throws -> String {
        return try value(forKey: key) { $0.string }
    }
    
    func string(forKey key: KeyCodable) -> String? {
        return self[key].string
    }
    
    func intValue(forKey key: KeyCodable) throws -> Int {
        return try value(forKey: key) { $0.int }
    }
    
    func int(forKey key: KeyCodable) -> Int? {
        return self[key].int
    }
    
    func boolValue(forKey key: KeyCodable) throws -> Bool {
        return try value(forKey: key) { $0.bool }
    }

    func bool(forKey key: KeyCodable) -> Bool? {
        return self[key].bool
    }
    
    func doubleValue(forKey key: KeyCodable) throws -> Double {
        return try value(forKey: key) { $0.double }
    }
    
    func double(forKey key: KeyCodable) -> Double? {
        return self[key].double
    }
    
    func urlValue(forKey key: KeyCodable) throws -> URL {
        let string = try stringValue(forKey: key)
        guard let url = URL(string: string) else {
            throw ConvenientRestKitError.awkwardURL(string)
        }
        return url
    }
    
    func url(forKey key: KeyCodable) -> URL? {
        guard let string = string(forKey: key) else {
            return nil
        }
        return URL(string: string)
    }
    
    func dateValue(forKey key: KeyCodable, dateFormatter: DateFormatter) throws -> Date {
        let dateString = try stringValue(forKey: key)
        return try dateFormatter.date(from: dateString) ?? ConvenientRestKitError.wrongDateFormat
    }
    
    func date(forKey key: KeyCodable, dateFormatter: DateFormatter) -> Date? {
        guard let dateString = string(forKey: key) else { return nil }
        return dateFormatter.date(from: dateString)
    }
    
    func rawRepresentableValue<T: RawRepresentable>(forKey key: KeyCodable, jsonValue: (JSON) -> T.RawValue?) throws -> T {
        let rawValue = try value(forKey: key, jsonModifier: jsonValue)
        return try T(rawValue: rawValue) ?? ConvenientRestKitError.failedToInitializeRawRepresentable
    }
    
    subscript (key: KeyCodable) -> JSON {
        return self[key.codingKey]
    }
}
