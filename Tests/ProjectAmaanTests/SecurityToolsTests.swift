import XCTest
@testable import SecurityTools

final class SecurityToolsTests: XCTestCase {
    
    // MARK: - Encoding Tools Tests
    
    func testBase64Encoding() {
        let manager = EncodingToolsManager()
        let testString = "Hello, Project Amaan!"
        
        let result = manager.encodeBase64(testString)
        
        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(result.data)
        XCTAssertEqual(result.data?.input, testString)
        XCTAssertEqual(result.data?.operation, .base64Encode)
        
        // Verify the encoding is correct
        let expectedEncoded = Data(testString.utf8).base64EncodedString()
        XCTAssertEqual(result.data?.output, expectedEncoded)
    }
    
    func testBase64Decoding() {
        let manager = EncodingToolsManager()
        let encodedString = "SGVsbG8sIFByb2plY3QgQW1hYW4h" // "Hello, Project Amaan!" in Base64
        
        let result = manager.decodeBase64(encodedString)
        
        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(result.data)
        XCTAssertEqual(result.data?.input, encodedString)
        XCTAssertEqual(result.data?.operation, .base64Decode)
        XCTAssertEqual(result.data?.output, "Hello, Project Amaan!")
    }
    
    func testInvalidBase64Decoding() {
        let manager = EncodingToolsManager()
        let invalidBase64 = "InvalidBase64!!!"
        
        let result = manager.decodeBase64(invalidBase64)
        
        XCTAssertFalse(result.isSuccess)
        XCTAssertNotNil(result.error)
        XCTAssertNil(result.data)
    }
    
    func testURLEncoding() {
        let manager = EncodingToolsManager()
        let testString = "Hello World & Special Characters!"
        
        let result = manager.encodeURL(testString)
        
        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(result.data)
        XCTAssertEqual(result.data?.operation, .urlEncode)
        XCTAssertTrue(result.data?.output.contains("Hello") == true)
    }
    
    func testHTMLEncoding() {
        let manager = EncodingToolsManager()
        let testString = "<script>alert('test');</script>"
        
        let result = manager.encodeHTML(testString)
        
        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(result.data)
        XCTAssertEqual(result.data?.operation, .htmlEncode)
        XCTAssertTrue(result.data?.output.contains("&lt;") == true)
        XCTAssertTrue(result.data?.output.contains("&gt;") == true)
    }
    
    func testMD5Hash() {
        let manager = EncodingToolsManager()
        let testString = "test"
        
        let result = manager.generateMD5(testString)
        
        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(result.data)
        XCTAssertEqual(result.data?.operation, .md5Hash)
        // MD5 of "test" should be "098f6bcd4621d373cade4e832627b4f6"
        XCTAssertEqual(result.data?.output, "098f6bcd4621d373cade4e832627b4f6")
    }
    
    func testSHA256Hash() {
        let manager = EncodingToolsManager()
        let testString = "test"
        
        let result = manager.generateSHA256(testString)
        
        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(result.data)
        XCTAssertEqual(result.data?.operation, .sha256Hash)
        // SHA-256 of "test" should be "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"
        XCTAssertEqual(result.data?.output, "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08")
    }
    
    // MARK: - API Key Manager Tests
    
    func testAPIKeyValidation() {
        let manager = APIKeyManager()
        
        // Test valid HaveIBeenPwned API key format (32+ characters)
        let validHIBPKey = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"
        let result = manager.validateAPIKey(validHIBPKey, for: .haveIBeenPwned)
        
        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(result.data)
        XCTAssertEqual(result.data, true)
    }
    
    func testInvalidAPIKeyValidation() {
        let manager = APIKeyManager()
        
        // Test invalid API key (too short)
        let invalidKey = "short"
        let result = manager.validateAPIKey(invalidKey, for: .haveIBeenPwned)
        
        XCTAssertFalse(result.isSuccess)
        XCTAssertNotNil(result.error)
        XCTAssertNil(result.data)
    }
    
