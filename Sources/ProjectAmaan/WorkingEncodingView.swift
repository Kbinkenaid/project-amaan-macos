import SwiftUI
import Foundation
import CryptoKit

struct WorkingEncodingToolsView: View {
    @State private var selectedOperation: EncodingOperation = .base64Encode
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var isProcessing = false
    @State private var history: [OperationHistory] = []
    @State private var showHistory = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("📝 Encoding/Decoding Tools")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Professional text encoding, decoding, and hashing utilities for security analysis.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Operation Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Operation Type")
                            .font(.headline)
                        
                        Picker("Operation", selection: $selectedOperation) {
                            Group {
                                Text("Base64 Encode").tag(EncodingOperation.base64Encode)
                                Text("Base64 Decode").tag(EncodingOperation.base64Decode)
                                Text("URL Encode").tag(EncodingOperation.urlEncode)
                                Text("URL Decode").tag(EncodingOperation.urlDecode)
                                Text("HTML Encode").tag(EncodingOperation.htmlEncode)
                                Text("HTML Decode").tag(EncodingOperation.htmlDecode)
                                Text("MD5 Hash").tag(EncodingOperation.md5Hash)
                                Text("SHA-256 Hash").tag(EncodingOperation.sha256Hash)
                                Text("Hex Encode").tag(EncodingOperation.hexEncode)
                                Text("Hex Decode").tag(EncodingOperation.hexDecode)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Text(selectedOperation.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    // Input/Output Section
                    HStack(spacing: 20) {
                        // Input
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Input")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("\(inputText.count) chars")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            TextEditor(text: $inputText)
                                .font(.system(.body, design: .monospaced))
                                .padding(8)
                                .background(.background, in: RoundedRectangle(cornerRadius: 8))
                                .frame(minHeight: 200)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Output
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Output")
                                    .font(.headline)
                                
                                Spacer()
                                
                                if !outputText.isEmpty {
                                    Button("Copy") {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(outputText, forType: .string)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            
                            TextEditor(text: .constant(outputText))
                                .font(.system(.body, design: .monospaced))
                                .padding(8)
                                .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                                .frame(minHeight: 200)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    // Action Buttons
                    HStack {
                        Button(action: processText) {
                            HStack {
                                if isProcessing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                                Text(isProcessing ? "Processing..." : "Process")
                            }
                            .frame(minWidth: 100)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(inputText.isEmpty || isProcessing)
                        
                        Button("Clear All") {
                            clearAll()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Sample Data") {
                            loadSampleData()
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button("History (\(history.count))") {
                            showHistory.toggle()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    // History Section
                    if showHistory && !history.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Operation History")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button("Clear History") {
                                    history.removeAll()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            
                            LazyVStack(spacing: 8) {
                                ForEach(Array(history.enumerated()), id: \.offset) { index, operation in
                                    HistoryRow(operation: operation) {
                                        inputText = operation.input
                                        outputText = operation.output
                                        selectedOperation = operation.operation
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            QuickActionButton(title: "Base64 Encode", operation: .base64Encode) {
                                selectedOperation = .base64Encode
                            }
                            
                            QuickActionButton(title: "URL Encode", operation: .urlEncode) {
                                selectedOperation = .urlEncode
                            }
                            
                            QuickActionButton(title: "MD5 Hash", operation: .md5Hash) {
                                selectedOperation = .md5Hash
                            }
                            
                            QuickActionButton(title: "SHA-256", operation: .sha256Hash) {
                                selectedOperation = .sha256Hash
                            }
                            
                            QuickActionButton(title: "Hex Encode", operation: .hexEncode) {
                                selectedOperation = .hexEncode
                            }
                            
                            QuickActionButton(title: "HTML Encode", operation: .htmlEncode) {
                                selectedOperation = .htmlEncode
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
        }
        .onAppear {
            loadSampleData()
        }
    }
    
    private func processText() {
        guard !inputText.isEmpty else { return }
        
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.performOperation(self.selectedOperation, on: self.inputText)
            
            DispatchQueue.main.async {
                self.isProcessing = false
                self.outputText = result
                
                // Add to history
                let historyItem = OperationHistory(
                    operation: self.selectedOperation,
                    input: self.inputText,
                    output: result,
                    timestamp: Date()
                )
                self.history.insert(historyItem, at: 0)
                
                // Keep only last 20 operations
                if self.history.count > 20 {
                    self.history.removeLast()
                }
            }
        }
    }
    
    private func performOperation(_ operation: EncodingOperation, on input: String) -> String {
        switch operation {
        case .base64Encode:
            return Data(input.utf8).base64EncodedString()
            
        case .base64Decode:
            guard let data = Data(base64Encoded: input) else { return "Invalid base64 input" }
            return String(data: data, encoding: .utf8) ?? "Unable to decode as UTF-8"
            
        case .urlEncode:
            return input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Encoding failed"
            
        case .urlDecode:
            return input.removingPercentEncoding ?? "Decoding failed"
            
        case .htmlEncode:
            return input
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "'", with: "&#x27;")
            
        case .htmlDecode:
            return input
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&#x27;", with: "'")
            
        case .md5Hash:
            let data = Data(input.utf8)
            let digest = Insecure.MD5.hash(data: data)
            return digest.map { String(format: "%02hhx", $0) }.joined()
            
        case .sha256Hash:
            let data = Data(input.utf8)
            let digest = SHA256.hash(data: data)
            return digest.map { String(format: "%02hhx", $0) }.joined()
            
        case .hexEncode:
            return Data(input.utf8).map { String(format: "%02x", $0) }.joined()
            
        case .hexDecode:
            let cleanInput = input.replacingOccurrences(of: " ", with: "")
            guard cleanInput.count % 2 == 0 else { return "Invalid hex input" }
            
            var data = Data()
            var index = cleanInput.startIndex
            
            while index < cleanInput.endIndex {
                let nextIndex = cleanInput.index(index, offsetBy: 2)
                let byteString = String(cleanInput[index..<nextIndex])
                
                guard let byte = UInt8(byteString, radix: 16) else {
                    return "Invalid hex input"
                }
                
                data.append(byte)
                index = nextIndex
            }
            
            return String(data: data, encoding: .utf8) ?? "Unable to decode as UTF-8"
        }
    }
    
    private func clearAll() {
        inputText = ""
        outputText = ""
    }
    
    private func loadSampleData() {
        switch selectedOperation {
        case .base64Encode, .base64Decode:
            inputText = "Hello, World! This is a test string for encoding."
        case .urlEncode, .urlDecode:
            inputText = "https://example.com/search?q=hello world&lang=en"
        case .htmlEncode, .htmlDecode:
            inputText = "<script>alert('Hello & \"World\"')</script>"
        case .md5Hash, .sha256Hash:
            inputText = "password123"
        case .hexEncode, .hexDecode:
            inputText = "Hello World!"
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let operation: EncodingOperation
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: operation.icon)
                    .font(.title3)
                
                Text(title)
                    .font(.caption)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }
}

struct HistoryRow: View {
    let operation: OperationHistory
    let onRestore: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(operation.operation.rawValue.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(operation.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Restore") {
                    onRestore()
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
            
            HStack {
                Text("Input:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(String(operation.input.prefix(30)) + (operation.input.count > 30 ? "..." : ""))
                    .font(.caption2)
                    .font(.system(.caption2, design: .monospaced))
            }
            
            HStack {
                Text("Output:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(String(operation.output.prefix(30)) + (operation.output.count > 30 ? "..." : ""))
                    .font(.caption2)
                    .font(.system(.caption2, design: .monospaced))
            }
        }
        .padding(8)
        .background(.background, in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// Data Structures
enum EncodingOperation: String, CaseIterable {
    case base64Encode = "base64_encode"
    case base64Decode = "base64_decode"
    case urlEncode = "url_encode"
    case urlDecode = "url_decode"
    case htmlEncode = "html_encode"
    case htmlDecode = "html_decode"
    case md5Hash = "md5_hash"
    case sha256Hash = "sha256_hash"
    case hexEncode = "hex_encode"
    case hexDecode = "hex_decode"
    
    var description: String {
        switch self {
        case .base64Encode: return "Encode text to Base64 format"
        case .base64Decode: return "Decode Base64 encoded text"
        case .urlEncode: return "Encode text for URL parameters"
        case .urlDecode: return "Decode URL encoded text"
        case .htmlEncode: return "Encode HTML special characters"
        case .htmlDecode: return "Decode HTML entities"
        case .md5Hash: return "Generate MD5 hash (128-bit)"
        case .sha256Hash: return "Generate SHA-256 hash (256-bit)"
        case .hexEncode: return "Encode text to hexadecimal"
        case .hexDecode: return "Decode hexadecimal to text"
        }
    }
    
    var icon: String {
        switch self {
        case .base64Encode, .base64Decode: return "arrow.up.arrow.down.circle"
        case .urlEncode, .urlDecode: return "link.circle"
        case .htmlEncode, .htmlDecode: return "doc.text"
        case .md5Hash, .sha256Hash: return "number.circle"
        case .hexEncode, .hexDecode: return "hexagon"
        }
    }
}

struct OperationHistory {
    let operation: EncodingOperation
    let input: String
    let output: String
    let timestamp: Date
}