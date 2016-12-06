//
//  SuperMockURLProtocol.swift
//  SuperMock
//
//  Created by Michael Armstrong on 02/11/2015.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import UIKit

class SuperMockURLProtocol: URLProtocol {
    
    override class func canInit(with request: URLRequest) -> Bool {
        
        if request.hasMock() {
            print("Requesting MOCK for : \(request.url)")
            return true
        }
        print("Passing Through WITHOUT MOCK : \(request.url)")
        return false
    }
    
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        
        let mockedRequest = SuperMockResponseHelper.sharedHelper.mockRequest(request)
        if let mockData = SuperMockResponseHelper.sharedHelper.responseForMockRequest(mockedRequest as URLRequest!) {
   
            //TODO: Fix up the below for use in UIWebView's.
            //      let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 302, HTTPVersion: "HTTP/1.1", headerFields: ["Location":request.URL!.absoluteString])!
            //  client?.URLProtocol(self, wasRedirectedToRequest: request, redirectResponse: response)

            let mimeType = SuperMockResponseHelper.sharedHelper.mimeType(mockedRequest.url!)
            var response = URLResponse(url: mockedRequest.url!, mimeType: mimeType, expectedContentLength: mockData.count, textEncodingName: "utf8")
            if let mockResponse = SuperMockResponseHelper.sharedHelper.mockResponse(request) {
                response = mockResponse
            }
            
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: mockData)
            client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    override func stopLoading() {
    }
}

class SuperMockRecordingURLProtocol: URLProtocol {
    
    var connection : NSURLConnection?
    var mutableData : Data?
    
    override class func canInit(with request: URLRequest) -> Bool {
        
        if let _ = URLProtocol.property(forKey: "SuperMockRecordingURLProtocol", in: request) {
            return false
        }
        if SuperMockResponseHelper.sharedHelper.recording  {
            return true
        }
        return false
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool {
        return super.requestIsCacheEquivalent(a, to:b)
    }
    
    override func startLoading() {
        
        if let copyRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest {
            
            URLProtocol.setProperty(request.url!, forKey: "SuperMockRecordingURLProtocol", in: copyRequest)
            connection = NSURLConnection(request: copyRequest as URLRequest, delegate: self)
            
            mutableData = Data()
        }
    }
    
    override func stopLoading() {
        connection?.cancel()
    }
}

extension SuperMockRecordingURLProtocol: NSURLConnectionDataDelegate {
    
    func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
        if let httpResponse = response as? HTTPURLResponse {
            let headers = httpResponse.allHeaderFields
            SuperMockResponseHelper.sharedHelper.recordResponseHeadersForRequest(headers, request: request, response: httpResponse)
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: URLCache.StoragePolicy.notAllowed)
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
        mutableData?.append(data)
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        client?.urlProtocolDidFinishLoading(self)
        SuperMockResponseHelper.sharedHelper.recordDataForRequest(mutableData, request: request)
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        client?.urlProtocol(self, didFailWithError: error)
    }
}
