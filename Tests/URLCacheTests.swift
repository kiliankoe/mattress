//
//  URLCacheTests.swift
//  Mattress
//
//  Created by David Mauro on 11/13/14.
//  Copyright (c) 2014 BuzzFeed. All rights reserved.
//

import XCTest

private let url = NSURL(string: "foo://bar")!
private let TestDirectory = "test"

class MockCacher: WebViewCacher {
    override func mattressCacheURL(url: NSURL,
        loadedHandler: WebViewLoadedHandler,
        completionHandler: WebViewCacherCompletionHandler,
        failureHandler: (NSError) -> ()) {}
}

class URLCacheTests: XCTestCase {

    func testRequestShouldBeStoredInMattress() {
        let mutableRequest = NSMutableURLRequest(URL: url)
        NSURLProtocol.setProperty(true, forKey: MattressCacheRequestPropertyKey, inRequest: mutableRequest)
        XCTAssert(URLCache.requestShouldBeStoredInMattress(mutableRequest), "")
    }

    func testValidMattressResponseGoesToMattressDiskCache() {
        let mutableRequest = NSMutableURLRequest(URL: url)
        NSURLProtocol.setProperty(true, forKey: MattressCacheRequestPropertyKey, inRequest: mutableRequest)

        var didCallMock = false
        let cache = makeMockURLCache()
        cache.mockDiskCache.storeCacheCalledHandler = {
            didCallMock = true
        }
        let response = makeValidCachedResponseForRequest(mutableRequest)
        cache.storeCachedResponse(response, forRequest: mutableRequest)
        XCTAssertTrue(didCallMock, "Disk cache storage method was not called")
    }

    func testInvalidMattressResponseDoesNotGoToMattressDiskCache() {
        let mutableRequest = NSMutableURLRequest(URL: url)
        NSURLProtocol.setProperty(true, forKey: MattressCacheRequestPropertyKey, inRequest: mutableRequest)

        var didCallMock = false
        let cache = makeMockURLCache()
        cache.mockDiskCache.storeCacheCalledHandler = {
            didCallMock = true
        }
        let response = NSCachedURLResponse()
        cache.storeCachedResponse(response, forRequest: mutableRequest)
        XCTAssertFalse(didCallMock, "Disk cache storage method was not called")
    }

    func testStandardRequestDoesNotGoToMattressDiskCache() {
        // Ensure plist on disk is reset
        let diskCache = DiskCache(path: TestDirectory, searchPathDirectory: .DocumentDirectory, maxCacheSize: 0)
        if let path = diskCache.diskPathForPropertyList()?.path {
            try! NSFileManager.defaultManager().removeItemAtPath(path)
        }

        let mutableRequest = NSMutableURLRequest(URL: url)

        var didCallMock = false
        let cache = makeMockURLCache()
        cache.mockDiskCache.storeCacheCalledHandler = {
            didCallMock = true
        }
        let response = NSCachedURLResponse()
        cache.storeCachedResponse(response, forRequest: mutableRequest)
        XCTAssertFalse(didCallMock, "Disk cache storage method was called")
    }

    func testCachedResponseIsRetriedFromMattressDiskCache() {
        let request = NSMutableURLRequest(URL: url)
        let cachedResponse = NSCachedURLResponse()

        let cache = makeMockURLCache()
        cache.mockDiskCache.retrieveCacheCalledHandler = { request in
            return cachedResponse
        }
        let response = cache.cachedResponseForRequest(request)
        if let response = response {
            XCTAssert(response == cachedResponse, "Response did not match")
        } else {
            XCTFail("No response returned from cache")
        }
    }

    func testMattressRequestGeneratesWebViewCacher() {
        let cache = makeURLCache()
        XCTAssert(cache.cachers.count == 0, "Cache should not start with any cachers")
        cache.diskCacheURL(url, loadedHandler: { webView in
            return true
        })
        XCTAssert(cache.cachers.count == 1, "Should have created a single WebViewCacher")
    }

    func testGettingWebViewCacherResponsibleForARequest() {
        let request = NSURLRequest(URL: url)
        let cacher1 = SourceCache()
        let cacher2 = WebViewCacher()

        let cache = makeURLCache()
        cache.cachers.append(cacher1)
        cache.cachers.append(cacher2)
        if let source = cache.webViewCacherOriginatingRequest(request) {
            XCTAssert(source == cacher1, "Returned the incorrect cacher")
        } else {
            XCTFail("No source cacher found")
        }
    }

