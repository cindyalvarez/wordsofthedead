import SwiftUI
import UserNotifications

/// Settings UI for notification preferences.
struct NotificationSettingsView: View {
    @ObservedObject var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Notifications")
                    .font(.title2.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundStyle(.gray)
                }
            }
            .padding(20)
            .background(Color(white: 0.98))
            
            Divider()
            
            // Settings list
            List {
                // Main toggle
                Section {
                    Toggle("Enable Notifications", isOn: $notificationManager.isEnabled)
                        .onChange(of: notificationManager.isEnabled) { newValue in
                            if newValue {
                                notificationManager.requestPermissionIfNeeded()
                                notificationManager.scheduleDailyReminder()
                                notificationManager.scheduleWeeklySummary()
                            } else {
                                notificationManager.cancelAll()
                            }
                        }
                } footer: {
                    Text("Receive reminders to practice and celebrate your progress")
                }
                
                if notificationManager.isEnabled {
                    // Notification types
                    Section {
                        Toggle("Daily Reminder at 5 PM", isOn: $notificationManager.dailyReminderEnabled)
                            .onChange(of: notificationManager.dailyReminderEnabled) { newValue in
                                if newValue {
                                    notificationManager.scheduleDailyReminder()
                                } else {
                                    notificationManager.cancel(type: "daily")
                                }
                            }
                        
                        Toggle("Weekly Summary (Sunday 6 PM)", isOn: $notificationManager.weeklyUpdateEnabled)
                            .onChange(of: notificationManager.weeklyUpdateEnabled) { newValue in
                                if newValue {
                                    notificationManager.scheduleWeeklySummary()
                                } else {
                                    notificationManager.cancel(type: "weekly")
                                }
                            }
                        
                        Toggle("Milestone Achievements", isOn: $notificationManager.milestoneAlertEnabled)
                            .onChange(of: notificationManager.milestoneAlertEnabled) { newValue in
                                if !newValue {
                                    notificationManager.cancel(type: "milestone")
                                }
                            }
                    } header: {
                        Text("Notification Types")
                    }
                    
                    // Quiet hours
                    Section {
                        DatePicker(
                            "Start (default 9 PM)",
                            selection: $notificationManager.quietHoursStart,
                            displayedComponents: .hourAndMinute
                        )
                        
                        DatePicker(
                            "End (default 9 AM)",
                            selection: $notificationManager.quietHoursEnd,
                            displayedComponents: .hourAndMinute
                        )
                    } header: {
                        Text("Quiet Hours")
                    } footer: {
                        Text("No notifications will be sent during these hours")
                    }
                    
                    // Permission status
                    Section {
                        HStack {
                            Text("Notifications")
                            Spacer()
                            PermissionBadge(status: notificationManager.permissionStatus)
                        }
                    } header: {
                        Text("Permission Status")
                    } footer: {
                        Text(permissionFooterText())
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
    
    private func permissionFooterText() -> String {
        switch notificationManager.permissionStatus {
        case .authorized:
            return "Notifications are enabled in System Preferences. You will receive notifications."
        case .denied:
            return "Notifications are disabled in System Preferences. Open System Preferences > Notifications to enable."
        case .provisional:
            return "Notifications will appear quietly in Notification Center."
        case .ephemeral:
            return "Temporary notification permission."
        case .notDetermined:
            return "Request permission to enable notifications."
        @unknown default:
            return "Unknown permission status"
        }
    }
}

/// Visual badge showing permission status.
private struct PermissionBadge: View {
    let status: UNAuthorizationStatus
    
    var statusText: String {
        switch status {
        case .authorized:
            return "✅ Allowed"
        case .denied:
            return "❌ Denied"
        case .provisional:
            return "🔔 Provisional"
        case .ephemeral:
            return "⏱️ Temporary"
        case .notDetermined:
            return "⁉️ Not Set"
        @unknown default:
            return "Unknown"
        }
    }
    
    var statusColor: Color {
        switch status {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .provisional, .ephemeral:
            return .orange
        case .notDetermined:
            return .gray
        @unknown default:
            return .gray
        }
    }
    
    var body: some View {
        Text(statusText)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor)
            .cornerRadius(6)
    }
}

#Preview {
    NotificationSettingsView()
}
