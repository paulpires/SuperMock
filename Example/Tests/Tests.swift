import UIKit
import XCTest
@testable import SuperMock

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        SuperMock.beginMocking(Bundle(for: AppDelegate.self))
    }
    
    override func tearDown() {
        super.tearDown()
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as? String
        let filePath = (documentsDirectory)! + "/Mocks.plist"
        
        do {try FileManager.default.removeItem(atPath: filePath)} catch{}
        SuperMock.endMocking()
    }
    
    func testValidGETRequestWithMockReturnsExpectedMockedData() {
        
        let responseHelper = SuperMockResponseHelper.sharedHelper
        
        let url = URL(string: "http://mike.kz/")!
        let realRequest = NSMutableURLRequest(url: url)
        realRequest.httpMethod = "GET"
        let mockRequest = responseHelper.mockRequest(realRequest as URLRequest)
        
        let bundle = Bundle(for: AppDelegate.self)
        let pathToExpectedData = bundle.path(forResource: "sample", ofType: "html")!
        
        let expectedData = try? Data(contentsOf: URL(fileURLWithPath: pathToExpectedData))
        let returnedData = responseHelper.responseForMockRequest(mockRequest as URLRequest!)
        
        XCTAssert(expectedData == returnedData, "Expected data not received for mock.")
        
    }
    
    func testValidPOSTRequestWithMockReturnsExpectedMockedData() {
        
        let responseHelper = SuperMockResponseHelper.sharedHelper
        
        let url = URL(string: "http://mike.kz/")!
        let realRequest = NSMutableURLRequest(url: url)
        realRequest.httpMethod = "POST"
        let mockRequest = responseHelper.mockRequest(realRequest as URLRequest)
        
        let bundle = Bundle(for: AppDelegate.self)
        let pathToExpectedData = bundle.path(forResource: "samplePOST", ofType: "html")!
        
        let expectedData = try? Data(contentsOf: URL(fileURLWithPath: pathToExpectedData))
        let returnedData = responseHelper.responseForMockRequest(mockRequest as URLRequest!)
        
        XCTAssert(expectedData == returnedData, "Expected data not received for mock.")
        
    }
    
    func testValidRequestWithNoMockReturnsOriginalRequest() {
        let responseHelper = SuperMockResponseHelper.sharedHelper
        
        let url = URL(string: "http://nomockavailable.com")!
        let realRequest = URLRequest(url: url)
        let mockRequest = responseHelper.mockRequest(realRequest)
        
        XCTAssert(realRequest == mockRequest as URLRequest, "Original request should be returned when no mock is available.")
    }
    
    func testValidRequestWithMockReturnsDifferentRequest() {
        let responseHelper = SuperMockResponseHelper.sharedHelper
        
        let url = URL(string: "http://mike.kz/")!
        let realRequest = URLRequest(url: url)
        let mockRequest = responseHelper.mockRequest(realRequest)
        
        XCTAssert(realRequest != mockRequest as URLRequest, "Different request should be returned when a mock is available.")
    }
    
    func testValidRequestWithMockReturnsFileURLRequest() {
        let responseHelper = SuperMockResponseHelper.sharedHelper
        
        let url = URL(string: "http://mike.kz/")!
        let realRequest = URLRequest(url: url)
        let mockRequest = responseHelper.mockRequest(realRequest)
        
        XCTAssertNotNil(mockRequest.url?.isFileURL, "baseURL mocked request should be returned when a mock is available.")
    }
    
    func testRecordDataAsMock() {
        
        let url = URL(string: "http://mike.kz/Daniele")!
        let realRequest = URLRequest(url: url)
        
        let responseString = "Something to put into the response field"
        
        let responseHelper = SuperMockResponseHelper.sharedHelper
        let expectedData = responseString.data(using: String.Encoding.utf8)!
        
        responseHelper.recordDataForRequest(expectedData, request: realRequest)
        
        let mockRequest = responseHelper.mockRequest(realRequest)
        let returnedData = responseHelper.responseForMockRequest(mockRequest as URLRequest!)
        
        XCTAssert(expectedData == returnedData, "Expected data not received for mock.")
        
    }
    
    func testMockResponseReturnNilIfNoHeadersFile() {
        
        let url = URL(string: "http://mike.kz/Daniele")!
        let realRequest = URLRequest(url: url)
        
        XCTAssertNil(SuperMockResponseHelper.sharedHelper.mockResponse(realRequest), "The response should be nil because does not exist file")
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as? String
        let filePath = (documentsDirectory)! + "/__mike.kz_Daniele"
        
        do {try FileManager.default.removeItem(atPath: filePath)} catch{}
    }
    
    func testMockResponseReturnedMockedHTTPResponse() {
        
        let url = URL(string: "http://mike.kz/")!
        let realRequest = NSMutableURLRequest(url: url)
        
        XCTAssertNotNil(SuperMockResponseHelper.sharedHelper.mockResponse(realRequest as URLRequest), "The response should not be nil because the file exist")
    }
    
    func testRecordResponseHeadersForRequestRecordFile() {
        
        let url = URL(string: "http://mike.kz/RecordedResponseHeaders")!
        let realRequest = URLRequest(url: url)
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: realRequest.allHTTPHeaderFields)
        
        SuperMockResponseHelper.sharedHelper.recordResponseHeadersForRequest(["Connection":"Keep-Alive"], request: realRequest, response: response!)
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as? String
        let filePath = (documentsDirectory)! + "/__mike.kz_RecordedResponseHeaders"
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: filePath), "Headers file need to be created")
        
        do {try FileManager.default.removeItem(atPath: filePath)} catch{}
    }
    
}