    func testCachingARequestToTheStandardCacheAlsoUpdatesTheRequestInTheMattressCacheIfItWasAlreadyStoredOnDisk() {
        // Ensure plist on disk is reset
        let diskCache = DiskCache(path: TestDirectory, searchPathDirectory: .DocumentDirectory, maxCacheSize: 0)
        if let path = diskCache.diskPathForPropertyList()?.path {
            try! NSFileManager.defaultManager().removeItemAtPath(path)
        }

        let cache = MockURLCacheWithMockDiskCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil,
            mattressDiskCapacity: 1024 * 1024, mattressDiskPath: nil, mattressSearchPathDirectory: .DocumentDirectory, isOfflineHandler: {
                return false
        })

        // Make sure the request has been stored once
        let url = NSURL(string: "foo://bar")!
        let request = NSURLRequest(URL: url)
        let cachedResponse = makeValidCachedResponseForRequest(request)
        cache.mockDiskCache.storeCachedResponseOnSuper(cachedResponse, forRequest: request)

        var didCall = false
        cache.mockDiskCache.storeCacheCalledHandler = {
            didCall = true
        }

        cache.storeCachedResponse(cachedResponse, forRequest: request)
        XCTAssert(didCall, "The Mattress disk cache storage method was not called")
    }

    // Mark: - Helpers

    func makeValidCachedResponseForRequest(request: NSURLRequest) -> NSCachedURLResponse {
        let url = request.URL ?? NSURL(string: "")!
        let data = "hello, world".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        let response = NSHTTPURLResponse(URL: url, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: nil)!
        _ = NSURLRequest(URL: url)
        return NSCachedURLResponse(response: response, data: data, userInfo: nil, storagePolicy: .Allowed)
    }

    func makeURLCache() -> URLCache {
        return URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil, mattressDiskCapacity: 0,
            mattressDiskPath: nil, mattressSearchPathDirectory: .DocumentDirectory, isOfflineHandler: nil)
    }

    func makeMockURLCache() -> MockURLCacheWithMockDiskCache {
        return MockURLCacheWithMockDiskCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil, mattressDiskCapacity: 0,
            mattressDiskPath: nil, mattressSearchPathDirectory: .DocumentDirectory, isOfflineHandler: nil)
    }
}

// Mark: - An ode to Xcode being the worst -OR- locally scoped subclasses are supposed to work but don't

class SourceCache: WebViewCacher {
    override func didOriginateRequest(request: NSURLRequest) -> Bool {
        return true
    }
}

class MockDiskCache: DiskCache {
    var storeCacheCalledHandler: (() -> ())?
    var retrieveCacheCalledHandler: ((request: NSURLRequest) -> (NSCachedURLResponse?))?

    func storeCachedResponseOnSuper(cachedResponse: NSCachedURLResponse, forRequest request: NSURLRequest) -> Bool {
        return super.storeCachedResponse(cachedResponse, forRequest: request)
    }

    override func storeCachedResponse(cachedResponse: NSCachedURLResponse, forRequest request: NSURLRequest) -> Bool {
        storeCacheCalledHandler?()
        return true
    }

    override func cachedResponseForRequest(request: NSURLRequest) -> NSCachedURLResponse? {
        if let handler = retrieveCacheCalledHandler {
            return handler(request: request)
        }
        return nil
    }
}
class MockURLCacheWithMockDiskCache: URLCache {
    var mockDiskCache: MockDiskCache {
        return diskCache as! MockDiskCache
    }

    override init(memoryCapacity: Int, diskCapacity: Int, diskPath path: String?, mattressDiskCapacity: Int,
        mattressDiskPath mattressPath: String?, mattressSearchPathDirectory searchPathDirectory: NSSearchPathDirectory, isOfflineHandler: (() -> Bool)?)
    {
        super.init(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: path, mattressDiskCapacity: mattressDiskCapacity,
            mattressDiskPath: mattressPath, mattressSearchPathDirectory: searchPathDirectory, isOfflineHandler: isOfflineHandler)

        diskCache = MockDiskCache(path: TestDirectory, searchPathDirectory: .DocumentDirectory, maxCacheSize: 1024)
    }
}

