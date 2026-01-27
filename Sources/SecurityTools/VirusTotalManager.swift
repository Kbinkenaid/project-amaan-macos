import Foundation

/// Manager for VirusTotal API operations
public class VirusTotalManager: ObservableObject {
    @Published public var isScanning = false
    @Published public var lastURLResult: VTURLResult?
    @Published public var lastFileResult: VTFileResult?
    @Published public var lastError: String?

    private let baseURL = "https://www.virustotal.com/api/v3"
    private let apiKeyManager = APIKeyManager()

    public init() {}

    // MARK: - URL/Domain Scanning

    /// Submit a URL for scanning
    public func scanURL(_ urlString: String) async -> SecurityResult<VTURLResult> {
        guard let apiKey = getAPIKey() else {
            return SecurityResult(error: .apiKeyMissing("VirusTotal API key not configured"))
        }

        // First, submit the URL for analysis
        let submitResult = await submitURLForAnalysis(urlString, apiKey: apiKey)

        guard let analysisId = submitResult.data else {
            return SecurityResult(error: submitResult.error ?? .unknownError("Failed to submit URL"))
        }

        // Then get the analysis results
        return await getURLAnalysis(analysisId: analysisId, originalURL: urlString, apiKey: apiKey)
    }

    private func submitURLForAnalysis(_ urlString: String, apiKey: String) async -> SecurityResult<String> {
        guard let url = URL(string: "\(baseURL)/urls") else {
            return SecurityResult(error: .invalidInput("Invalid API URL"))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-apikey")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "url=\(urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlString)"
        request.httpBody = body.data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return SecurityResult(error: .networkError("Invalid response"))
            }

            if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataObj = json["data"] as? [String: Any],
                   let id = dataObj["id"] as? String {
                    return SecurityResult(data: id)
                }
            }

