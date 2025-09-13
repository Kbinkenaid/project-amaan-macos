import Foundation
import Security

/// Manager for secure API key storage and management
public class APIKeyManager: ObservableObject {
    @Published public var availableServices: [APIService] = []
    
    private let serviceName = "ProjectAmaan"
    
    public init() {
        setupAvailableServices()
    }
    
    // MARK: - Public Methods
    
    /// Store an API key securely in the Keychain
    public func storeAPIKey(_ key: String, for service: APIService) -> SecurityResult<Bool> {
        guard !key.isEmpty else {
            return SecurityResult(error: .invalidInput("API key cannot be empty"))
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: service.identifier,
            kSecValueData as String: key.data(using: .utf8)!
        ]
        
        // Delete existing key first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            updateServiceAvailability(for: service, isAvailable: true)
            return SecurityResult(data: true)
        } else {
            return SecurityResult(error: .unknownError("Failed to store API key: \(status)"))
        }
    }
    
    /// Retrieve an API key from the Keychain
    public func getAPIKey(for service: APIService) -> SecurityResult<String> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: service.identifier,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let key = String(data: data, encoding: .utf8) {
            return SecurityResult(data: key)
        } else if status == errSecItemNotFound {
            return SecurityResult(error: .apiKeyMissing("API key not found for \(service.name)"))
        } else {
            return SecurityResult(error: .unknownError("Failed to retrieve API key: \(status)"))
        }
    }
    
    /// Remove an API key from the Keychain
    public func removeAPIKey(for service: APIService) -> SecurityResult<Bool> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: service.identifier
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            updateServiceAvailability(for: service, isAvailable: false)
            return SecurityResult(data: true)
        } else {
            return SecurityResult(error: .unknownError("Failed to remove API key: \(status)"))
        }
    }
    
    /// Check if an API key exists for a service
    public func hasAPIKey(for service: APIService) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: service.identifier
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Validate an API key format
    public func validateAPIKey(_ key: String, for service: APIService) -> SecurityResult<Bool> {
        guard !key.isEmpty else {
            return SecurityResult(error: .invalidInput("API key cannot be empty"))
        }
        
        if service == .haveIBeenPwned {
            // HIBP API keys are typically 32-character hex strings
            let isValidFormat = key.count >= 32 && key.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber) }
            if isValidFormat {
                return SecurityResult(data: true)
            } else {
                return SecurityResult(error: .invalidInput("Invalid HaveIBeenPwned API key format"))
            }
        } else if service == .virustotal {
            // VirusTotal API keys are typically 64-character hex strings
            let isValidFormat = key.count == 64 && key.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber) }
            if isValidFormat {
                return SecurityResult(data: true)
            } else {
                return SecurityResult(error: .invalidInput("Invalid VirusTotal API key format"))
            }
        } else if service == .shodan {
            // Shodan API keys are typically 32-character alphanumeric strings
            let isValidFormat = key.count == 32 && key.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber) }
            if isValidFormat {
                return SecurityResult(data: true)
            } else {
                return SecurityResult(error: .invalidInput("Invalid Shodan API key format"))
            }
        }
        
        // Default case - basic validation for unknown services
        return SecurityResult(data: !key.isEmpty && key.count >= 16)
    }
    
    /// Get all configured API services
    public func getConfiguredServices() -> [APIService] {
        return availableServices.filter { hasAPIKey(for: $0) }
    }
    
    /// Export API keys (for backup purposes)
    public func exportAPIKeys() -> SecurityResult<[String: String]> {
        var exportData: [String: String] = [:]
        
        for service in APIService.allCases {
            if let keyResult = getAPIKey(for: service).data {
                exportData[service.identifier] = keyResult
            }
        }
        
        return SecurityResult(data: exportData)
    }
    
    /// Import API keys (from backup)
    public func importAPIKeys(_ keyData: [String: String]) -> SecurityResult<Int> {
        var importedCount = 0
        
        for (identifier, key) in keyData {
            if let service = APIService.allCases.first(where: { $0.identifier == identifier }) {
                if storeAPIKey(key, for: service).isSuccess {
                    importedCount += 1
                }
            }
        }
        
        return SecurityResult(data: importedCount)
    }
    
    // MARK: - Private Methods
    
    private func setupAvailableServices() {
        availableServices = APIService.allCases
        
        // Update availability status for each service
        for service in availableServices {
            updateServiceAvailability(for: service, isAvailable: hasAPIKey(for: service))
        }
    }
    
    private func updateServiceAvailability(for service: APIService, isAvailable: Bool) {
        DispatchQueue.main.async {
            if let index = self.availableServices.firstIndex(where: { $0.identifier == service.identifier }) {
                self.availableServices[index] = APIService(
                    name: service.name,
                    identifier: service.identifier,
                    description: service.description,
                    websiteURL: service.websiteURL,
                    isConfigured: isAvailable
                )
            }
        }
    }
}

// MARK: - Data Models

public struct APIService: Identifiable, CaseIterable, Equatable, Hashable {
    public let id = UUID()
    public let name: String
    public let identifier: String
    public let description: String
    public let websiteURL: String
    public let isConfigured: Bool
    
    public init(name: String, identifier: String, description: String, websiteURL: String, isConfigured: Bool = false) {
        self.name = name
        self.identifier = identifier
        self.description = description
        self.websiteURL = websiteURL
        self.isConfigured = isConfigured
    }
    
    public static let haveIBeenPwned = APIService(
        name: "HaveIBeenPwned",
        identifier: "hibp",
        description: "Check if email addresses or domains have been involved in data breaches",
        websiteURL: "https://haveibeenpwned.com/API/Key"
    )
    
    public static let virustotal = APIService(
        name: "VirusTotal",
        identifier: "virustotal",
        description: "Analyze files and URLs for malware and security threats",
        websiteURL: "https://www.virustotal.com/gui/join-us"
    )
    
    public static let shodan = APIService(
        name: "Shodan",
        identifier: "shodan",
        description: "Search engine for Internet-connected devices and services",
        websiteURL: "https://account.shodan.io/"
    )
    
    public static let allCases: [APIService] = [
        .haveIBeenPwned,
        .virustotal,
        .shodan
    ]
    
    public static func == (lhs: APIService, rhs: APIService) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}