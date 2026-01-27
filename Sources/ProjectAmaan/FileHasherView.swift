import SwiftUI
import CryptoKit
import UniformTypeIdentifiers

struct FileHasherView: View {
    @State private var selectedFileURL: URL?
    @State private var fileName: String?
    @State private var fileSize: String?
    @State private var isCalculating = false
    @State private var md5Hash: String?
    @State private var sha1Hash: String?
    @State private var sha256Hash: String?
    @State private var sha512Hash: String?
    @State private var verifyHash = ""
    @State private var verifyResult: VerifyResult?
    @State private var isDragging = false
    @State private var copyFeedback: String?

    enum VerifyResult {
        case match(String)
        case noMatch

        var description: String {
            switch self {
            case .match(let type): return "Match! (\(type))"
            case .noMatch: return "No match found"
            }
        }

        var color: Color {
            switch self {
            case .match: return .green
            case .noMatch: return .red
            }
        }

        var icon: String {
            switch self {
            case .match: return "checkmark.circle.fill"
            case .noMatch: return "xmark.circle.fill"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "number.circle.fill")
                            .font(.title)
                            .foregroundColor(.indigo)
                        Text("File Hasher")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    Text("Calculate and verify file integrity hashes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Drop Zone
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isDragging ? Color.indigo : Color.gray.opacity(0.5),
                                style: StrokeStyle(lineWidth: 2, dash: [8])
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isDragging ? Color.indigo.opacity(0.1) : Color.clear)
                            )

                        VStack(spacing: 12) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 48))
                                .foregroundColor(isDragging ? .indigo : .secondary)

                            Text("Drop file here")
                                .font(.headline)
                                .foregroundColor(isDragging ? .indigo : .secondary)

                            Text("or")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Button(action: selectFile) {
                                HStack {
                                    Image(systemName: "folder")
                                    Text("Choose File")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.indigo)
                        }
                        .padding(40)
                    }
                    .frame(height: 200)
                    .onDrop(of: [UTType.fileURL], isTargeted: $isDragging) { providers in
                        handleDrop(providers: providers)
                        return true
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)

                // File Info
                if let name = fileName, let size = fileSize {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.indigo)
                            Text("Selected File")
                                .font(.headline)
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(name)
                                    .font(.system(.body, design: .monospaced))
                                Text(size)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if isCalculating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }

                // Hash Results
                if md5Hash != nil || sha1Hash != nil || sha256Hash != nil || sha512Hash != nil {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Hash Results")
                            .font(.headline)

                        if let hash = md5Hash {
                            HashRow(name: "MD5", hash: hash, copyFeedback: $copyFeedback)
                        }

                        if let hash = sha1Hash {
                            HashRow(name: "SHA-1", hash: hash, copyFeedback: $copyFeedback)
                        }

                        if let hash = sha256Hash {
                            HashRow(name: "SHA-256", hash: hash, copyFeedback: $copyFeedback)
                        }

                        if let hash = sha512Hash {
                            HashRow(name: "SHA-512", hash: hash, copyFeedback: $copyFeedback)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)

                    // Verify Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Verify Hash")
                            .font(.headline)

                        Text("Paste a hash to verify file integrity")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            TextField("Enter hash to verify...", text: $verifyHash)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                                .onChange(of: verifyHash) { _, newValue in
                                    verifyHashMatch(newValue)
                                }

                            Button(action: { verifyHash = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .opacity(verifyHash.isEmpty ? 0 : 1)
                        }

                        if let result = verifyResult {
                            HStack {
                                Image(systemName: result.icon)
                                    .foregroundColor(result.color)
                                Text(result.description)
                                    .fontWeight(.medium)
                                    .foregroundColor(result.color)
                            }
                            .padding(8)
                            .background(result.color.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }

                // Info Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("About File Hashing")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(icon: "lock.fill", title: "MD5", description: "128-bit hash, fast but cryptographically broken")
                        InfoRow(icon: "lock.fill", title: "SHA-1", description: "160-bit hash, deprecated for security use")
                        InfoRow(icon: "lock.shield.fill", title: "SHA-256", description: "256-bit hash, recommended for integrity checks")
                        InfoRow(icon: "lock.shield.fill", title: "SHA-512", description: "512-bit hash, highest security level")
                    }
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

    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK {
            if let url = panel.url {
                processFile(url)
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

            DispatchQueue.main.async {
                processFile(url)
            }
        }
    }

    private func processFile(_ url: URL) {
        selectedFileURL = url
        fileName = url.lastPathComponent

        // Get file size
        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attributes[.size] as? Int64 {
            fileSize = formatFileSize(size)
        }

        // Clear previous results
        md5Hash = nil
        sha1Hash = nil
        sha256Hash = nil
        sha512Hash = nil
        verifyResult = nil

        // Calculate hashes
        calculateHashes(for: url)
    }

    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    private func calculateHashes(for url: URL) {
        isCalculating = true

        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = try? Data(contentsOf: url) else {
                DispatchQueue.main.async {
                    isCalculating = false
                }
                return
            }

            // Calculate all hashes
            let md5 = Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
            let sha1 = Insecure.SHA1.hash(data: data).map { String(format: "%02x", $0) }.joined()
            let sha256 = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            let sha512 = SHA512.hash(data: data).map { String(format: "%02x", $0) }.joined()

            DispatchQueue.main.async {
                md5Hash = md5
                sha1Hash = sha1
                sha256Hash = sha256
                sha512Hash = sha512
                isCalculating = false

                // Re-verify if there was a hash entered
                if !verifyHash.isEmpty {
                    verifyHashMatch(verifyHash)
                }
            }
        }
    }

    private func verifyHashMatch(_ input: String) {
        let cleanInput = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanInput.isEmpty else {
            verifyResult = nil
            return
        }

        if cleanInput == md5Hash?.lowercased() {
            verifyResult = .match("MD5")
        } else if cleanInput == sha1Hash?.lowercased() {
            verifyResult = .match("SHA-1")
        } else if cleanInput == sha256Hash?.lowercased() {
            verifyResult = .match("SHA-256")
        } else if cleanInput == sha512Hash?.lowercased() {
            verifyResult = .match("SHA-512")
        } else {
            verifyResult = .noMatch
        }
    }
}

struct HashRow: View {
    let name: String
    let hash: String
    @Binding var copyFeedback: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: copyHash) {
                    HStack(spacing: 4) {
                        Image(systemName: copyFeedback == name ? "checkmark" : "doc.on.doc")
                        Text("Copy")
                    }
                    .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(copyFeedback == name ? .green : .blue)
            }

            Text(hash)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
        }
    }

    private func copyHash() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(hash, forType: .string)
        copyFeedback = name
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if copyFeedback == name {
                copyFeedback = nil
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.indigo)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
