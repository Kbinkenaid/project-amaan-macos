import Foundation
import Crypto
import NIO

/// Main manager for all security tools functionality
public class SecurityToolsManager: ObservableObject {
    @Published public var isProcessing = false
    @Published public var lastError: SecurityError?
    
    // Tool managers
    public let breachDetector: BreachDetectionManager
    public let networkTools: NetworkToolsManager
    public let encodingTools: EncodingToolsManager
    public let apiKeyManager: APIKeyManager
    
    public init() {
        self.breachDetector = BreachDetectionManager()
        self.networkTools = NetworkToolsManager()
        self.encodingTools = EncodingToolsManager()
        self.apiKeyManager = APIKeyManager()
    }
}

// MARK: - Security Error Types

public enum SecurityError: Error, LocalizedError {
    case networkError(String)
    case invalidInput(String)
    case apiKeyMissing(String)
    case encodingError(String)
    case unknownError(String)
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .invalidInput(let message):
            return "Invalid Input: \(message)"
        case .apiKeyMissing(let message):
            return "API Key Missing: \(message)"
        case .encodingError(let message):
            return "Encoding Error: \(message)"
        case .unknownError(let message):
            return "Unknown Error: \(message)"
        }
    }
}

// MARK: - Common Data Models

public struct SecurityResult<T> {
    public let data: T?
    public let error: SecurityError?
    public let timestamp: Date
    
    public init(data: T? = nil, error: SecurityError? = nil) {
        self.data = data
        self.error = error
        self.timestamp = Date()
    }
    
    public var isSuccess: Bool {
        return error == nil && data != nil
    }
}