            return SecurityResult(error: .networkError("API error: \(httpResponse.statusCode)"))
        } catch {
            return SecurityResult(error: .networkError(error.localizedDescription))
        }
    }

    private func getURLAnalysis(analysisId: String, originalURL: String, apiKey: String) async -> SecurityResult<VTURLResult> {
        guard let url = URL(string: "\(baseURL)/analyses/\(analysisId)") else {
            return SecurityResult(error: .invalidInput("Invalid API URL"))
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-apikey")

        // Poll for results (analysis may take time)
        for _ in 0..<10 {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    continue
                }

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataObj = json["data"] as? [String: Any],
                   let attributes = dataObj["attributes"] as? [String: Any] {

                    let status = attributes["status"] as? String

                    if status == "completed" {
                        let result = parseURLAnalysisResult(attributes, originalURL: originalURL)

                        await MainActor.run {
                            self.lastURLResult = result
                        }

                        return SecurityResult(data: result)
                    }
                }

                // Wait before polling again
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            } catch {
                continue
            }
        }

        return SecurityResult(error: .networkError("Analysis timeout"))
    }

    /// Get domain report
    public func getDomainReport(_ domain: String) async -> SecurityResult<VTURLResult> {
        guard let apiKey = getAPIKey() else {
            return SecurityResult(error: .apiKeyMissing("VirusTotal API key not configured"))
        }

        guard let url = URL(string: "\(baseURL)/domains/\(domain)") else {
            return SecurityResult(error: .invalidInput("Invalid domain"))
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-apikey")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return SecurityResult(error: .networkError("Invalid response"))
            }

            if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataObj = json["data"] as? [String: Any],
                   let attributes = dataObj["attributes"] as? [String: Any] {

                    let result = parseDomainResult(attributes, domain: domain)

                    await MainActor.run {
                        self.lastURLResult = result
                    }

                    return SecurityResult(data: result)
                }
            }

            return SecurityResult(error: .networkError("API error: \(httpResponse.statusCode)"))
        } catch {
            return SecurityResult(error: .networkError(error.localizedDescription))
        }
    }

    // MARK: - File Scanning

    /// Get file report by hash (doesn't upload the file)
    public func getFileReport(hash: String) async -> SecurityResult<VTFileResult> {
        guard let apiKey = getAPIKey() else {
            return SecurityResult(error: .apiKeyMissing("VirusTotal API key not configured"))
        }

        guard let url = URL(string: "\(baseURL)/files/\(hash)") else {
            return SecurityResult(error: .invalidInput("Invalid hash"))
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-apikey")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return SecurityResult(error: .networkError("Invalid response"))
            }

            if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataObj = json["data"] as? [String: Any],
                   let attributes = dataObj["attributes"] as? [String: Any] {

                    let result = parseFileResult(attributes, hash: hash)

                    await MainActor.run {
                        self.lastFileResult = result
                    }

                    return SecurityResult(data: result)
                }
            } else if httpResponse.statusCode == 404 {
                return SecurityResult(error: .invalidInput("File not found in VirusTotal database"))
            }

            return SecurityResult(error: .networkError("API error: \(httpResponse.statusCode)"))
        } catch {
            return SecurityResult(error: .networkError(error.localizedDescription))
        }
    }

    /// Upload and scan a file
    public func scanFile(_ fileURL: URL) async -> SecurityResult<VTFileResult> {
        guard let apiKey = getAPIKey() else {
            return SecurityResult(error: .apiKeyMissing("VirusTotal API key not configured"))
        }

        // Check file size - VirusTotal has limits
        guard let fileSize = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64,
              fileSize <= 32 * 1024 * 1024 else { // 32MB limit for standard endpoint
            return SecurityResult(error: .invalidInput("File too large (max 32MB)"))
        }

        guard let url = URL(string: "\(baseURL)/files") else {
            return SecurityResult(error: .invalidInput("Invalid API URL"))
        }

        // Read file data
        guard let fileData = try? Data(contentsOf: fileURL) else {
            return SecurityResult(error: .invalidInput("Could not read file"))
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-apikey")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Build multipart form data
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return SecurityResult(error: .networkError("Invalid response"))
            }

            if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataObj = json["data"] as? [String: Any],
                   let id = dataObj["id"] as? String {

                    // Get the analysis results
                    return await getFileAnalysis(analysisId: id, fileName: fileURL.lastPathComponent, apiKey: apiKey)
                }
            }

            return SecurityResult(error: .networkError("Upload failed: \(httpResponse.statusCode)"))
        } catch {
            return SecurityResult(error: .networkError(error.localizedDescription))
        }
    }

    private func getFileAnalysis(analysisId: String, fileName: String, apiKey: String) async -> SecurityResult<VTFileResult> {
        guard let url = URL(string: "\(baseURL)/analyses/\(analysisId)") else {
            return SecurityResult(error: .invalidInput("Invalid API URL"))
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-apikey")

        // Poll for results
        for _ in 0..<30 { // File analysis can take longer
            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    continue
                }

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataObj = json["data"] as? [String: Any],
                   let attributes = dataObj["attributes"] as? [String: Any] {

                    let status = attributes["status"] as? String

                    if status == "completed" {
                        let result = parseFileAnalysisResult(attributes, fileName: fileName)

                        await MainActor.run {
                            self.lastFileResult = result
                        }

                        return SecurityResult(data: result)
                    }
                }

                try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            } catch {
                continue
            }
        }

        return SecurityResult(error: .networkError("Analysis timeout"))
    }

    // MARK: - Parsing Helpers

    private func parseURLAnalysisResult(_ attributes: [String: Any], originalURL: String) -> VTURLResult {
        var positives = 0
        var total = 0
        var engines: [VTEngine] = []

        if let stats = attributes["stats"] as? [String: Int] {
            positives = (stats["malicious"] ?? 0) + (stats["suspicious"] ?? 0)
            total = (stats["harmless"] ?? 0) + (stats["malicious"] ?? 0) +
                   (stats["suspicious"] ?? 0) + (stats["undetected"] ?? 0)
        }

        if let results = attributes["results"] as? [String: [String: Any]] {
            for (engineName, result) in results {
                let category = result["category"] as? String ?? "undetected"
                let detected = category == "malicious" || category == "suspicious"
                let resultText = result["result"] as? String

                engines.append(VTEngine(
                    name: engineName,
                    detected: detected,
                    result: resultText,
                    category: category
                ))
            }
        }

        // Sort engines: detected first, then alphabetically
        engines.sort {
            if $0.detected != $1.detected {
                return $0.detected
            }
            return $0.name < $1.name
        }

        return VTURLResult(
            url: originalURL,
            scanDate: Date(),
            positives: positives,
            total: total,
            categories: [],
            engines: engines
        )
    }

    private func parseDomainResult(_ attributes: [String: Any], domain: String) -> VTURLResult {
        var positives = 0
        var total = 0
        var engines: [VTEngine] = []
        var categories: [String] = []

        if let stats = attributes["last_analysis_stats"] as? [String: Int] {
            positives = (stats["malicious"] ?? 0) + (stats["suspicious"] ?? 0)
            total = (stats["harmless"] ?? 0) + (stats["malicious"] ?? 0) +
                   (stats["suspicious"] ?? 0) + (stats["undetected"] ?? 0)
        }

        if let results = attributes["last_analysis_results"] as? [String: [String: Any]] {
            for (engineName, result) in results {
                let category = result["category"] as? String ?? "undetected"
                let detected = category == "malicious" || category == "suspicious"
                let resultText = result["result"] as? String

                engines.append(VTEngine(
                    name: engineName,
                    detected: detected,
                    result: resultText,
                    category: category
                ))
            }
        }

        if let cats = attributes["categories"] as? [String: String] {
            categories = Array(Set(cats.values))
        }

        engines.sort {
            if $0.detected != $1.detected {
                return $0.detected
            }
            return $0.name < $1.name
        }

        return VTURLResult(
            url: domain,
            scanDate: Date(),
            positives: positives,
            total: total,
            categories: categories,
            engines: engines
        )
    }

    private func parseFileResult(_ attributes: [String: Any], hash: String) -> VTFileResult {
        var positives = 0
        var total = 0
        var detections: [VTDetection] = []

        let fileName = attributes["meaningful_name"] as? String ??
                      (attributes["names"] as? [String])?.first ?? "Unknown"
        let fileSize = attributes["size"] as? Int ?? 0

        if let stats = attributes["last_analysis_stats"] as? [String: Int] {
            positives = (stats["malicious"] ?? 0) + (stats["suspicious"] ?? 0)
            total = (stats["harmless"] ?? 0) + (stats["malicious"] ?? 0) +
                   (stats["suspicious"] ?? 0) + (stats["undetected"] ?? 0)
        }

        if let results = attributes["last_analysis_results"] as? [String: [String: Any]] {
            for (engineName, result) in results {
                let category = result["category"] as? String ?? "undetected"
                let detected = category == "malicious" || category == "suspicious"

                if detected {
                    detections.append(VTDetection(
                        engine: engineName,
                        malwareType: result["result"] as? String ?? "Detected",
                        category: category
                    ))
                }
            }
        }

        detections.sort { $0.engine < $1.engine }

        return VTFileResult(
            fileName: fileName,
            fileHash: hash,
            fileSize: fileSize,
            scanDate: Date(),
            positives: positives,
            total: total,
            detections: detections
        )
    }

    private func parseFileAnalysisResult(_ attributes: [String: Any], fileName: String) -> VTFileResult {
        var positives = 0
        var total = 0
        var detections: [VTDetection] = []
        var fileHash = ""

        if let stats = attributes["stats"] as? [String: Int] {
            positives = (stats["malicious"] ?? 0) + (stats["suspicious"] ?? 0)
            total = (stats["harmless"] ?? 0) + (stats["malicious"] ?? 0) +
                   (stats["suspicious"] ?? 0) + (stats["undetected"] ?? 0)
        }

        if let results = attributes["results"] as? [String: [String: Any]] {
            for (engineName, result) in results {
                let category = result["category"] as? String ?? "undetected"
                let detected = category == "malicious" || category == "suspicious"

                if detected {
                    detections.append(VTDetection(
                        engine: engineName,
                        malwareType: result["result"] as? String ?? "Detected",
                        category: category
                    ))
                }
            }
        }

        if let meta = attributes["meta"] as? [String: Any],
           let fileInfo = meta["file_info"] as? [String: Any] {
            fileHash = fileInfo["sha256"] as? String ?? ""
        }

        detections.sort { $0.engine < $1.engine }

        return VTFileResult(
            fileName: fileName,
            fileHash: fileHash,
            fileSize: 0,
            scanDate: Date(),
            positives: positives,
            total: total,
            detections: detections
        )
    }

    // MARK: - Helpers

    private func getAPIKey() -> String? {
        let result = apiKeyManager.getAPIKey(for: .virustotal)
        return result.data
    }
}

