import SwiftUI
import Foundation
import SecurityTools

struct WorkingNetworkToolsView: View {
    @State private var selectedTool: NetworkTool = .portScanner
    
    enum NetworkTool: String, CaseIterable {
        case portScanner = "Port Scanner"
        case whoisLookup = "WHOIS Lookup"
        case dnsLookup = "DNS Lookup"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("🌐 Network Tools")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Professional network analysis and reconnaissance tools for security testing.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // Tool Selector
            Picker("Network Tool", selection: $selectedTool) {
                ForEach(NetworkTool.allCases, id: \.self) { tool in
                    Text(tool.rawValue).tag(tool)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Tool Content
            ScrollView {
                switch selectedTool {
                case .portScanner:
                    PortScannerView()
                case .whoisLookup:
                    WhoisLookupView()
                case .dnsLookup:
                    DNSLookupView()
                }
            }
        }
    }
}

struct PortScannerView: View {
    @StateObject private var networkManager = NetworkToolsManager()
    @State private var hostInput = ""
    @State private var portRange = "22,80,443,8080,3389"
    @State private var showResults = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Input Section
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Host:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Enter IP address or domain name", text: $hostInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(.body, design: .monospaced))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ports to Scan:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("22,80,443,8080,3389", text: $portRange)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(.body, design: .monospaced))
                    
