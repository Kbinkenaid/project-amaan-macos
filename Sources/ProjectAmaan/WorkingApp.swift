import SwiftUI
import SecurityTools

@main
struct ProjectAmaanWorkingApp: App {
    var body: some Scene {
        WindowGroup {
            WorkingMainView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
    }
}

struct WorkingMainView: View {
    @State private var selectedTool: SecurityTool = .breachDetection
    
    enum SecurityTool: String, CaseIterable {
        case breachDetection = "Breach Detection"
        case networkTools = "Network Tools"
        case encodingTools = "Encoding Tools"
        case passwordTools = "Password Tools"
        case virusTotalTools = "VirusTotal"
        case settings = "Settings"
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "shield.checkered")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text("Project Amaan")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text("Cybersecurity Toolkit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                Divider()
                
                // Tool List
                List(SecurityTool.allCases, id: \.self, selection: $selectedTool) { tool in
                    HStack {
                        Image(systemName: iconForTool(tool))
                            .foregroundColor(colorForTool(tool))
                            .frame(width: 20)
                        
                        Text(tool.rawValue)
                            .font(.body)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .tag(tool)
                }
                .listStyle(SidebarListStyle())
                
                Spacer()
                
                // Status
                VStack(alignment: .leading, spacing: 4) {
                    Text("✅ Fully Functional")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("🛡️ Native macOS")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding()
            }
            .frame(minWidth: 200)
        } detail: {
            // Main Content - WORKING TOOLS
            Group {
                switch selectedTool {
                case .breachDetection:
                    WorkingBreachDetectionView()
                case .networkTools:
                    WorkingNetworkToolsView()
                case .encodingTools:
                    WorkingEncodingToolsView()
                case .passwordTools:
                    PasswordToolsView()
                case .virusTotalTools:
                    VirusTotalView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Project Amaan")
    }
    
    private func iconForTool(_ tool: SecurityTool) -> String {
        switch tool {
        case .breachDetection: return "shield.checkered"
        case .networkTools: return "network"
        case .encodingTools: return "chevron.left.forwardslash.chevron.right"
        case .passwordTools: return "key.fill"
        case .virusTotalTools: return "viruses"
        case .settings: return "gearshape.fill"
        }
    }

    private func colorForTool(_ tool: SecurityTool) -> Color {
        switch tool {
        case .breachDetection: return .blue
        case .networkTools: return .green
        case .encodingTools: return .orange
        case .passwordTools: return .purple
        case .virusTotalTools: return .red
        case .settings: return .gray
        }
    }
}