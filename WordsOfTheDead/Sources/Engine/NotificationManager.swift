import Foundation
import UserNotifications

/// Manages all macOS notifications: daily reminders, weekly summaries, milestone alerts.
/// Respects Do Not Disturb settings and user preferences.
@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    // MARK: - Settings
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "notif_enabled") }
    }
    
    @Published var dailyReminderEnabled: Bool {
        didSet { UserDefaults.standard.set(dailyReminderEnabled, forKey: "notif_daily") }
    }
    
    @Published var weeklyUpdateEnabled: Bool {
        didSet { UserDefaults.standard.set(weeklyUpdateEnabled, forKey: "notif_weekly") }
    }
    
    @Published var milestoneAlertEnabled: Bool {
        didSet { UserDefaults.standard.set(milestoneAlertEnabled, forKey: "notif_milestone") }
    }
    
    @Published var quietHoursStart: Date {
        didSet { UserDefaults.standard.set(quietHoursStart, forKey: "notif_quiet_start") }
    }
    
    @Published var quietHoursEnd: Date {
        didSet { UserDefaults.standard.set(quietHoursEnd, forKey: "notif_quiet_end") }
    }
    
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - Initialization
    private init() {
        // Load settings from UserDefaults
        self.isEnabled = UserDefaults.standard.bool(forKey: "notif_enabled")
        self.dailyReminderEnabled = UserDefaults.standard.bool(forKey: "notif_daily")
        self.weeklyUpdateEnabled = UserDefaults.standard.bool(forKey: "notif_weekly")
        self.milestoneAlertEnabled = UserDefaults.standard.bool(forKey: "notif_milestone")
        
        // Load quiet hours (default 9 PM - 9 AM)
        if let savedStart = UserDefaults.standard.object(forKey: "notif_quiet_start") as? Date {
            self.quietHoursStart = savedStart
        } else {
            var components = DateComponents()
            components.hour = 21
            components.minute = 0
            self.quietHoursStart = Calendar.current.date(from: components) ?? Date()
        }
        
        if let savedEnd = UserDefaults.standard.object(forKey: "notif_quiet_end") as? Date {
            self.quietHoursEnd = savedEnd
        } else {
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            self.quietHoursEnd = Calendar.current.date(from: components) ?? Date()
        }
        
        // Defer permission request to avoid blocking during app startup
        // The permission will be checked and requested when needed
        Task {
            await self.checkPermissionStatus()
        }
    }
    
    // MARK: - Permission Management
    private func checkPermissionStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        await MainActor.run {
            self.permissionStatus = settings.authorizationStatus
        }
    }
    
    func requestPermissionIfNeeded() {
        Task {
            let center = UNUserNotificationCenter.current()
            let current = await center.notificationSettings()
            await MainActor.run {
                self.permissionStatus = current.authorizationStatus
            }
            
            // Request if not yet determined
            if current.authorizationStatus == .notDetermined {
                do {
                    let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                    let updated = await center.notificationSettings()
                    await MainActor.run {
                        self.permissionStatus = updated.authorizationStatus
                        if granted {
                            self.isEnabled = true
                        }
                    }
                } catch {
                    print("[Notifications] Permission request failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Notification Scheduling
    
    /// Schedule daily reminder at 5 PM if goal not yet met today.
    func scheduleDailyReminder() {
        guard isEnabled, dailyReminderEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📚 Time to Practice"
        content.body = "Complete your daily word goal and keep your streak alive!"
        content.sound = .default
        content.badge = NSNumber(value: 1)
        content.userInfo = ["type": "daily_reminder"]
        
        // Schedule for 5 PM today
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        dateComponents.hour = 17
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[Notifications] Failed to schedule daily reminder: \(error)")
            } else {
                print("[Notifications] Daily reminder scheduled for 5 PM")
            }
        }
    }
    
    /// Schedule weekly summary notification for Sunday 6 PM.
    func scheduleWeeklySummary() {
        guard isEnabled, weeklyUpdateEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📊 Weekly Summary"
        content.body = "Check your weekly progress and see how your streak is growing!"
        content.sound = .default
        content.badge = NSNumber(value: 1)
        content.userInfo = ["type": "weekly_summary"]
        
        // Schedule for Sunday at 6 PM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1  // Sunday
        dateComponents.hour = 18
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_summary", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[Notifications] Failed to schedule weekly summary: \(error)")
            } else {
                print("[Notifications] Weekly summary scheduled for Sunday 6 PM")
            }
        }
    }
    
    /// Send immediate notification on milestone achievement (e.g., 7-day streak).
    func notifyMilestoneReached(_ milestone: Int) {
        guard isEnabled, milestoneAlertEnabled else { return }
        guard !isInQuietHours() else {
            print("[Notifications] Milestone \(milestone) reached but in quiet hours")
            return
        }
        
        let badges: [Int: String] = [
            7: "🔥 Week Warrior!",
            14: "⚡ Fortnight Master!",
            30: "👑 Month Champion!",
            60: "💎 Season King!",
            100: "🌟 Century Collector!"
        ]
        
        let badge = badges[milestone] ?? "🎉 Milestone Reached!"
        
        let content = UNMutableNotificationContent()
        content.title = badge
        content.body = "Congratulations on reaching a \(milestone)-day streak! You're unstoppable!"
        content.sound = .default
        content.userInfo = ["type": "milestone", "days": milestone]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "milestone_\(milestone)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[Notifications] Failed to send milestone notification: \(error)")
            } else {
                print("[Notifications] Milestone \(milestone) notification sent")
            }
        }
    }
    
    /// Send notification when streak is at risk (< 25% daily progress).
    func notifyStreakAtRisk() {
        guard isEnabled else { return }
        guard !isInQuietHours() else {
            print("[Notifications] Streak at risk alert suppressed (quiet hours)")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Streak at Risk!"
        content.body = "You've only practiced a few words today. Come back and complete your goal before midnight!"
        content.sound = .default
        content.userInfo = ["type": "streak_at_risk"]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "streak_at_risk_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[Notifications] Failed to send streak at risk alert: \(error)")
            } else {
                print("[Notifications] Streak at risk alert sent")
            }
        }
    }
    
    // MARK: - Do Not Disturb Handling
    
    /// Check if current time is within quiet hours (default 9 PM - 9 AM).
    private func isInQuietHours() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        let startComponents = calendar.dateComponents([.hour, .minute], from: quietHoursStart)
        let endComponents = calendar.dateComponents([.hour, .minute], from: quietHoursEnd)
        
        let nowMinutes = (nowComponents.hour ?? 0) * 60 + (nowComponents.minute ?? 0)
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
        
        // Handle overnight quiet hours (e.g., 9 PM to 9 AM)
        if startMinutes > endMinutes {
            return nowMinutes >= startMinutes || nowMinutes < endMinutes
        } else {
            return nowMinutes >= startMinutes && nowMinutes < endMinutes
        }
    }
    
    // MARK: - Cleanup
    
    /// Cancel all scheduled notifications.
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("[Notifications] All notifications cancelled")
    }
    
    /// Cancel specific notification by type.
    func cancel(type: String) {
        var identifiers: [String] = []
        switch type {
        case "daily":
            identifiers = ["daily_reminder"]
        case "weekly":
            identifiers = ["weekly_summary"]
        case "milestone":
            identifiers = (7...100).map { "milestone_\($0)" }
        default:
            break
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