// MARK: - Data Models

public struct VTURLResult: Sendable {
    public let url: String
    public let scanDate: Date
    public let positives: Int
    public let total: Int
    public let categories: [String]
    public let engines: [VTEngine]

    public var threatLevel: ThreatLevel {
        if total == 0 { return .unknown }
        let ratio = Double(positives) / Double(total)
        if positives == 0 { return .clean }
        if ratio < 0.1 { return .low }
        if ratio < 0.3 { return .medium }
        return .high
    }
}

public struct VTFileResult: Sendable {
    public let fileName: String
    public let fileHash: String
    public let fileSize: Int
    public let scanDate: Date
    public let positives: Int
    public let total: Int
    public let detections: [VTDetection]

    public var threatLevel: ThreatLevel {
        if total == 0 { return .unknown }
        let ratio = Double(positives) / Double(total)
        if positives == 0 { return .clean }
        if ratio < 0.1 { return .low }
        if ratio < 0.3 { return .medium }
        return .high
    }

    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
    }
}

public struct VTEngine: Sendable {
    public let name: String
    public let detected: Bool
    public let result: String?
    public let category: String
}

public struct VTDetection: Sendable {
    public let engine: String
    public let malwareType: String
    public let category: String
}

public enum ThreatLevel: Sendable {
    case clean
    case low
    case medium
    case high
    case unknown

    public var description: String {
        switch self {
        case .clean: return "Clean"
        case .low: return "Low Risk"
        case .medium: return "Medium Risk"
        case .high: return "High Risk"
        case .unknown: return "Unknown"
        }
    }

    public var color: String {
        switch self {
        case .clean: return "green"
        case .low: return "yellow"
        case .medium: return "orange"
        case .high: return "red"
        case .unknown: return "gray"
        }
    }
}
