import XCTest
import Foundation
@testable import SecurityTools

final class ProjectAmaanTests: XCTestCase {
    
    // MARK: - Encoding Tools Tests
    
    func testBase64Operations() throws {
        let manager = EncodingToolsManager()
        
        // Test encoding
        let encodeResult = manager.encodeBase64("Hello World")
        XCTAssertTrue(encodeResult.isSuccess, "Base64 encoding should succeed")
        XCTAssertEqual(encodeResult.data?.output, "SGVsbG8gV29ybGQ=", "Base64 output should be correct")
        
        // Test decoding
        let decodeResult = manager.decodeBase64("SGVsbG8gV29ybGQ=")
        XCTAssertTrue(decodeResult.isSuccess, "Base64 decoding should succeed")
        XCTAssertEqual(decodeResult.data?.output, "Hello World", "Base64 decode should be correct")
        
        // Test invalid input
        let invalidResult = manager.decodeBase64("invalid-base64!")
        XCTAssertFalse(invalidResult.isSuccess, "Should reject invalid Base64")
    }
    
    func testURLOperations() throws {
        let manager = EncodingToolsManager()
        
        // Test URL encoding
        let encodeResult = manager.encodeURL("Hello World & More!")
        XCTAssertTrue(encodeResult.isSuccess, "URL encoding should succeed")
        
        // Test URL decoding
        let decodeResult = manager.decodeURL("Hello%20World")
        XCTAssertTrue(decodeResult.isSuccess, "URL decoding should succeed")
        XCTAssertEqual(decodeResult.data?.output, "Hello World", "URL decode should be correct")
    }
    
    func testHTMLOperations() throws {
        let manager = EncodingToolsManager()
        
        // Test HTML encoding
        let encodeResult = manager.encodeHTML("<script>alert('test')</script>")
        XCTAssertTrue(encodeResult.isSuccess, "HTML encoding should succeed")
        XCTAssertTrue(encodeResult.data?.output.contains("&lt;") == true, "Should encode < character")
        
        // Test HTML decoding
        let decodeResult = manager.decodeHTML("&lt;div&gt;Test&lt;/div&gt;")
        XCTAssertTrue(decodeResult.isSuccess, "HTML decoding should succeed")
        XCTAssertEqual(decodeResult.data?.output, "<div>Test</div>", "HTML decode should be correct")
    }
    
    func testHashOperations() throws {
        let manager = EncodingToolsManager()
        
        // Test MD5
        let md5Result = manager.generateMD5("test")
        XCTAssertTrue(md5Result.isSuccess, "MD5 should succeed")
        XCTAssertEqual(md5Result.data?.output, "098f6bcd4621d373cade4e832627b4f6", "MD5 should be correct")
        
        // Test SHA-256
        let sha256Result = manager.generateSHA256("test")
        XCTAssertTrue(sha256Result.isSuccess, "SHA-256 should succeed")
        XCTAssertEqual(sha256Result.data?.output, "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08", "SHA-256 should be correct")
    }
    
    func testHexOperations() throws {
        let manager = EncodingToolsManager()
        
        // Test hex encoding
        let encodeResult = manager.textToHex("Hello")
        XCTAssertTrue(encodeResult.isSuccess, "Hex encoding should succeed")
        XCTAssertEqual(encodeResult.data?.output, "48656c6c6f", "Hex encoding should be correct")
        
        // Test hex decoding
        let decodeResult = manager.hexToText("48656c6c6f")
        XCTAssertTrue(decodeResult.isSuccess, "Hex decoding should succeed")
        XCTAssertEqual(decodeResult.data?.output, "Hello", "Hex decoding should be correct")
        
        // Test invalid hex
        let invalidResult = manager.hexToText("invalid-hex!")
        XCTAssertFalse(invalidResult.isSuccess, "Should reject invalid hex")
    }
    
    // MARK: - Network Tools Tests
    
    func testNetworkManagerInitialization() throws {
        let manager = NetworkToolsManager()
        XCTAssertFalse(manager.isScanning, "Should start not scanning")
        XCTAssertEqual(manager.scanProgress, 0, "Should start with zero progress")
    }
    
    func testPortScanValidation() async throws {
        let manager = NetworkToolsManager()
        
        // Test invalid host
        let invalidHostResult = await manager.scanPorts(host: "", ports: [80])
        XCTAssertFalse(invalidHostResult.isSuccess, "Should reject empty host")
        
        // Test invalid ports
        let invalidPortsResult = await manager.scanPorts(host: "127.0.0.1", ports: [])
        XCTAssertFalse(invalidPortsResult.isSuccess, "Should reject empty ports array")
        
        // Test port range validation
        let outOfRangeResult = await manager.scanPorts(host: "127.0.0.1", ports: [99999])
        XCTAssertFalse(outOfRangeResult.isSuccess, "Should reject out-of-range ports")
    }
    
    // MARK: - Breach Detection Tests
    
    func testBreachManagerInitialization() throws {
        let manager = BreachDetectionManager()
        XCTAssertFalse(manager.isChecking, "Should start not checking")
        XCTAssertNil(manager.lastResult, "Should start with no results")
    }
    
    func testEmailValidation() async throws {
        let manager = BreachDetectionManager()
        
        // Test invalid email
        let invalidResult = await manager.checkEmail("invalid-email")
        XCTAssertFalse(invalidResult.isSuccess, "Should reject invalid email format")
        
        // Test empty email
        let emptyResult = await manager.checkEmail("")
        XCTAssertFalse(emptyResult.isSuccess, "Should reject empty email")
    }
    
