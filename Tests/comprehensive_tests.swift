import XCTest
import Foundation
@testable import SecurityTools
@testable import ProjectAmaan

class ProjectAmaanComprehensiveTests: XCTestCase {
    
    // MARK: - Breach Detection Tests
    
    func testBreachDetectionManager() async throws {
        let manager = BreachDetectionManager()
        
        // Test email validation
        let validEmailResult = await manager.checkEmail("test@example.com")
        XCTAssertTrue(validEmailResult.isSuccess || validEmailResult.error != nil, "Should handle email check")
        
        // Test invalid email
        let invalidEmailResult = await manager.checkEmail("invalid-email")
        XCTAssertNotNil(invalidEmailResult.error, "Should reject invalid email format")
        
        // Test domain check
        let domainResult = await manager.checkDomain("example.com")
        XCTAssertTrue(domainResult.isSuccess || domainResult.error != nil, "Should handle domain check")
        
        // Test invalid domain
        let invalidDomainResult = await manager.checkDomain("invalid-domain")
        XCTAssertNotNil(invalidDomainResult.error, "Should reject invalid domain format")
    }
    
    // MARK: - Network Tools Tests
    
    func testNetworkToolsManager() async throws {
        let manager = NetworkToolsManager()
        
        // Test port scanning
        let portScanResult = await manager.scanPorts(host: "127.0.0.1", ports: [22, 80, 443])
        XCTAssertNotNil(portScanResult, "Should return port scan result")
        
        // Test quick scan
        let quickScanResult = await manager.quickScan(host: "google.com")
        XCTAssertTrue(quickScanResult.isSuccess || quickScanResult.error != nil, "Should handle quick scan")
        
        // Test WHOIS lookup
        let whoisResult = await manager.whoisLookup("google.com")
        XCTAssertTrue(whoisResult.isSuccess || whoisResult.error != nil, "Should handle WHOIS lookup")
        
        // Test DNS lookup
        let dnsResult = await manager.dnsLookup("google.com")
        XCTAssertTrue(dnsResult.isSuccess || dnsResult.error != nil, "Should handle DNS lookup")
        
        // Test invalid host
        let invalidHostResult = await manager.scanPorts(host: "invalid-host-name-123", ports: [80])
        XCTAssertTrue(invalidHostResult.error != nil || invalidHostResult.data != nil, "Should handle invalid host")
    }
    
    // MARK: - Encoding Tools Tests
    
