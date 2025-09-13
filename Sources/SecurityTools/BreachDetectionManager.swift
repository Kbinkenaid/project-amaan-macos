import Foundation
import NIO
import NIOHTTP1

/// Manager for HaveIBeenPwned breach detection functionality
public class BreachDetectionManager: ObservableObject {
    @Published public var isChecking = false
    @Published public var lastResult: BreachResult?
    
    public init() {
    }
    
    private let baseURL = "https://haveibeenpwned.com/api/v3"
    private var apiKey: String? {
        return UserDefaults.standard.string(forKey: "haveibeenpwned_api_key")
    }
    
    // MARK: - Public Methods
    
    /// Check if an email has been involved in any breaches
    public func checkEmail(_ email: String) async -> SecurityResult<BreachResult> {
        guard isValidEmail(email) else {
            return SecurityResult(error: .invalidInput("Invalid email format"))
        }
        
        isChecking = true
        defer { isChecking = false }
        
        do {
            let breaches = try await fetchBreaches(for: email, type: .email)
            let result = BreachResult(
                query: email,
                type: .email,
                breaches: breaches,
                isBreached: !breaches.isEmpty
            )
            
            DispatchQueue.main.async {
                self.lastResult = result
            }
            
            return SecurityResult(data: result)
        } catch let error as SecurityError {
            return SecurityResult(error: error)
        } catch {
            return SecurityResult(error: .networkError(error.localizedDescription))
        }
    }
    
    /// Check if a domain has been involved in any breaches
    public func checkDomain(_ domain: String) async -> SecurityResult<BreachResult> {
        guard isValidDomain(domain) else {
            return SecurityResult(error: .invalidInput("Invalid domain format"))
        }
        
        isChecking = true
        defer { isChecking = false }
        
        do {
            let breaches = try await fetchBreaches(for: domain, type: .domain)
            let result = BreachResult(
                query: domain,
                type: .domain,
                breaches: breaches,
                isBreached: !breaches.isEmpty
            )
            
            DispatchQueue.main.async {
                self.lastResult = result
            }
            
            return SecurityResult(data: result)
        } catch let error as SecurityError {
            return SecurityResult(error: error)
        } catch {
            return SecurityResult(error: .networkError(error.localizedDescription))
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchBreaches(for query: String, type: QueryType) async throws -> [Breach] {
        let endpoint = type == .email ? "/breachedaccount/\(query)" : "/breaches"
        let urlString = baseURL + endpoint
        
        guard let url = URL(string: urlString) else {
            throw SecurityError.networkError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add API key if available
        if let apiKey = apiKey {
            request.addValue(apiKey, forHTTPHeaderField: "hibp-api-key")
        }
        
        request.addValue("ProjectAmaan-macOS", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    return try parseBreachResponse(data)
                case 404:
                    return [] // No breaches found
                case 401:
                    throw SecurityError.apiKeyMissing("Invalid or missing API key")
                case 429:
                    throw SecurityError.networkError("Rate limit exceeded. Please try again later.")
                default:
                    throw SecurityError.networkError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            throw SecurityError.networkError("Invalid response")
        } catch let error as SecurityError {
            throw error
        } catch {
            throw SecurityError.networkError("Request failed: \(error.localizedDescription)")
        }
    }
    
    private func parseBreachResponse(_ data: Data) throws -> [Breach] {
        do {
            let breaches = try JSONDecoder().decode([Breach].self, from: data)
            return breaches
        } catch {
            throw SecurityError.encodingError("Failed to parse breach data")
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func isValidDomain(_ domain: String) -> Bool {
        let domainRegex = "^[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", domainRegex).evaluate(with: domain)
    }
}

// MARK: - Data Models

public struct BreachResult: Sendable {
    public let query: String
    public let type: QueryType
    public let breaches: [Breach]
    public let isBreached: Bool
    public let timestamp: Date
    
    public init(query: String, type: QueryType, breaches: [Breach], isBreached: Bool) {
        self.query = query
        self.type = type
        self.breaches = breaches
        self.isBreached = isBreached
        self.timestamp = Date()
    }
}

public struct Breach: Codable, Identifiable {
    public let name: String
    public let title: String
    public let domain: String
    public let breachDate: String
    public let addedDate: String
    public let modifiedDate: String
    public let pwnCount: Int
    public let description: String
    public let logoPath: String
    public let dataClasses: [String]
    public let isVerified: Bool
    public let isFabricated: Bool
    public let isSensitive: Bool
    public let isRetired: Bool
    public let isSpamList: Bool
    
    public var id: String { name }
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case title = "Title"
        case domain = "Domain"
        case breachDate = "BreachDate"
        case addedDate = "AddedDate"
        case modifiedDate = "ModifiedDate"
        case pwnCount = "PwnCount"
        case description = "Description"
        case logoPath = "LogoPath"
        case dataClasses = "DataClasses"
        case isVerified = "IsVerified"
        case isFabricated = "IsFabricated"
        case isSensitive = "IsSensitive"
        case isRetired = "IsRetired"
        case isSpamList = "IsSpamList"
    }
}

public enum QueryType: Sendable {
    case email
    case domain
}