import SwiftUI
import Foundation

struct JWTDecoderView: View {
    @State private var jwtInput = ""
    @State private var decodedHeader: String?
    @State private var decodedPayload: String?
    @State private var signature: String?
    @State private var errorMessage: String?
    @State private var expirationStatus: ExpirationStatus?
    @State private var copyFeedback: String?

    enum ExpirationStatus {
        case valid(Date)
        case expired(Date)
        case noExpiration

        var description: String {
            switch self {
            case .valid(let date):
                return "Valid until \(formatDate(date))"
            case .expired(let date):
                return "Expired on \(formatDate(date))"
            case .noExpiration:
                return "No expiration set"
            }
        }

        var color: Color {
            switch self {
            case .valid: return .green
            case .expired: return .red
            case .noExpiration: return .orange
            }
        }

        var icon: String {
            switch self {
            case .valid: return "checkmark.circle.fill"
            case .expired: return "xmark.circle.fill"
            case .noExpiration: return "questionmark.circle.fill"
            }
        }

        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .medium
            return formatter.string(from: date)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "ticket.fill")
                            .font(.title)
                            .foregroundColor(.cyan)
                        Text("JWT Decoder")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    Text("Decode and inspect JSON Web Tokens")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Input Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Paste JWT Token")
                        .font(.headline)

                    TextEditor(text: $jwtInput)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )

                    HStack {
                        Button(action: decodeJWT) {
                            HStack {
                                Image(systemName: "key.viewfinder")
                                Text("Decode")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                        .disabled(jwtInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Button(action: clearAll) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear")
                            }
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Button(action: pasteFromClipboard) {
                            HStack {
                                Image(systemName: "doc.on.clipboard")
                                Text("Paste")
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)

                // Error Message
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }

                // Expiration Status
                if let status = expirationStatus {
                    HStack {
                        Image(systemName: status.icon)
                            .foregroundColor(status.color)
                        Text(status.description)
                            .fontWeight(.medium)
                            .foregroundColor(status.color)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(status.color.opacity(0.1))
                    .cornerRadius(8)
                }

                // Decoded Sections
                if decodedHeader != nil || decodedPayload != nil || signature != nil {
                    VStack(spacing: 16) {
                        // Header Section
                        if let header = decodedHeader {
                            DecodedSection(
                                title: "HEADER",
                                content: header,
                                color: .red,
                                copyFeedback: $copyFeedback
                            )
                        }

                        // Payload Section
                        if let payload = decodedPayload {
                            DecodedSection(
                                title: "PAYLOAD",
                                content: payload,
                                color: .purple,
                                copyFeedback: $copyFeedback
                            )
                        }

                        // Signature Section
                        if let sig = signature {
                            DecodedSection(
                                title: "SIGNATURE",
                                content: sig,
                                color: .cyan,
                                copyFeedback: $copyFeedback
                            )
                        }
                    }
                }

                // JWT Structure Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("JWT Structure")
                        .font(.headline)

                    HStack(spacing: 4) {
                        Text("header")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(4)
                        Text(".")
                            .foregroundColor(.secondary)
                        Text("payload")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.2))
                            .cornerRadius(4)
                        Text(".")
                            .foregroundColor(.secondary)
                        Text("signature")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.cyan.opacity(0.2))
                            .cornerRadius(4)
                    }
                    .font(.system(.caption, design: .monospaced))

                    Text("JWTs are Base64URL encoded. This tool decodes and pretty-prints the header and payload JSON.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)

                Spacer()
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func decodeJWT() {
        let token = jwtInput.trimmingCharacters(in: .whitespacesAndNewlines)
        errorMessage = nil
        expirationStatus = nil

        let parts = token.split(separator: ".")
        guard parts.count == 3 else {
            errorMessage = "Invalid JWT format. Expected 3 parts separated by dots."
            decodedHeader = nil
            decodedPayload = nil
            signature = nil
            return
        }

        // Decode Header
        if let headerData = base64URLDecode(String(parts[0])),
           let headerJSON = try? JSONSerialization.jsonObject(with: headerData),
           let prettyHeader = try? JSONSerialization.data(withJSONObject: headerJSON, options: .prettyPrinted),
           let headerString = String(data: prettyHeader, encoding: .utf8) {
            decodedHeader = headerString
        } else {
            errorMessage = "Failed to decode header"
            decodedHeader = nil
        }

        // Decode Payload
        if let payloadData = base64URLDecode(String(parts[1])),
           let payloadJSON = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] {

            // Check expiration
            if let exp = payloadJSON["exp"] as? TimeInterval {
                let expDate = Date(timeIntervalSince1970: exp)
                if expDate > Date() {
                    expirationStatus = .valid(expDate)
                } else {
                    expirationStatus = .expired(expDate)
                }
            } else {
                expirationStatus = .noExpiration
            }

            // Format payload with timestamp annotations
            let annotatedPayload = annotateTimestamps(payloadJSON)
            if let prettyPayload = try? JSONSerialization.data(withJSONObject: annotatedPayload, options: .prettyPrinted),
               let payloadString = String(data: prettyPayload, encoding: .utf8) {
                decodedPayload = payloadString
            }
        } else {
            errorMessage = "Failed to decode payload"
            decodedPayload = nil
        }

        // Signature (just show as-is, it's Base64URL encoded)
        signature = String(parts[2])
    }

    private func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Add padding if needed
        let paddingLength = (4 - base64.count % 4) % 4
        base64 += String(repeating: "=", count: paddingLength)

        return Data(base64Encoded: base64)
    }

    private func annotateTimestamps(_ payload: [String: Any]) -> [String: Any] {
        var annotated = payload
        let timestampKeys = ["iat", "exp", "nbf", "auth_time"]
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium

        for key in timestampKeys {
            if let timestamp = payload[key] as? TimeInterval {
                let date = Date(timeIntervalSince1970: timestamp)
                annotated[key] = "\(Int(timestamp)) (\(formatter.string(from: date)))"
            }
        }

        return annotated
    }

    private func clearAll() {
        jwtInput = ""
        decodedHeader = nil
        decodedPayload = nil
        signature = nil
        errorMessage = nil
        expirationStatus = nil
    }

    private func pasteFromClipboard() {
        if let string = NSPasteboard.general.string(forType: .string) {
            jwtInput = string
        }
    }
}

struct DecodedSection: View {
    let title: String
    let content: String
    let color: Color
    @Binding var copyFeedback: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)

                Spacer()

                Button(action: copyContent) {
                    HStack(spacing: 4) {
                        Image(systemName: copyFeedback == title ? "checkmark" : "doc.on.doc")
                        Text("Copy")
                    }
                    .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(copyFeedback == title ? .green : .blue)
            }

            Text(content)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.3), lineWidth: 2)
                )
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private func copyContent() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
        copyFeedback = title
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if copyFeedback == title {
                copyFeedback = nil
            }
        }
    }
}
