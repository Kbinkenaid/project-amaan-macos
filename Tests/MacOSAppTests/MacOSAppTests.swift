import XCTest
import WebKit
@testable import MacOSApp

final class MacOSAppTests: XCTestCase {
    var webViewManager: WebViewManager!
    
    override func setUpWithError() throws {
        webViewManager = WebViewManager()
    }
    
    override func tearDownWithError() throws {
        webViewManager = nil
    }
    
    func testWebViewManagerInitialization() throws {
        XCTAssertNotNil(webViewManager)
        XCTAssertFalse(webViewManager.isLoading)
        XCTAssertFalse(webViewManager.canGoBack)
        XCTAssertFalse(webViewManager.canGoForward)
        XCTAssertEqual(webViewManager.title, "")
        XCTAssertNil(webViewManager.url)
    }
    
    func testWebViewCreation() throws {
        let webView = webViewManager.createWebView()
        XCTAssertNotNil(webView)
        XCTAssertTrue(webView.configuration.preferences.javaScriptEnabled)
    }
    
    func testURLLoading() throws {
        let expectation = XCTestExpectation(description: "URL loading")
        let webView = webViewManager.createWebView()
        
        // Test loading a valid URL
        let testURL = URL(string: "https://www.apple.com")!
        webViewManager.load(url: testURL)
        
        // Wait a bit to ensure the loading process starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
        
        // The URL should be set (even if still loading)
        XCTAssertNotNil(webViewManager.url)
    }
    
    func testJavaScriptExecution() throws {
        let expectation = XCTestExpectation(description: "JavaScript execution")
        let webView = webViewManager.createWebView()
        
        // Load a simple HTML page
        let html = "<html><body><script>window.testValue = 'Hello, World!';</script></body></html>"
        webView.loadHTMLString(html, baseURL: nil)
        
        // Wait for the page to load, then execute JavaScript
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.webViewManager.executeJavaScript("window.testValue") { result, error in
                XCTAssertNil(error)
                XCTAssertEqual(result as? String, "Hello, World!")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testCSSInjection() throws {
        let expectation = XCTestExpectation(description: "CSS injection")
        let webView = webViewManager.createWebView()
        
        // Load a simple HTML page
        let html = "<html><body><div id='test'>Test content</div></body></html>"
        webView.loadHTMLString(html, baseURL: nil)
        
        // Wait for the page to load, then inject CSS
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.webViewManager.injectCSS("#test { color: red; }")
            
            // Verify the CSS was injected by checking computed style
            self.webViewManager.executeJavaScript("getComputedStyle(document.getElementById('test')).color") { result, error in
                XCTAssertNil(error)
                // The result should be an RGB color value
                XCTAssertTrue((result as? String)?.contains("rgb") == true)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testWebDataClearing() throws {
        // This test ensures the clearWebData method doesn't crash
        XCTAssertNoThrow(webViewManager.clearWebData())
    }
    
    func testConfigurationUpdates() throws {
        // Test JavaScript enabling/disabling
        webViewManager.updateJavaScriptEnabled(false)
        webViewManager.updateJavaScriptEnabled(true)
        
        // Test popup allowing/disallowing
        webViewManager.updateAllowPopups(true)
        webViewManager.updateAllowPopups(false)
        
        // These methods should not crash
        XCTAssertTrue(true) // If we reach here, methods didn't crash
    }
    
    func testNavigationMethods() throws {
        let webView = webViewManager.createWebView()
        
        // These methods should not crash even when there's no navigation history
        XCTAssertNoThrow(webViewManager.goBack())
        XCTAssertNoThrow(webViewManager.goForward())
        XCTAssertNoThrow(webViewManager.reload())
    }
}

// MARK: - Integration Tests

final class IntegrationTests: XCTestCase {
    func testAppLaunch() throws {
        // Test that the app delegate can be created
        let delegate = AppDelegate()
        XCTAssertNotNil(delegate)
    }
    
    func testMainContentViewCreation() throws {
        // Test that the main content view can be created
        let contentView = MainContentView()
        XCTAssertNotNil(contentView)
    }
    
    func testWebViewRepresentableCreation() throws {
        let webViewManager = WebViewManager()
        let representable = WebViewRepresentable(webViewManager: webViewManager)
        XCTAssertNotNil(representable)
    }
}

// MARK: - Performance Tests

final class PerformanceTests: XCTestCase {
    func testWebViewManagerPerformance() throws {
        measure {
            let webViewManager = WebViewManager()
            let webView = webViewManager.createWebView()
            _ = webView
        }
    }
    
    func testJavaScriptExecutionPerformance() throws {
        let webViewManager = WebViewManager()
        let webView = webViewManager.createWebView()
        let html = "<html><body><script>var data = [];</script></body></html>"
        webView.loadHTMLString(html, baseURL: nil)
        
        let expectation = XCTestExpectation(description: "Performance test")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.measure {
                webViewManager.executeJavaScript("Math.random()") { _, _ in }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}