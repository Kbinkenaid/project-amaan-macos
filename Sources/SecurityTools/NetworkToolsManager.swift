import Foundation
import Network
import NIO

/// Manager for network security tools (port scanning, WHOIS, DNS lookup)
public class NetworkToolsManager: ObservableObject {
    @Published public var isScanning = false
    @Published public var scanProgress: Double = 0
    @Published public var lastScanResult: PortScanResult?
    @Published public var lastWhoisResult: WhoisResult?
    @Published public var lastDNSResult: DNSResult?
    
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    public init() {
        monitor.start(queue: monitorQueue)
    }
    
    deinit {
        monitor.cancel()
    }
    
    // MARK: - Port Scanning
    
    /// Scan a host for open ports
    public func scanPorts(host: String, ports: [Int]) async -> SecurityResult<PortScanResult> {
        guard isValidHost(host) else {
            return SecurityResult(error: .invalidInput("Invalid host format"))
        }
        
        guard !ports.isEmpty && ports.allSatisfy({ $0 > 0 && $0 <= 65535 }) else {
            return SecurityResult(error: .invalidInput("Invalid port range"))
        }
        
        isScanning = true
        scanProgress = 0
        defer { 
            isScanning = false
            scanProgress = 0
        }
        
        var openPorts: [PortScanEntry] = []
        let totalPorts = ports.count
        
        for (index, port) in ports.enumerated() {
            let isOpen = await checkPort(host: host, port: port)
            if isOpen {
                let entry = PortScanEntry(
                    port: port,
                    isOpen: true,
                    service: getServiceName(for: port)
                )
                openPorts.append(entry)
            }
            
            DispatchQueue.main.async {
                self.scanProgress = Double(index + 1) / Double(totalPorts)
            }
        }
        
        let result = PortScanResult(
            host: host,
            scannedPorts: ports,
            openPorts: openPorts,
            scanDuration: Date().timeIntervalSince(Date())
        )
        
        DispatchQueue.main.async {
            self.lastScanResult = result
        }
        
        return SecurityResult(data: result)
    }
    
    /// Quick scan of common ports
    public func quickScan(host: String) async -> SecurityResult<PortScanResult> {
        let commonPorts = [21, 22, 23, 25, 53, 80, 110, 143, 443, 993, 995]
        return await scanPorts(host: host, ports: commonPorts)
    }
    
    // MARK: - WHOIS Lookup
    
    /// Perform WHOIS lookup for a domain
    public func whoisLookup(_ domain: String) async -> SecurityResult<WhoisResult> {
        guard isValidDomain(domain) else {
            return SecurityResult(error: .invalidInput("Invalid domain format"))
        }
        
        do {
            let whoisData = try await performWhoisQuery(domain)
            let result = WhoisResult(
                domain: domain,
                rawData: whoisData,
                parsedInfo: parseWhoisData(whoisData)
            )
            
            DispatchQueue.main.async {
                self.lastWhoisResult = result
            }
            
            return SecurityResult(data: result)
        } catch let error as SecurityError {
            return SecurityResult(error: error)
        } catch {
            return SecurityResult(error: .networkError("WHOIS lookup failed: \(error.localizedDescription)"))
        }
    }
    
    // MARK: - DNS Lookup
    
    /// Perform DNS lookup for a domain
    public func dnsLookup(_ domain: String) async -> SecurityResult<DNSResult> {
        guard isValidDomain(domain) else {
            return SecurityResult(error: .invalidInput("Invalid domain format"))
        }
        
        do {
            let dnsRecords = try await performDNSQuery(domain)
            let result = DNSResult(
                domain: domain,
                records: dnsRecords
            )
            
            DispatchQueue.main.async {
                self.lastDNSResult = result
            }
            
            return SecurityResult(data: result)
        } catch let error as SecurityError {
            return SecurityResult(error: error)
        } catch {
            return SecurityResult(error: .networkError("DNS lookup failed: \(error.localizedDescription)"))
        }
    }
    
    // MARK: - Private Methods
    