                    Text("Separate multiple ports with commas or use ranges (e.g., 80-90)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Button(action: startPortScan) {
                        HStack {
                            if networkManager.isScanning {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(networkManager.isScanning ? "Scanning..." : "Start Port Scan")
                        }
                        .frame(minWidth: 120)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(hostInput.isEmpty || networkManager.isScanning)
                    
                    if networkManager.isScanning {
                        Button("Stop") {
                            stopScan()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            
            // Progress
            if networkManager.isScanning {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scan Progress")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ProgressView(value: networkManager.scanProgress, total: 1.0)
                    
                    Text("\(Int(networkManager.scanProgress * 100))% Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
            
            // Results
            if showResults {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Scan Results for \(hostInput)")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Clear") {
                            clearResults()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if let result = networkManager.lastScanResult {
                        if result.openPorts.isEmpty {
                            Label("No open ports found", systemImage: "checkmark.shield.fill")
                                .foregroundColor(.green)
                                .padding()
                                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(Array(result.openPorts.enumerated()), id: \.offset) { _, portEntry in
                                    RealPortResultRow(port: portEntry.port, service: getServiceName(for: portEntry.port))
                                }
                            }
                        }
                    } else if !networkManager.isScanning && showResults {
                        Label("No open ports found", systemImage: "checkmark.shield.fill")
                            .foregroundColor(.green)
                            .padding()
                            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
    
    private func startPortScan() {
        guard !hostInput.isEmpty else { return }
        
        showResults = true
        let ports = parsePortRange(portRange)
        
        Task {
            let result = await networkManager.scanPorts(host: hostInput, ports: ports)
            
            DispatchQueue.main.async {
                if !result.isSuccess {
                    // Handle error - could show error message
                    print("Port scan failed: \(result.error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func stopScan() {
        // Stop scanning if needed
        // NetworkToolsManager would need a stop method implementation
    }
    
    private func clearResults() {
        networkManager.lastScanResult = nil
        showResults = false
        hostInput = ""
    }
    
    private func parsePortRange(_ range: String) -> [Int] {
        let components = range.components(separatedBy: ",")
        var ports: [Int] = []
        
        for component in components {
            let trimmed = component.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("-") {
                let rangeParts = trimmed.components(separatedBy: "-")
                if rangeParts.count == 2,
                   let start = Int(rangeParts[0]),
                   let end = Int(rangeParts[1]) {
                    ports.append(contentsOf: start...end)
                }
            } else if let port = Int(trimmed) {
                ports.append(port)
            }
        }
        
        return Array(Set(ports)).sorted()
    }
    
    private func getServiceName(for port: Int) -> String {
        let services = [
            22: "SSH",
            80: "HTTP",
            443: "HTTPS", 
            8080: "HTTP-Alt",
            3389: "RDP",
            21: "FTP",
            25: "SMTP",
            53: "DNS",
            110: "POP3",
            995: "POP3S",
            143: "IMAP",
            993: "IMAPS"
        ]
        return services[port] ?? "Unknown"
    }
}

struct WhoisLookupView: View {
    @StateObject private var networkManager = NetworkToolsManager()
    @State private var domainInput = ""
    @State private var showResults = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Domain Name:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Enter domain name (e.g., example.com)", text: $domainInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(.body, design: .monospaced))
                }
                
                Button(action: performWhoisLookup) {
                    HStack {
                        if networkManager.isScanning {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(networkManager.isScanning ? "Looking up..." : "WHOIS Lookup")
                    }
                    .frame(minWidth: 120)
                }
                .buttonStyle(.borderedProminent)
                .disabled(domainInput.isEmpty || networkManager.isScanning)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            
            if showResults {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("WHOIS Results for \(domainInput)")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Clear") {
                            clearWhoisResults()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if let result = networkManager.lastWhoisResult {
                        RealWhoisResultView(result: result)
                    } else if !networkManager.isScanning && showResults {
                        Label("WHOIS lookup failed or no data available", systemImage: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .padding()
                            .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
    
    private func performWhoisLookup() {
        guard !domainInput.isEmpty else { return }
        
        showResults = true
        
        Task {
            let result = await networkManager.whoisLookup(domainInput)
            
            DispatchQueue.main.async {
                if !result.isSuccess {
                    print("WHOIS lookup failed: \(result.error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func clearWhoisResults() {
        networkManager.lastWhoisResult = nil
        showResults = false
        domainInput = ""
    }
}

struct DNSLookupView: View {
    @StateObject private var networkManager = NetworkToolsManager()
    @State private var domainInput = ""
    @State private var recordType = "A"
    @State private var showResults = false
    
    let recordTypes = ["A", "AAAA", "CNAME", "MX", "TXT", "NS"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Domain Name:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Enter domain name", text: $domainInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(.body, design: .monospaced))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Record Type:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Record Type", selection: $recordType) {
                        ForEach(recordTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Button(action: performDNSLookup) {
                    HStack {
                        if networkManager.isScanning {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(networkManager.isScanning ? "Looking up..." : "DNS Lookup")
                    }
                    .frame(minWidth: 120)
                }
                .buttonStyle(.borderedProminent)
                .disabled(domainInput.isEmpty || networkManager.isScanning)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            
            if showResults {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("DNS Results for \(domainInput)")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Clear") {
                            clearDNSResults()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if let dnsResult = networkManager.lastDNSResult, !dnsResult.records.isEmpty {
                        DNSResultsView(results: dnsResult.records)
                    } else if !networkManager.isScanning && showResults {
                        Label("DNS lookup failed or no records found", systemImage: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .padding()
                            .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
    
    private func performDNSLookup() {
        guard !domainInput.isEmpty else { return }
        
        showResults = true
        
        Task {
            let result = await networkManager.dnsLookup(domainInput)
            
            DispatchQueue.main.async {
                if !result.isSuccess {
                    print("DNS lookup failed: \(result.error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func clearDNSResults() {
        networkManager.lastDNSResult = nil
        showResults = false
        domainInput = ""
    }
}

// Supporting Views and Data Structures
struct PortResult {
    let port: Int
    let isOpen: Bool
    let service: String
}

struct PortResultRow: View {
    let result: PortResult
    
    var body: some View {
        HStack {
            Text("\(result.port)")
                .font(.system(.body, design: .monospaced))
                .frame(width: 60, alignment: .leading)
            
            Text(result.service)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Label("Open", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
    }
}

struct WhoisResult {
    let domain: String
    let registrar: String
    let registrationDate: String
    let expirationDate: String
    let nameServers: [String]
    let status: String
    let adminContact: String
    let techContact: String
}

struct WhoisResultView: View {
    let result: WhoisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WHOIS Information")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                WhoisRow(label: "Domain", value: result.domain)
                WhoisRow(label: "Registrar", value: result.registrar)
                WhoisRow(label: "Registration Date", value: formatDate(result.registrationDate))
                WhoisRow(label: "Expiration Date", value: formatDate(result.expirationDate))
                WhoisRow(label: "Status", value: result.status)
                WhoisRow(label: "Name Servers", value: result.nameServers.joined(separator: ", "))
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

struct WhoisRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("\(label):")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
        }
    }
}

struct DNSResultsView: View {
    let results: [SecurityTools.DNSRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DNS Records")
                .font(.headline)
            
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(Array(results.enumerated()), id: \.offset) { _, record in
                    HStack {
                        Text(record.type)
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.medium)
                            .frame(width: 60, alignment: .leading)
                        
                        Text(record.value)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct RealWhoisResultView: View {
    let result: SecurityTools.WhoisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WHOIS Information for \(result.domain)")
                .font(.headline)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(result.parsedInfo.keys.sorted()), id: \.self) { key in
                        if let value = result.parsedInfo[key], !value.isEmpty {
                            WhoisRow(label: key, value: value)
                        }
                    }
                    
                    Divider()
                    
                    Text("Raw WHOIS Data")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(result.rawData)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                }
            }
            .frame(maxHeight: 300)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    WorkingNetworkToolsView()
}