    func testEmptyAPIKeyValidation() {
        let manager = APIKeyManager()
        
        let result = manager.validateAPIKey("", for: .haveIBeenPwned)
        
        XCTAssertFalse(result.isSuccess)
        XCTAssertNotNil(result.error)
        XCTAssertNil(result.data)
    }
    
    // MARK: - Network Tools Tests
    
    func testPortRangeGeneration() {
        // This would require mocking network connections for proper testing
        // For now, just test the manager creation
        let manager = NetworkToolsManager()
        XCTAssertNotNil(manager)
        XCTAssertFalse(manager.isScanning)
        XCTAssertEqual(manager.scanProgress, 0)
    }
    
    // MARK: - Security Tools Manager Tests
    
    func testSecurityToolsManagerInitialization() {
        let manager = SecurityToolsManager()
        
        XCTAssertNotNil(manager.breachDetector)
        XCTAssertNotNil(manager.networkTools)
        XCTAssertNotNil(manager.encodingTools)
        XCTAssertNotNil(manager.apiKeyManager)
        XCTAssertFalse(manager.isProcessing)
        XCTAssertNil(manager.lastError)
    }
    
    // MARK: - Helper Methods Tests
    
    func testHexConversion() {
        let manager = EncodingToolsManager()
        let testString = "Hello"
        
        // Test text to hex
        let hexResult = manager.textToHex(testString)
        XCTAssertTrue(hexResult.isSuccess)
        XCTAssertNotNil(hexResult.data)
        
        // Test hex back to text
        if let hexString = hexResult.data?.output {
            let textResult = manager.hexToText(hexString)
            XCTAssertTrue(textResult.isSuccess)
            XCTAssertEqual(textResult.data?.output, testString)
        } else {
            XCTFail("Hex conversion failed")
        }
    }
    
    func testTextExtraction() {
        let manager = EncodingToolsManager()
        let htmlString = "<p>Hello <strong>World</strong>!</p>"
        
        let result = manager.extractPlainText(htmlString)
        
        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(result.data)
        XCTAssertEqual(result.data?.operation, .textExtraction)
        XCTAssertTrue(result.data?.output.contains("Hello World") == true)
        XCTAssertFalse(result.data?.output.contains("<p>") == true)
    }
    
    // MARK: - Performance Tests
    
    func testEncodingPerformance() {
        let manager = EncodingToolsManager()
        let largeString = String(repeating: "Hello, Project Amaan! ", count: 1000)
        
        measure {
            let _ = manager.encodeBase64(largeString)
        }
    }
    
    func testHashingPerformance() {
        let manager = EncodingToolsManager()
        let largeString = String(repeating: "Performance Test Data ", count: 1000)
        
        measure {
            let _ = manager.generateSHA256(largeString)
        }
    }
}

// MARK: - Mock Data for Testing

extension SecurityToolsTests {
    
    static var mockBreachData: [String: Any] {
        return [
            "Name": "TestBreach",
            "Title": "Test Data Breach",
            "Domain": "test.com",
            "BreachDate": "2023-01-01",
            "AddedDate": "2023-01-02T00:00:00Z",
            "ModifiedDate": "2023-01-02T00:00:00Z",
            "PwnCount": 1000,
            "Description": "A test breach for unit testing",
            "LogoPath": "test-logo.png",
            "DataClasses": ["Email addresses", "Passwords"],
            "IsVerified": true,
            "IsFabricated": false,
            "IsSensitive": false,
            "IsRetired": false,
            "IsSpamList": false
        ]
    }
}

// MARK: - Test Extensions

extension SecurityError: Equatable {
    public static func == (lhs: SecurityError, rhs: SecurityError) -> Bool {
        switch (lhs, rhs) {
        case (.networkError(let lhsMessage), .networkError(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.invalidInput(let lhsMessage), .invalidInput(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.apiKeyMissing(let lhsMessage), .apiKeyMissing(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.encodingError(let lhsMessage), .encodingError(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.unknownError(let lhsMessage), .unknownError(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}