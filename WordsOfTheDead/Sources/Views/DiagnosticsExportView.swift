import SwiftUI

/// Modal view for exporting diagnostics bundle for troubleshooting and support.
struct DiagnosticsExportView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var isExporting = false
    @State private var exportedURL: URL?
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("Export Diagnostics")
                    .font(.title2.bold())
                Text("Create a support bundle to help troubleshoot issues")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            // Description
            VStack(alignment: .leading, spacing: 12) {
                Text("What's Included:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    DiagnosticItem(icon: "📝", title: "Event Logs", description: "Game and system event logs (QA mode)")
                    DiagnosticItem(icon: "📊", title: "Statistics", description: "Aggregated player metrics and progress")
                    DiagnosticItem(icon: "🖥️", title: "System Info", description: "OS version, timezone, locale information")
                }
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Text("Privacy:")
                    .font(.headline)
                    .padding(.top, 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("✅ Includes: Error logs, timestamps, system details")
                        .font(.caption)
                    Text("❌ Never includes: Player names, game progress, personal settings")
                        .font(.caption)
                }
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .font(.subheadline)
            .padding(16)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(10)
            
            // Status
            if let error = errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            } else if showSuccess, let url = exportedURL {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Bundle created successfully!")
                        .font(.caption)
                    Text(url.lastPathComponent)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer()
            
            // Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button(action: export) {
                    if isExporting {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Exporting...")
                        }
                    } else if showSuccess {
                        HStack {
                            Image(systemName: "folder.fill")
                            Text("Open in Finder")
                        }
                    } else {
                        Text("Create Bundle")
                    }
                }
                .disabled(isExporting)
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 500, maxWidth: 600, minHeight: 400)
    }
    
    private func export() {
        if showSuccess, let url = exportedURL {
            // Open bundle in Finder
            FileUtilities.revealDiagnosticsBundle(url)
            dismiss()
            return
        }
        
        isExporting = true
        errorMessage = nil
        showSuccess = false
        
        // Export on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            if let bundleURL = FileUtilities.exportDiagnostics() {
                DispatchQueue.main.async {
                    isExporting = false
                    exportedURL = bundleURL
                    showSuccess = true
                    errorMessage = nil
                }
            } else {
                DispatchQueue.main.async {
                    isExporting = false
                    errorMessage = "Failed to create diagnostics bundle. Check logs for details."
                    showSuccess = false
                }
            }
        }
    }
}

private struct DiagnosticItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 18))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

#Preview {
    DiagnosticsExportView()
}