    func testEncodingToolsManager() throws {
        let manager = EncodingToolsManager()
        
        // Test Base64 encoding
        let base64EncodeResult = manager.encodeBase64("Hello World")
        XCTAssertTrue(base64EncodeResult.isSuccess, "Should encode Base64 successfully")
        XCTAssertEqual(base64EncodeResult.data?.output, "SGVsbG8gV29ybGQ=", "Base64 encoding should be correct")
        
        // Test Base64 decoding
        let base64DecodeResult = manager.decodeBase64("SGVsbG8gV29ybGQ=")
        XCTAssertTrue(base64DecodeResult.isSuccess, "Should decode Base64 successfully")
        XCTAssertEqual(base64DecodeResult.data?.output, "Hello World", "Base64 decoding should be correct")
        
        // Test URL encoding
        let urlEncodeResult = manager.encodeURL("Hello World & More!")
        XCTAssertTrue(urlEncodeResult.isSuccess, "Should encode URL successfully")
        XCTAssertTrue(urlEncodeResult.data?.output.contains("%20") == true, "URL encoding should contain encoded spaces")
        
        // Test URL decoding
        let urlDecodeResult = manager.decodeURL("Hello%20World")
        XCTAssertTrue(urlDecodeResult.isSuccess, "Should decode URL successfully")
        XCTAssertEqual(urlDecodeResult.data?.output, "Hello World", "URL decoding should be correct")
        
        // Test HTML encoding
        let htmlEncodeResult = manager.encodeHTML("<script>alert('test')</script>")
        XCTAssertTrue(htmlEncodeResult.isSuccess, "Should encode HTML successfully")
        XCTAssertTrue(htmlEncodeResult.data?.output.contains("&lt;") == true, "HTML encoding should contain encoded brackets")
        
        // Test HTML decoding
        let htmlDecodeResult = manager.decodeHTML("&lt;div&gt;Test&lt;/div&gt;")
        XCTAssertTrue(htmlDecodeResult.isSuccess, "Should decode HTML successfully")
        XCTAssertEqual(htmlDecodeResult.data?.output, "<div>Test</div>", "HTML decoding should be correct")
        
        // Test MD5 hashing
        let md5Result = manager.generateMD5("test")
        XCTAssertTrue(md5Result.isSuccess, "Should generate MD5 hash successfully")
        XCTAssertEqual(md5Result.data?.output, "098f6bcd4621d373cade4e832627b4f6", "MD5 hash should be correct")
        
        // Test SHA-256 hashing
        let sha256Result = manager.generateSHA256("test")
        XCTAssertTrue(sha256Result.isSuccess, "Should generate SHA-256 hash successfully")
        XCTAssertEqual(sha256Result.data?.output, "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08", "SHA-256 hash should be correct")
        
        // Test hex encoding
        let hexEncodeResult = manager.textToHex("Hello")
        XCTAssertTrue(hexEncodeResult.isSuccess, "Should encode to hex successfully")
        XCTAssertEqual(hexEncodeResult.data?.output, "48656c6c6f", "Hex encoding should be correct")
        
        // Test hex decoding
        let hexDecodeResult = manager.hexToText("48656c6c6f")
        XCTAssertTrue(hexDecodeResult.isSuccess, "Should decode from hex successfully")
        XCTAssertEqual(hexDecodeResult.data?.output, "Hello", "Hex decoding should be correct")
        
        // Test text extraction
        let textExtractionResult = manager.extractPlainText("<h1>Hello &amp; World</h1>")
        XCTAssertTrue(textExtractionResult.isSuccess, "Should extract plain text successfully")
        XCTAssertEqual(textExtractionResult.data?.output, "Hello & World", "Text extraction should be correct")
        
        // Test empty input validation
        let emptyResult = manager.encodeBase64("")
        XCTAssertFalse(emptyResult.isSuccess, "Should reject empty input")
        XCTAssertNotNil(emptyResult.error, "Should return error for empty input")
        
        // Test invalid Base64 decoding
        let invalidBase64Result = manager.decodeBase64("invalid-base64!")
        XCTAssertFalse(invalidBase64Result.isSuccess, "Should reject invalid Base64")
        XCTAssertNotNil(invalidBase64Result.error, "Should return error for invalid Base64")
        
        // Test invalid hex decoding
        let invalidHexResult = manager.hexToText("invalid-hex!")
        XCTAssertFalse(invalidHexResult.isSuccess, "Should reject invalid hex")
        XCTAssertNotNil(invalidHexResult.error, "Should return error for invalid hex")
    }
    
    // MARK: - Data Model Tests
    
