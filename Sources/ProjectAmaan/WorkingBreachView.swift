import SwiftUI
import Foundation
import SecurityTools

struct WorkingBreachDetectionView: View {
    @StateObject private var breachManager = BreachDetectionManager()
    @State private var emailInput = ""
    @State private var domainInput = ""
    @State private var selectedMode: QueryMode = .email
    @State private var errorMessage = ""
    @State private var showResults = false
    
    enum QueryMode: String, CaseIterable {
        case email = "Email"
        case domain = "Domain"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("🔍 Breach Detection")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Check if email addresses or domains have been compromised in data breaches using the HaveIBeenPwned database.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                // Input Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Query Type")
                        .font(.headline)
                    
                    Picker("Query Type", selection: $selectedMode) {
                        ForEach(QueryMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedMode == .email ? "Email Address:" : "Domain Name:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField(
                            selectedMode == .email ? "Enter email address" : "Enter domain name",
                            text: selectedMode == .email ? $emailInput : $domainInput
                        )
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(.body, design: .monospaced))
                        
                        if selectedMode == .email && !emailInput.isEmpty && !isValidEmail(emailInput) {
                            Label("Invalid email format", systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Button(action: performBreachCheck) {
                        HStack {
                            if breachManager.isChecking {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(breachManager.isChecking ? "Checking..." : "Check for Breaches")
                        }
                        .frame(minWidth: 120)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(breachManager.isChecking || (selectedMode == .email ? emailInput.isEmpty : domainInput.isEmpty))
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                // Results Section
                if showResults {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Results")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button("Clear") {
                                clearResults()
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if !errorMessage.isEmpty {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .padding()
                                .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        } else if let result = breachManager.lastResult {
                            if result.isBreached {
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("⚠️ Found \(result.breaches.count) breach(es)", systemImage: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    LazyVStack(spacing: 12) {
                                        ForEach(result.breaches.prefix(5), id: \.name) { breach in
                                            RealBreachCard(breach: breach)
                                        }
                                    }
                                }
                            } else {
                                Label("✅ No breaches found - this is good news!", systemImage: "checkmark.shield.fill")
                                    .foregroundColor(.green)
                                    .padding()
                                    .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                            }
                        } else if !breachManager.isChecking && showResults {
                            Label("No breaches found - this is good news!", systemImage: "checkmark.shield.fill")
                                .foregroundColor(.green)
                                .padding()
                                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                
                // Info Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("ℹ️ About Breach Detection")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• This tool checks against the HaveIBeenPwned database")
                        Text("• Data breaches are incidents where sensitive data is accessed")
                        Text("• If your email appears, consider changing passwords")
                        Text("• Use unique passwords for each service")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }
    
    private func performBreachCheck() {
        let query = selectedMode == .email ? emailInput : domainInput
        
        guard !query.isEmpty else { return }
        
        errorMessage = ""
        showResults = true
        
        Task {
            let result = selectedMode == .email ? 
                await breachManager.checkEmail(query) :
                await breachManager.checkDomain(query)
            
            DispatchQueue.main.async {
                if !result.isSuccess {
                    self.errorMessage = result.error?.localizedDescription ?? "Unknown error occurred"
                }
            }
        }
    }
    
    private func clearResults() {
        breachManager.lastResult = nil
        errorMessage = ""
        showResults = false
        emailInput = ""
        domainInput = ""
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
}

struct BreachCard: View {
    let breach: BreachInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(breach.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Breach Date: \(formatDate(breach.breachDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(breach.description)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            
            if !breach.dataClasses.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Compromised Data:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 120))
                    ], alignment: .leading, spacing: 4) {
                        ForEach(breach.dataClasses, id: \.self) { dataClass in
                            Text(dataClass)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            HStack {
                Text("Affected accounts: \(breach.pwnCount.formatted())")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Domain: \(breach.domain)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.red.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.red.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return dateString
    }
}

struct BreachInfo {
    let name: String
    let title: String
    let domain: String
    let breachDate: String
    let addedDate: String
    let modifiedDate: String
    let pwnCount: Int
    let description: String
    let dataClasses: [String]
}

#Preview {
    WorkingBreachDetectionView()
}