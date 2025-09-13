import SwiftUI

struct RealPortResultRow: View {
    let port: Int
    let service: String
    
    var body: some View {
        HStack {
            Text("\(port)")
                .font(.system(.body, design: .monospaced))
                .frame(width: 60, alignment: .leading)
            
            Text(service)
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

func getServiceName(for port: Int) -> String {
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