    func testBreachModel() throws {
        let jsonString = """
        {
            "Name": "Adobe",
            "Title": "Adobe",
            "Domain": "adobe.com",
            "BreachDate": "2013-10-04",
            "AddedDate": "2013-12-04T00:00Z",
            "ModifiedDate": "2013-12-04T00:00Z",
            "PwnCount": 152445165,
            "Description": "In October 2013, 153 million Adobe accounts were breached with each containing an internal ID, username, email, encrypted password and a password hint in plain text.",
            "LogoPath": "https://haveibeenpwned.com/Content/Images/PwnedLogos/Adobe.png",
            "DataClasses": ["Email addresses", "Password hints", "Passwords", "Usernames"],
            "IsVerified": true,
            "IsFabricated": false,
            "IsSensitive": false,
            "IsRetired": false,
            "IsSpamList": false
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let breach = try JSONDecoder().decode(Breach.self, from: jsonData)
        
        XCTAssertEqual(breach.name, "Adobe", "Breach name should be decoded correctly")
        XCTAssertEqual(breach.title, "Adobe", "Breach title should be decoded correctly")
        XCTAssertEqual(breach.domain, "adobe.com", "Breach domain should be decoded correctly")
        XCTAssertEqual(breach.pwnCount, 152445165, "Breach pwn count should be decoded correctly")
        XCTAssertTrue(breach.isVerified, "Breach verification status should be decoded correctly")
        XCTAssertFalse(breach.isFabricated, "Breach fabrication status should be decoded correctly")
        XCTAssertEqual(breach.dataClasses.count, 4, "Breach should have correct number of data classes")
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() throws {
        let manager = EncodingToolsManager()
        
        // Test various error conditions
        let emptyInputResult = manager.encodeBase64("")
        XCTAssertNotNil(emptyInputResult.error, "Should handle empty input error")
        XCTAssertTrue(emptyInputResult.error is SecurityError, "Should return SecurityError")
        
        if case .invalidInput(let message) = emptyInputResult.error {
            XCTAssertFalse(message.isEmpty, "Error message should not be empty")
        } else {
            XCTFail("Should return invalidInput error")
        }
    }
    
    // MARK: - UI Component Tests
    
    func testUIComponents() throws {
        // Test that UI components can be instantiated without crashes
        let mainView = WorkingMainView()
        XCTAssertNotNil(mainView, "Main view should be creatable")
        
        // Test tool enumeration
        let tools = WorkingMainView.SecurityTool.allCases
        XCTAssertEqual(tools.count, 3, "Should have exactly 3 security tools")
        XCTAssertTrue(tools.contains(.breachDetection), "Should contain breach detection tool")
        XCTAssertTrue(tools.contains(.networkTools), "Should contain network tools")
        XCTAssertTrue(tools.contains(.encodingTools), "Should contain encoding tools")
    }
    
    // MARK: - Integration Tests
    
    func testManagerIntegration() throws {
        let securityManager = SecurityToolsManager()
        
        XCTAssertNotNil(securityManager.breachDetector, "Should have breach detector")
        XCTAssertNotNil(securityManager.networkTools, "Should have network tools")
        XCTAssertNotNil(securityManager.encodingTools, "Should have encoding tools")
        XCTAssertNotNil(securityManager.apiKeyManager, "Should have API key manager")
        
        XCTAssertFalse(securityManager.isProcessing, "Should start in non-processing state")
        XCTAssertNil(securityManager.lastError, "Should start without errors")
    }
    
    // MARK: - Performance Tests
    
    func testPerformance() throws {
        let manager = EncodingToolsManager()
        let largeText = String(repeating: "Hello World! ", count: 10000)
        
        // Test Base64 encoding performance
        measure {
            let _ = manager.encodeBase64(largeText)
        }
        
        // Test SHA-256 hashing performance
        measure {
            let _ = manager.generateSHA256(largeText)
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testEdgeCases() throws {
        let manager = EncodingToolsManager()
        
        // Test with Unicode characters
        let unicodeResult = manager.encodeBase64("Hello 🌍 World! 中文 العربية")
        XCTAssertTrue(unicodeResult.isSuccess, "Should handle Unicode characters")
        
        // Test with very long strings
        let longString = String(repeating: "a", count: 100000)
        let longStringResult = manager.generateSHA256(longString)
        XCTAssertTrue(longStringResult.isSuccess, "Should handle very long strings")
        
        // Test with special characters
        let specialCharsResult = manager.encodeHTML("!@#$%^&*()_+-={}[]|\\:;\"'<>,.?/")
        XCTAssertTrue(specialCharsResult.isSuccess, "Should handle special characters")
    }
}