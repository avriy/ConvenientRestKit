import XCTest
@testable import ConvenientRestKit
import SwiftyJSON

struct Scarer {
    let name: String
    let nickname: String?
    let url: URL
}

extension Scarer: JSONInitializable {
    enum CodingKeys: String, KeyCodable {
        case name, nickname, url
    }
    
    init(json: JSON) throws {
        
        name = try json.stringValue(forKey: CodingKeys.name)
        nickname = json.string(forKey: CodingKeys.nickname)
        let urlString = try json.stringValue(forKey: CodingKeys.url)
        url = URL(string: urlString)!
        
    }
}

struct GetScarers: RequestConfigurationProtocol {
    
    let domain = URLDomain(baseURL: URL(string: "https://avriy.github.io")!)
    let apiPath = "scarers"
    let methodType: HTTPMethodType = .get
    let content: RequestContent = .none
    let session: URLSession = .shared
    
    static func processResponse(response: HTTPURLResponse, data: Data?) throws -> [Scarer] {
        if let data = data {
            let jsonObject = JSON(data: data)
            return try [Scarer](json: jsonObject)
        }
        
        return []
    }
}

#if os(macOS)

struct GetScarerImage: RequestConfigurationProtocol {
    let domain: URLDomain
    let apiPath = ""
    let methodType: HTTPMethodType = .get
    let content: RequestContent = .none
    let session: URLSession = .shared
    
    init(scarer: Scarer) {
        domain = URLDomain(baseURL: scarer.url)
    }
    
    static func processResponse(response: HTTPURLResponse, data: Data?) throws -> NSImage {
        guard let data = data, let image = NSImage(data: data) else {
            throw CodingErrors.noDataInResponse
        }
        
        return image
    }
}

#endif

class ConvenientRestKitTests: XCTestCase {
    
    func errorHandler(for expectation: XCTestExpectation) -> ((Error) -> Void) {
        return { error in
            expectation.fulfill()
            XCTFail("Failed with \(error)")
        }
    }
    
    func testDownloadScarers() {
        let canDownloadScarers = expectation(description: "Can download scarers")
        
        GetScarers().performTask(errorHandler: errorHandler(for: canDownloadScarers)) { result in
            canDownloadScarers.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
    }
    
#if os(macOS)
    
    func testDownloadScarerImage() {
        let canDownloadScarerImage = expectation(description: "Can download scarer image")
        let mike = Scarer(name: "Mike Wazowski", nickname: nil, url: URL(string: "https://yt3.ggpht.com/-qKieNm4z4W4/AAAAAAAAAAI/AAAAAAAAAAA/kAhPHqgE5N4/s900-c-k-no-mo-rj-c0xffffff/photo.jpg")!)
        
        GetScarerImage(scarer: mike).performTask(errorHandler: errorHandler(for: canDownloadScarerImage)) { image in
            canDownloadScarerImage.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
    }

#endif

    static var allTests = [
        ("testExample", testDownloadScarers),
    ]
}
