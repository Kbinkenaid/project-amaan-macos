import SwiftUI
import SecurityTools
import UniformTypeIdentifiers

struct VirusTotalView: View {
    @StateObject private var manager = VirusTotalManager()
    @StateObject private var apiKeyManager = APIKeyManager()
    @State private var selectedTab = 0
    @State private var urlInput = ""
    @State private var hashInput = ""
    @State private var isScanning = false
    @State private var errorMessage: String?
    @State private var selectedFileURL: URL?
    @State private var isDragging = false
    @State private var showAllEngines = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "shield.checkerboard")
                            .font(.title)
                            .foregroundColor(.red)
                        Text("VirusTotal Scanner")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    Text("Scan URLs, domains, and files for security threats")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // API Key Check
                if !apiKeyManager.hasAPIKey(for: .virustotal) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("VirusTotal API key required. Configure in Settings.")
                            .foregroundColor(.orange)
                        Spacer()
                        Button("Go to Settings") {
                            // This would need navigation handling
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }

                Divider()

                // Tab Selector
                Picker("Scanner Type", selection: $selectedTab) {
                    Text("URL Scanner").tag(0)
                    Text("File Scanner").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Tab Content
                if selectedTab == 0 {
                    urlScannerView
                } else {
                    fileScannerView
                }

                Spacer()
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - URL Scanner View

    private var urlScannerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Input Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Enter URL or Domain")
                    .font(.headline)

                HStack {
                    TextField("https://example.com or example.com", text: $urlInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))

                    Button(action: scanURL) {
                        HStack {
                            if isScanning {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "magnifyingglass")
                            }
                            Text("Scan")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isScanning || !apiKeyManager.hasAPIKey(for: .virustotal))
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

            // URL Results
            if let result = manager.lastURLResult {
                urlResultView(result)
            }
        }
    }

    private func urlResultView(_ result: VTURLResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Summary Card
            VStack(spacing: 12) {
                threatLevelBadge(result.threatLevel, positives: result.positives, total: result.total)

                Text(result.url)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text("Scanned: \(formatDate(result.scanDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(threatBackgroundColor(result.threatLevel))
            .cornerRadius(12)

            // Categories
            if !result.categories.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Categories")
                        .font(.headline)

                    FlowLayout(spacing: 8) {
                        ForEach(result.categories, id: \.self) { category in
                            Text(category)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }

            // Engine Results
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Engine Results")
                        .font(.headline)
                    Spacer()
                    Button(showAllEngines ? "Show Less" : "Show All \(result.engines.count)") {
                        showAllEngines.toggle()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                }

                let detectedEngines = result.engines.filter { $0.detected }
                let cleanEngines = result.engines.filter { !$0.detected }

                // Show detected first
                ForEach(detectedEngines.prefix(showAllEngines ? detectedEngines.count : 10), id: \.name) { engine in
                    engineRow(engine)
                }

                // Show clean engines if expanded
                if showAllEngines {
                    ForEach(cleanEngines, id: \.name) { engine in
                        engineRow(engine)
                    }
                } else if detectedEngines.isEmpty {
                    ForEach(cleanEngines.prefix(5), id: \.name) { engine in
                        engineRow(engine)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
    }

    // MARK: - File Scanner View

    private var fileScannerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Hash Lookup Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Lookup by Hash")
                    .font(.headline)

                Text("Check if a file hash exists in VirusTotal's database")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    TextField("Enter MD5, SHA-1, or SHA-256 hash", text: $hashInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))

                    Button(action: lookupHash) {
                        HStack {
                            if isScanning {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "magnifyingglass")
                            }
                            Text("Lookup")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(hashInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isScanning || !apiKeyManager.hasAPIKey(for: .virustotal))
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

            // File Upload Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Upload File for Scanning")
                    .font(.headline)

                Text("Upload a file to scan (max 32MB)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isDragging ? Color.red : Color.gray.opacity(0.5),
                            style: StrokeStyle(lineWidth: 2, dash: [8])
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isDragging ? Color.red.opacity(0.1) : Color.clear)
                        )

                    VStack(spacing: 12) {
                        Image(systemName: "doc.badge.arrow.up")
                            .font(.system(size: 36))
                            .foregroundColor(isDragging ? .red : .secondary)

                        Text("Drop file here")
                            .font(.subheadline)
                            .foregroundColor(isDragging ? .red : .secondary)

                        Text("or")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button(action: selectFile) {
                            HStack {
                                Image(systemName: "folder")
                                Text("Choose File")
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(!apiKeyManager.hasAPIKey(for: .virustotal))
                    }
                    .padding(30)
                }
                .frame(height: 160)
                .onDrop(of: [UTType.fileURL], isTargeted: $isDragging) { providers in
                    handleFileDrop(providers: providers)
                    return true
                }

                if let fileURL = selectedFileURL {
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundColor(.red)
                        Text(fileURL.lastPathComponent)
                            .font(.system(.body, design: .monospaced))
                        Spacer()

                        Button(action: scanFile) {
                            HStack {
                                if isScanning {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "arrow.up.circle")
                                }
                                Text("Scan File")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(isScanning)
                    }
                    .padding()
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
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

            // File Results
            if let result = manager.lastFileResult {
                fileResultView(result)
            }
        }
    }

    private func fileResultView(_ result: VTFileResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Summary Card
            VStack(spacing: 12) {
                threatLevelBadge(result.threatLevel, positives: result.positives, total: result.total)

                VStack(spacing: 4) {
                    Text(result.fileName)
                        .font(.headline)

                    if !result.fileHash.isEmpty {
                        Text(result.fileHash)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    if result.fileSize > 0 {
                        Text(result.formattedSize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Text("Scanned: \(formatDate(result.scanDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(threatBackgroundColor(result.threatLevel))
            .cornerRadius(12)

            // Detections
            if !result.detections.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Detections (\(result.detections.count))")
                        .font(.headline)

                    ForEach(result.detections, id: \.engine) { detection in
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(detection.engine)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(detection.malwareType)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }

                            Spacer()
                        }
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            } else if result.total > 0 {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    Text("No threats detected by any security vendor")
                        .foregroundColor(.green)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Helper Views

    private func threatLevelBadge(_ level: ThreatLevel, positives: Int, total: Int) -> some View {
        VStack(spacing: 8) {
            Image(systemName: threatIcon(level))
                .font(.system(size: 48))
                .foregroundColor(threatColor(level))

            Text(level.description.uppercased())
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(threatColor(level))

            Text("\(positives)/\(total) security vendors flagged this")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func engineRow(_ engine: VTEngine) -> some View {
        HStack {
            Image(systemName: engine.detected ? "xmark.circle.fill" : "checkmark.circle.fill")
                .foregroundColor(engine.detected ? .red : .green)

            Text(engine.name)
                .font(.subheadline)

            Spacer()

            if let result = engine.result, engine.detected {
                Text(result)
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                Text(engine.detected ? "Detected" : "Clean")
                    .font(.caption)
                    .foregroundColor(engine.detected ? .red : .green)
            }
        }
        .padding(.vertical, 4)
    }

    private func threatIcon(_ level: ThreatLevel) -> String {
        switch level {
        case .clean: return "checkmark.shield.fill"
        case .low: return "exclamationmark.shield.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "xmark.shield.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    private func threatColor(_ level: ThreatLevel) -> Color {
        switch level {
        case .clean: return .green
        case .low: return .yellow
        case .medium: return .orange
        case .high: return .red
        case .unknown: return .gray
        }
    }

    private func threatBackgroundColor(_ level: ThreatLevel) -> Color {
        threatColor(level).opacity(0.1)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Actions

    private func scanURL() {
        let input = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }

        isScanning = true
        errorMessage = nil

        Task {
            let result: SecurityResult<VTURLResult>

            // Check if it's a domain or URL
            if input.contains("://") {
                result = await manager.scanURL(input)
            } else {
                result = await manager.getDomainReport(input)
            }

            await MainActor.run {
                isScanning = false
                if let error = result.error {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func lookupHash() {
        let hash = hashInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !hash.isEmpty else { return }

        isScanning = true
        errorMessage = nil

        Task {
            let result = await manager.getFileReport(hash: hash)

            await MainActor.run {
                isScanning = false
                if let error = result.error {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK {
            selectedFileURL = panel.url
        }
    }

    private func handleFileDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

            DispatchQueue.main.async {
                selectedFileURL = url
            }
        }
    }

    private func scanFile() {
        guard let fileURL = selectedFileURL else { return }

        isScanning = true
        errorMessage = nil

        Task {
            let result = await manager.scanFile(fileURL)

            await MainActor.run {
                isScanning = false
                if let error = result.error {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Flow Layout for Categories

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: width, height: y + rowHeight)
        }
    }
}