// MARK: Test File Helper Class
extension Tests {
    
    func testMockedFilePathReturnFilePathForExistingFile() {
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as? String
        let filePath = (documentsDirectory)! + "/__www.danieleforlani.net_c1d94.txt"
        let string = "Something to save as data"
        
        try! string.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
        
        SuperMock.beginRecording(Bundle(for: AppDelegate.self), policy: .Override)
        
        XCTAssertTrue(FileHelper.mockedResponseFilePath(URL(string: "http://www.danieleforlani.net/c1d94")!) == filePath, "Expected the right path for existing file")
        SuperMock.endRecording()
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: filePath), "Plist file need to be copied if does exist in bundle")
        
        do {try FileManager.default.removeItem(atPath: filePath)} catch{}
    }
    
    func testMockedFilePathReturnFilePathHeaderForExistingFile() {
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as? String
        let filePath = (documentsDirectory)! + "/__www.danieleforlani.net_c1d94"
        let string = "Something to save as data"
        
        try! string.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
        
        
        XCTAssertTrue(FileHelper.mockedResponseHeadersFilePath(URL(string: "http://www.danieleforlani.net/c1d94")!) == filePath, "Expected the right path for existing file")
        
        do {try FileManager.default.removeItem(atPath: filePath)} catch{}
    }
    
    func testMockFileOutOfBundle_NoMockFile_CreateMockFile() {
        
        SuperMockResponseHelper.sharedHelper.mocksFile = "NewMock"
        let _ = FileHelper.mockFileOutOfBundle()
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as! String
        
        let mockPath = "\(documentsDirectory)/\(SuperMockResponseHelper.sharedHelper.mocksFile).plist"
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: mockPath), "Plist file need to be created if does not exist")
        
        do {try FileManager.default.removeItem(atPath: mockPath)} catch{}
    }
    
    func testMockFileOutOfBundle_CopyMockFile() {
        
        SuperMockResponseHelper.sharedHelper.mocksFile = "Mock"
        let _ = FileHelper.mockFileOutOfBundle()
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as! String
        let mockPath = "\(documentsDirectory)/\(SuperMockResponseHelper.sharedHelper.mocksFile).plist"
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: mockPath), "Plist file need to be copied if does exist in bundle")
        
        do {try FileManager.default.removeItem(atPath: mockPath)} catch{}
    }
    
    func testMockFileOutOfBundle_Exist_ReturnCorrectpath() {
        
        SuperMockResponseHelper.sharedHelper.mocksFile = "FakeMock"
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as! String
        let mockPath = "\(documentsDirectory)/\(SuperMockResponseHelper.sharedHelper.mocksFile).plist"
        
        let string = "Fake Mock File"
        
        try? string.write(toFile: mockPath, atomically: true, encoding: String.Encoding.utf8)
        
        let filePath = FileHelper.mockFileOutOfBundle()
        
        XCTAssertTrue(filePath == mockPath, "Plist file need to be copied if does exist in bundle")
        
        do {try FileManager.default.removeItem(atPath: mockPath)} catch{}
    }
    
    
}