    private func checkPort(host: String, port: Int) async -> Bool {
        return await withCheckedContinuation { continuation in
            let queue = DispatchQueue(label: "port-check-\(port)")
            var hasResumed = false
            let lock = NSLock()

            func safeResume(with value: Bool) {
                lock.lock()
                defer { lock.unlock() }
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(returning: value)
                }
            }

            let connection = NWConnection(
                host: NWEndpoint.Host(host),
                port: NWEndpoint.Port(integerLiteral: UInt16(port)),
                using: .tcp
            )

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connection.cancel()
                    safeResume(with: true)
                case .failed(_), .cancelled:
                    safeResume(with: false)
                default:
                    break
                }
            }

            connection.start(queue: queue)

            // Timeout after 2 seconds
            queue.asyncAfter(deadline: .now() + 2) {
                connection.cancel()
                safeResume(with: false)
            }
        }
    }
    
    private func performWhoisQuery(_ domain: String) async throws -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/whois")
        process.arguments = [domain]
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output
            } else {
                throw SecurityError.encodingError("Failed to decode WHOIS response")
            }
        } catch {
            throw SecurityError.networkError("WHOIS command failed")
        }
    }
    
    private func performDNSQuery(_ domain: String) async throws -> [DNSRecord] {
        var records: [DNSRecord] = []

        // Use dig command for more reliable DNS lookups
        let recordTypes = ["A", "AAAA", "MX", "NS", "TXT", "CNAME"]

        for recordType in recordTypes {
            if let results = try? await runDigCommand(domain: domain, recordType: recordType) {
                records.append(contentsOf: results)
            }
        }

        // Fallback to system resolver if dig fails
        if records.isEmpty {
            if let addresses = try? await resolveHost(domain) {
                for address in addresses {
                    records.append(DNSRecord(type: "A", value: address))
                }
            }
        }

        if records.isEmpty {
            throw SecurityError.networkError("No DNS records found for \(domain)")
        }

        return records
    }

    private func runDigCommand(domain: String, recordType: String) async throws -> [DNSRecord] {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/dig")
        process.arguments = ["+short", domain, recordType]
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }

                return lines.map { DNSRecord(type: recordType, value: $0) }
            }
        } catch {
            // Silently fail for individual record types
        }

        return []
    }

    private func resolveHost(_ domain: String) async throws -> [String] {
        return try await withCheckedThrowingContinuation { continuation in
            let host = CFHostCreateWithName(nil, domain as CFString).takeRetainedValue()

            var result: DarwinBoolean = false
            let addresses = CFHostGetAddressing(host, &result)

            if result.boolValue, let addresses = addresses?.takeUnretainedValue() as? [Data] {
                let ipAddresses = addresses.compactMap { data -> String? in
                    data.withUnsafeBytes { bytes in
                        let sockaddr = bytes.bindMemory(to: sockaddr.self).baseAddress!
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))

                        if getnameinfo(sockaddr, socklen_t(data.count),
                                     &hostname, socklen_t(hostname.count),
                                     nil, 0, NI_NUMERICHOST) == 0 {
                            return String(cString: hostname)
                        }
                        return nil
                    }
                }
                continuation.resume(returning: ipAddresses)
            } else {
                continuation.resume(throwing: SecurityError.networkError("DNS resolution failed"))
            }
        }
    }
    
    private func parseWhoisData(_ rawData: String) -> [String: String] {
        var parsed: [String: String] = [:]
        
        let lines = rawData.components(separatedBy: .newlines)
        for line in lines {
            if line.contains(":") {
                let components = line.components(separatedBy: ":").map { $0.trimmingCharacters(in: .whitespaces) }
                if components.count >= 2 {
                    let key = components[0]
                    let value = components[1...].joined(separator: ":")
                    parsed[key] = value
                }
            }
        }
        
        return parsed
    }
    
    private func getServiceName(for port: Int) -> String {
        let commonServices: [Int: String] = [
            21: "FTP",
            22: "SSH",
            23: "Telnet",
            25: "SMTP",
            53: "DNS",
            80: "HTTP",
            110: "POP3",
            143: "IMAP",
            443: "HTTPS",
            993: "IMAPS",
            995: "POP3S"
        ]
        
        return commonServices[port] ?? "Unknown"
    }
    
    private func isValidHost(_ host: String) -> Bool {
        // Check if it's an IP address or domain name
        return isValidIPAddress(host) || isValidDomain(host)
    }
    
    private func isValidIPAddress(_ ip: String) -> Bool {
        var sin = sockaddr_in()
        var sin6 = sockaddr_in6()
        
        if ip.withCString({ cstring in inet_pton(AF_INET, cstring, &sin.sin_addr) }) == 1 {
            return true
        }
        
        if ip.withCString({ cstring in inet_pton(AF_INET6, cstring, &sin6.sin6_addr) }) == 1 {
            return true
        }
        
        return false
    }
    
    private func isValidDomain(_ domain: String) -> Bool {
        let domainRegex = "^[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", domainRegex).evaluate(with: domain)
    }
}

// MARK: - Data Models

public struct PortScanResult: Sendable {
    public let host: String
    public let scannedPorts: [Int]
    public let openPorts: [PortScanEntry]
    public let scanDuration: TimeInterval
    public let timestamp: Date
    
    public init(host: String, scannedPorts: [Int], openPorts: [PortScanEntry], scanDuration: TimeInterval) {
        self.host = host
        self.scannedPorts = scannedPorts
        self.openPorts = openPorts
        self.scanDuration = scanDuration
        self.timestamp = Date()
    }
}

public struct PortScanEntry: Sendable {
    public let port: Int
    public let isOpen: Bool
    public let service: String
    
    public init(port: Int, isOpen: Bool, service: String) {
        self.port = port
        self.isOpen = isOpen
        self.service = service
    }
}

public struct WhoisResult: Sendable {
    public let domain: String
    public let rawData: String
    public let parsedInfo: [String: String]
    public let timestamp: Date
    
    public init(domain: String, rawData: String, parsedInfo: [String: String]) {
        self.domain = domain
        self.rawData = rawData
        self.parsedInfo = parsedInfo
        self.timestamp = Date()
    }
}

public struct DNSResult: Sendable {
    public let domain: String
    public let records: [DNSRecord]
    public let timestamp: Date
    
    public init(domain: String, records: [DNSRecord]) {
        self.domain = domain
        self.records = records
        self.timestamp = Date()
    }
}

public struct DNSRecord: Sendable {
    public let type: String
    public let value: String
    
    public init(type: String, value: String) {
        self.type = type
        self.value = value
    }
}