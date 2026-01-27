import SwiftUI
import Security

struct PasswordToolsView: View {
    @State private var passwordLength: Double = 16
    @State private var includeUppercase = true
    @State private var includeLowercase = true
    @State private var includeNumbers = true
    @State private var includeSymbols = true
    @State private var excludeSimilar = false
    @State private var generatedPassword = ""
    @State private var passwordHistory: [String] = []
    @State private var multiplePasswords: [String] = []
    @State private var showMultiple = false
    @State private var copyFeedback = false

    private let uppercaseChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    private let lowercaseChars = "abcdefghijklmnopqrstuvwxyz"
    private let numberChars = "0123456789"
    private let symbolChars = "!@#$%^&*()_+-=[]{}|;:,.<>?"
    private let similarChars = "0O1lI"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "key.fill")
                            .font(.title)
                            .foregroundColor(.purple)
                        Text("Password Generator")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    Text("Generate cryptographically secure passwords")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Configuration Section
                VStack(alignment: .leading, spacing: 16) {
                    // Length Slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Password Length")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(passwordLength)) characters")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $passwordLength, in: 8...128, step: 1)
                            .accentColor(.purple)
                    }

                    Divider()

                    // Character Options
                    Text("Character Sets")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $includeUppercase) {
                            HStack {
                                Text("Uppercase (A-Z)")
                                Spacer()
                                Text("ABCDEFGH...")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Toggle(isOn: $includeLowercase) {
                            HStack {
                                Text("Lowercase (a-z)")
                                Spacer()
                                Text("abcdefgh...")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Toggle(isOn: $includeNumbers) {
                            HStack {
                                Text("Numbers (0-9)")
                                Spacer()
                                Text("0123456789")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Toggle(isOn: $includeSymbols) {
                            HStack {
                                Text("Symbols")
                                Spacer()
                                Text("!@#$%^&*...")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Divider()

                        Toggle(isOn: $excludeSimilar) {
                            HStack {
                                Text("Exclude Similar Characters")
                                Spacer()
                                Text("0O, 1lI")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)

                // Generated Password Display
                VStack(alignment: .leading, spacing: 12) {
                    Text("Generated Password")
                        .font(.headline)

                    HStack {
                        Text(generatedPassword.isEmpty ? "Click Generate to create a password" : generatedPassword)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(generatedPassword.isEmpty ? .secondary : .primary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)

                        Button(action: copyPassword) {
                            Image(systemName: copyFeedback ? "checkmark" : "doc.on.doc")
                                .foregroundColor(copyFeedback ? .green : .blue)
                        }
                        .buttonStyle(.bordered)
                        .disabled(generatedPassword.isEmpty)
                        .help("Copy to clipboard")
                    }

                    // Strength Meter
                    if !generatedPassword.isEmpty {
                        PasswordStrengthMeter(password: generatedPassword)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)

                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: generatePassword) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Generate")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .disabled(!hasValidCharacterSet)

                    Button(action: generateMultiplePasswords) {
                        HStack {
                            Image(systemName: "square.stack.3d.up")
                            Text("Generate 5")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!hasValidCharacterSet)
                }

                // Multiple Passwords Section
                if showMultiple && !multiplePasswords.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Generated Passwords")
                                .font(.headline)
                            Spacer()
                            Button("Clear") {
                                showMultiple = false
                                multiplePasswords = []
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.red)
                        }

                        ForEach(multiplePasswords, id: \.self) { password in
                            HStack {
                                Text(password)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                                Spacer()
                                Button(action: { copyToClipboard(password) }) {
                                    Image(systemName: "doc.on.doc")
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(8)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(6)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }

                // Password History
                if !passwordHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Passwords")
                                .font(.headline)
                            Spacer()
                            Button("Clear History") {
                                passwordHistory = []
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.red)
                        }

                        ForEach(passwordHistory.prefix(10), id: \.self) { password in
                            HStack {
                                Text(password)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .textSelection(.enabled)
                                Spacer()
                                Button(action: { copyToClipboard(password) }) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }

                Spacer()
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var hasValidCharacterSet: Bool {
        includeUppercase || includeLowercase || includeNumbers || includeSymbols
    }

    private func buildCharacterSet() -> String {
        var chars = ""
        if includeUppercase { chars += uppercaseChars }
        if includeLowercase { chars += lowercaseChars }
        if includeNumbers { chars += numberChars }
        if includeSymbols { chars += symbolChars }

        if excludeSimilar {
            chars = String(chars.filter { !similarChars.contains($0) })
        }

        return chars
    }

    private func generateSecureRandomPassword(length: Int, characterSet: String) -> String {
        guard !characterSet.isEmpty else { return "" }

        let chars = Array(characterSet)
        var password = ""
        var randomBytes = [UInt8](repeating: 0, count: length)

        let status = SecRandomCopyBytes(kSecRandomDefault, length, &randomBytes)

        if status == errSecSuccess {
            for byte in randomBytes {
                let index = Int(byte) % chars.count
                password.append(chars[index])
            }
        }

        return password
    }

    private func generatePassword() {
        let charSet = buildCharacterSet()
        let newPassword = generateSecureRandomPassword(length: Int(passwordLength), characterSet: charSet)

        if !newPassword.isEmpty {
            // Add current password to history if it exists
            if !generatedPassword.isEmpty && !passwordHistory.contains(generatedPassword) {
                passwordHistory.insert(generatedPassword, at: 0)
                if passwordHistory.count > 10 {
                    passwordHistory = Array(passwordHistory.prefix(10))
                }
            }
            generatedPassword = newPassword
        }
    }

    private func generateMultiplePasswords() {
        let charSet = buildCharacterSet()
        multiplePasswords = (0..<5).compactMap { _ in
            generateSecureRandomPassword(length: Int(passwordLength), characterSet: charSet)
        }
        showMultiple = true
    }

    private func copyPassword() {
        copyToClipboard(generatedPassword)
        copyFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copyFeedback = false
        }
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

struct PasswordStrengthMeter: View {
    let password: String

    private var entropy: Double {
        guard !password.isEmpty else { return 0 }

        var charsetSize = 0
        let hasLower = password.contains(where: { $0.isLowercase })
        let hasUpper = password.contains(where: { $0.isUppercase })
        let hasDigit = password.contains(where: { $0.isNumber })
        let hasSymbol = password.contains(where: { !$0.isLetter && !$0.isNumber })

        if hasLower { charsetSize += 26 }
        if hasUpper { charsetSize += 26 }
        if hasDigit { charsetSize += 10 }
        if hasSymbol { charsetSize += 32 }

        guard charsetSize > 0 else { return 0 }

        return Double(password.count) * log2(Double(charsetSize))
    }

    private var strengthLevel: (String, Color, Double) {
        switch entropy {
        case 0..<28: return ("Very Weak", .red, 0.15)
        case 28..<36: return ("Weak", .orange, 0.30)
        case 36..<60: return ("Fair", .yellow, 0.50)
        case 60..<128: return ("Strong", .green, 0.75)
        default: return ("Very Strong", .blue, 1.0)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Strength:")
                    .font(.subheadline)
                Text(strengthLevel.0)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(strengthLevel.1)
                Spacer()
                Text("\(Int(entropy)) bits of entropy")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(strengthLevel.1)
                        .frame(width: geometry.size.width * strengthLevel.2, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
}