    func testDomainValidation() async throws {
        let manager = BreachDetectionManager()
        
        // Test invalid domain
        let invalidResult = await manager.checkDomain("invalid-domain")
        XCTAssertFalse(invalidResult.isSuccess, "Should reject invalid domain format")
        
        // Test empty domain
        let emptyResult = await manager.checkDomain("")
        XCTAssertFalse(emptyResult.isSuccess, "Should reject empty domain")
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorTypes() throws {
        // Test SecurityError types
        let networkError = SecurityError.networkError("Test network error")
        XCTAssertEqual(networkError.errorDescription, "Network Error: Test network error")
        
        let invalidInputError = SecurityError.invalidInput("Test invalid input")
        XCTAssertEqual(invalidInputError.errorDescription, "Invalid Input: Test invalid input")
        
        let apiKeyError = SecurityError.apiKeyMissing("Test API key missing")
        XCTAssertEqual(apiKeyError.errorDescription, "API Key Missing: Test API key missing")
        
        let encodingError = SecurityError.encodingError("Test encoding error")
        XCTAssertEqual(encodingError.errorDescription, "Encoding Error: Test encoding error")
        
        let unknownError = SecurityError.unknownError("Test unknown error")
        XCTAssertEqual(unknownError.errorDescription, "Unknown Error: Test unknown error")
    }
    
    func testSecurityResult() throws {
        // Test success result
        let successResult = SecurityResult(data: "test data")
        XCTAssertTrue(successResult.isSuccess, "Success result should be marked as success")
        XCTAssertEqual(successResult.data, "test data", "Should contain correct data")
        XCTAssertNil(successResult.error, "Success result should have no error")
        
        // Test error result
        let errorResult = SecurityResult<String>(error: .invalidInput("test error"))
        XCTAssertFalse(errorResult.isSuccess, "Error result should not be marked as success")
        XCTAssertNil(errorResult.data, "Error result should have no data")
        XCTAssertNotNil(errorResult.error, "Error result should have error")
    }
    
    // MARK: - Data Model Tests
    
    func testEncodingResult() throws {
        let result = EncodingResult(
            input: "test input",
            output: "test output", 
            operation: .base64Encode
        )
        
        XCTAssertEqual(result.input, "test input", "Input should be stored correctly")
        XCTAssertEqual(result.output, "test output", "Output should be stored correctly")
        XCTAssertEqual(result.operation, .base64Encode, "Operation should be stored correctly")
        XCTAssertNotNil(result.timestamp, "Timestamp should be set")
    }
    
    func testBreachModelDecoding() throws {
        let jsonString = """
        {
            "Name": "TestBreach",
            "Title": "Test Breach",
            "Domain": "test.com",
            "BreachDate": "2023-01-01",
            "AddedDate": "2023-01-02T00:00Z",
            "ModifiedDate": "2023-01-03T00:00Z",
            "PwnCount": 1000,
            "Description": "Test description",
            "LogoPath": "https://example.com/logo.png",
            "DataClasses": ["Email addresses", "Passwords"],
            "IsVerified": true,
            "IsFabricated": false,
            "IsSensitive": false,
            "IsRetired": false,
            "IsSpamList": false
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let breach = try JSONDecoder().decode(Breach.self, from: jsonData)
        
        XCTAssertEqual(breach.name, "TestBreach", "Name should be decoded correctly")
        XCTAssertEqual(breach.title, "Test Breach", "Title should be decoded correctly")
        XCTAssertEqual(breach.domain, "test.com", "Domain should be decoded correctly")
        XCTAssertEqual(breach.pwnCount, 1000, "PwnCount should be decoded correctly")
        XCTAssertEqual(breach.dataClasses.count, 2, "Should have correct number of data classes")
        XCTAssertTrue(breach.isVerified, "IsVerified should be decoded correctly")
        XCTAssertFalse(breach.isFabricated, "IsFabricated should be decoded correctly")
    }
    
    // MARK: - Performance Tests
    
    func testEncodingPerformance() throws {
        let manager = EncodingToolsManager()
        let testString = String(repeating: "Hello World! ", count: 1000)
        
        measure {
            let _ = manager.encodeBase64(testString)
        }
    }
    
    func testHashingPerformance() throws {
        let manager = EncodingToolsManager()
        let testString = String(repeating: "test data ", count: 1000)
        
        measure {
            let _ = manager.generateSHA256(testString)
        }
    }
    
    // MARK: - Edge Cases
    
    func testUnicodeHandling() throws {
        let manager = EncodingToolsManager()
        let unicodeText = "Hello 🌍 World! 中文 العربية русский"
        
        let result = manager.encodeBase64(unicodeText)
        XCTAssertTrue(result.isSuccess, "Should handle Unicode characters")
        
        if let encodedData = result.data {
            let decodeResult = manager.decodeBase64(encodedData.output)
            XCTAssertTrue(decodeResult.isSuccess, "Should decode Unicode correctly")
            XCTAssertEqual(decodeResult.data?.output, unicodeText, "Unicode should round-trip correctly")
        }
    }
    
    func testEmptyInputHandling() throws {
        let manager = EncodingToolsManager()
        
        let emptyBase64 = manager.encodeBase64("")
        XCTAssertFalse(emptyBase64.isSuccess, "Should reject empty input for Base64")
        
        let emptyURL = manager.encodeURL("")
        XCTAssertFalse(emptyURL.isSuccess, "Should reject empty input for URL encoding")
        
        let emptyHTML = manager.encodeHTML("")
        XCTAssertFalse(emptyHTML.isSuccess, "Should reject empty input for HTML encoding")
        
        let emptyMD5 = manager.generateMD5("")
        XCTAssertFalse(emptyMD5.isSuccess, "Should reject empty input for MD5")
        
        let emptySHA256 = manager.generateSHA256("")
        XCTAssertFalse(emptySHA256.isSuccess, "Should reject empty input for SHA-256")
    }
}