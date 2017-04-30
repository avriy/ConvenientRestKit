import SwiftyJSON
import Foundation

public protocol JSONInitializable {
    init(json: JSON) throws
}

public protocol JSONRepresentable {
    var json: JSON { get }
}

public protocol JSONCoding: JSONInitializable, JSONRepresentable {
}

public extension JSONRepresentable {
    func writeToFile(atURL url: URL) throws {
        let data = try json.rawData()
        try data.write(to: url)
    }
}

public extension JSONInitializable {
    init(fileURL url: URL) throws {
        let data = try Data(contentsOf: url)
        let jsonObject = JSON(data: data)
        try self.init(json: jsonObject)
    }
}
