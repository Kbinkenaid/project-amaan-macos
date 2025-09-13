import SwiftUI
import SecurityTools

struct RealBreachCard: View {
    let breach: Breach
    
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