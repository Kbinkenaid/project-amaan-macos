import Foundation
import Crypto

/// Manager for encoding/decoding utilities
public class EncodingToolsManager: ObservableObject {
    
    public init() {
    }
    @Published public var lastResult: EncodingResult?
    
    // MARK: - Base64 Operations
    
    /// Encode text to Base64
    public func encodeBase64(_ text: String) -> SecurityResult<EncodingResult> {
        guard !text.isEmpty else {
            return SecurityResult(error: .invalidInput("Input text cannot be empty"))
        }
        
        guard let data = text.data(using: .utf8) else {
            return SecurityResult(error: .encodingError("Failed to convert text to data"))
        }
        
        let encoded = data.base64EncodedString()
        let result = EncodingResult(
            input: text,
            output: encoded,
            operation: .base64Encode
        )
        
        DispatchQueue.main.async {
            self.lastResult = result
        }
        
        return SecurityResult(data: result)
    }
    
    /// Decode Base64 to text
    public func decodeBase64(_ encodedText: String) -> SecurityResult<EncodingResult> {
        guard !encodedText.isEmpty else {
            return SecurityResult(error: .invalidInput("Input text cannot be empty"))
        }
        
        guard let data = Data(base64Encoded: encodedText) else {
            return SecurityResult(error: .encodingError("Invalid Base64 format"))
        }
        
        guard let decoded = String(data: data, encoding: .utf8) else {
            return SecurityResult(error: .encodingError("Failed to decode Base64 data"))
        }
        
        let result = EncodingResult(
            input: encodedText,
            output: decoded,
            operation: .base64Decode
        )
        
        DispatchQueue.main.async {
            self.lastResult = result
        }
        
        return SecurityResult(data: result)
    }
    
    // MARK: - URL Encoding Operations
    
    /// URL encode text
    public func encodeURL(_ text: String) -> SecurityResult<EncodingResult> {
        guard !text.isEmpty else {
            return SecurityResult(error: .invalidInput("Input text cannot be empty"))
        }
        
        guard let encoded = text.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            return SecurityResult(error: .encodingError("Failed to URL encode text"))
        }
        
        let result = EncodingResult(
            input: text,
            output: encoded,
            operation: .urlEncode
        )
        
        DispatchQueue.main.async {
            self.lastResult = result
        }
        
        return SecurityResult(data: result)
    }
    
    /// URL decode text
    public func decodeURL(_ encodedText: String) -> SecurityResult<EncodingResult> {
        guard !encodedText.isEmpty else {
            return SecurityResult(error: .invalidInput("Input text cannot be empty"))
        }
        
        guard let decoded = encodedText.removingPercentEncoding else {
            return SecurityResult(error: .encodingError("Failed to URL decode text"))
        }
        
        let result = EncodingResult(
            input: encodedText,
            output: decoded,
            operation: .urlDecode
        )
        
        DispatchQueue.main.async {
            self.lastResult = result
        }
        
        return SecurityResult(data: result)
    }
    
    // MARK: - HTML Entity Operations
    
    /// Encode HTML entities
    public func encodeHTML(_ text: String) -> SecurityResult<EncodingResult> {
        guard !text.isEmpty else {
            return SecurityResult(error: .invalidInput("Input text cannot be empty"))
        }
        
        let encoded = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
        
        let result = EncodingResult(
            input: text,
            output: encoded,
            operation: .htmlEncode
        )
        
        DispatchQueue.main.async {
            self.lastResult = result
        }
        
        return SecurityResult(data: result)
    }
    
    /// Decode HTML entities
    public func decodeHTML(_ encodedText: String) -> SecurityResult<EncodingResult> {
        guard !encodedText.isEmpty else {
            return SecurityResult(error: .invalidInput("Input text cannot be empty"))
        }
        
        let decoded = encodedText
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
        
        let result = EncodingResult(
            input: encodedText,
            output: decoded,
            operation: .htmlDecode
        )
        
        DispatchQueue.main.async {
            self.lastResult = result
        }
        
        return SecurityResult(data: result)
    }
    
    // MARK: - Hash Operations
    
    /// Generate MD5 hash
    public func generateMD5(_ text: String) -> SecurityResult<EncodingResult> {
        guard !text.isEmpty else {
            return SecurityResult(error: .invalidInput("Input text cannot be empty"))
        }
        
        guard let data = text.data(using: .utf8) else {
            return SecurityResult(error: .encodingError("Failed to convert text to data"))
        }
        
        let hash = Insecure.MD5.hash(data: data)
        let hashString = hash.map { String(format: "%02x", $0) }.joined()
        
        let result = EncodingResult(
            input: text,
            output: hashString,
            operation: .md5Hash
        )
        
        DispatchQueue.main.async {
            self.lastResult = result
        }
        
        return SecurityResult(data: result)
    }
    
    /// Generate SHA-256 hash
    public func generateSHA256(_ text: String) -> SecurityResult<EncodingResult> {
        guard !text.isEmpty else {
            return SecurityResult(error: .invalidInput("Input text cannot be empty"))
        }
        
        guard let data = text.data(using: .utf8) else {
            return SecurityResult(error: .encodingError("Failed to convert text to data"))
        }
        
        let hash = SHA256.hash(data: data)
        let hashString = hash.map { String(format: "%02x", $0) }.joined()
        
        let result = EncodingResult(
            input: text,
            output: hashString,
            operation: .sha256Hash
        )
        
        DispatchQueue.main.async {
            self.lastResult = result
        }
        
        return SecurityResult(data: result)
    }
    
    // MARK: - Text Extraction
    
    /// Extract plain text from various formats
    public func extractPlainText(_ text: String) -> SecurityResult<EncodingResult> {
        guard !text.isEmpty else {
            return SecurityResult(error: .invalidInput("Input text cannot be empty"))
        }
        
        var extracted = text
        
        // Remove HTML tags
        extracted = extracted.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
        
        // Decode common HTML entities
        extracted = decodeHTML(extracted).data?.output ?? extracted
        
        // Clean up whitespace
        extracted = extracted.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        
        let result = EncodingResult(
            input: text,
            output: extracted,
            operation: .textExtraction
        )
        
        DispatchQueue.main.async {
            self.lastResult = result
        }
        
        return SecurityResult(data: result)
    }
    
    // MARK: - Binary Operations
    
    /// Convert text to hexadecimal
    public func textToHex(_ text: String) -> SecurityResult<EncodingResult> {
        guard !text.isEmpty else {
            return SecurityResult(error: .invalidInput("Input text cannot be empty"))
        }
        
        guard let data = text.data(using: .utf8) else {
            return SecurityResult(error: .encodingError("Failed to convert text to data"))
        }
        
        let hex = data.map { String(format: "%02x", $0) }.joined()
        
        let result = EncodingResult(
            input: text,
            output: hex,
            operation: .textToHex
        )
        
        DispatchQueue.main.async {
            self.lastResult = result
        }
        
        return SecurityResult(data: result)
    }
    
    /// Convert hexadecimal to text
    public func hexToText(_ hex: String) -> SecurityResult<EncodingResult> {
        guard !hex.isEmpty else {
            return SecurityResult(error: .invalidInput("Input hex cannot be empty"))
        }
        
        let cleanHex = hex.replacingOccurrences(of: " ", with: "")
        
        guard cleanHex.count % 2 == 0 else {
            return SecurityResult(error: .invalidInput("Hex string must have even number of characters"))
        }
        
        var data = Data()
        var index = cleanHex.startIndex
        
        while index < cleanHex.endIndex {
            let nextIndex = cleanHex.index(index, offsetBy: 2)
            let byteString = String(cleanHex[index..<nextIndex])
            
            guard let byte = UInt8(byteString, radix: 16) else {
                return SecurityResult(error: .encodingError("Invalid hexadecimal format"))
            }
            
            data.append(byte)
            index = nextIndex
        }
        
        guard let text = String(data: data, encoding: .utf8) else {
            return SecurityResult(error: .encodingError("Failed to convert hex data to text"))
        }
        
        let result = EncodingResult(
            input: hex,
            output: text,
            operation: .hexToText
        )
        
        DispatchQueue.main.async {
            self.lastResult = result
        }
        
        return SecurityResult(data: result)
    }
}

// MARK: - Data Models

public struct EncodingResult {
    public let input: String
    public let output: String
    public let operation: EncodingOperation
    public let timestamp: Date
    
    public init(input: String, output: String, operation: EncodingOperation) {
        self.input = input
        self.output = output
        self.operation = operation
        self.timestamp = Date()
    }
}

public enum EncodingOperation: String, CaseIterable {
    case base64Encode = "Base64 Encode"
    case base64Decode = "Base64 Decode"
    case urlEncode = "URL Encode"
    case urlDecode = "URL Decode"
    case htmlEncode = "HTML Encode"
    case htmlDecode = "HTML Decode"
    case md5Hash = "MD5 Hash"
    case sha256Hash = "SHA-256 Hash"
    case textExtraction = "Text Extraction"
    case textToHex = "Text to Hex"
    case hexToText = "Hex to Text"
    
    public var description: String {
        return self.rawValue
    }
}