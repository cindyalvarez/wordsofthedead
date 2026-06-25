# NotificationManager Implementation Guide

**Status**: ✅ Complete and integrated

## Overview

NotificationManager is a singleton service that manages all macOS notifications for Words of the Dead, including daily reminders, weekly summaries, milestone alerts, and streak-at-risk warnings. It respects quiet hours (default 9 PM - 9 AM) and user preferences stored in UserDefaults.

## Architecture

### NotificationManager.swift (500+ lines)

**Key Classes**:
- `NotificationManager`: Singleton managing all notification scheduling, permissions, and user settings

**Key Properties**:
```swift
// Settings (persisted to UserDefaults)
@Published var isEnabled: Bool                    // Master toggle
@Published var dailyReminderEnabled: Bool          // 5 PM reminders
@Published var weeklyUpdateEnabled: Bool           // Sunday 6 PM summary
@Published var milestoneAlertEnabled: Bool         // Milestone notifications
@Published var quietHoursStart: Date               // Default: 9 PM
@Published var quietHoursEnd: Date                 // Default: 9 AM
@Published var permissionStatus: UNAuthorizationStatus
```

## Features Implemented

### 1. Daily Reminder Notifications
**Time**: 5 PM daily (if not met)
**Content**: "📚 Time to Practice" with motivational message
**Scope**: Only sent if `dailyReminderEnabled` is true and notifications are enabled
**Setup**: `scheduleDailyReminder()`

### 2. Weekly Summary Notifications
**Time**: Sunday 6 PM (recurring)
**Content**: "📊 Weekly Summary" encouraging users to review progress
**Scope**: Only sent if `weeklyUpdateEnabled` is true
**Setup**: `scheduleWeeklySummary()`

### 3. Milestone Achievement Alerts
**Trigger**: When streak reaches 7, 14, 30, 60, 100 days
**Content**: Achievement badge with encouraging message (e.g., "🔥 Week Warrior!")
**Timing**: Immediate notification (subject to quiet hours)
**Method**: `notifyMilestoneReached(Int)`

### 4. Streak-at-Risk Warnings
**Trigger**: User has practiced < 25% of daily goal but > 0
**Content**: "⚠️ Streak at Risk!" with urgency message
**Timing**: Immediate (subject to quiet hours)
**Method**: `notifyStreakAtRisk()`

### 5. Quiet Hours
**Default**: 9 PM - 9 AM (prevents nighttime notifications)
**Customizable**: Users can adjust via NotificationSettingsView
**Scope**: All notifications respect quiet hours except immediate alerts on quiet hour start
**Logic**: Checks time range before sending any alert

## User Preferences UI

### NotificationSettingsView.swift

A clean settings interface with:
- **Master toggle** to enable/disable all notifications
- **Type-specific toggles**:
  - Daily Reminder at 5 PM
  - Weekly Summary (Sunday 6 PM)
  - Milestone Achievements
- **Quiet hours configuration** (time pickers)
- **Permission status indicator** showing:
  - ✅ Allowed (green)
  - ❌ Denied (red)
  - 🔔 Provisional (orange)
  - ⏱️ Temporary (orange)
  - ⁉️ Not Set (gray)
- **Footer text** explaining permission requirements

### Integration
- Accessed via gear icon in OpeningScreenView
- Settings persisted in UserDefaults
- Changes take effect immediately

## Data Flow

```
User Opens App
├─ WordsOfTheDeadApp initializes NotificationManager
├─ NotificationManager.requestPermissionIfNeeded() 
│  └─ Asks user for notification permission (first launch)
└─ Load saved settings from UserDefaults

Player Selects "Daily Reminder" Setting
├─ Toggle sets dailyReminderEnabled = true
├─ onChange triggers scheduleDailyReminder()
└─ UNUserNotificationCenter schedules recurring notification at 5 PM

Player Completes Game Session
├─ GameEngine.endGame() calls updateMetrics()
├─ Checks if streak reached milestone (7, 14, 30, 60, 100)
│  └─ Calls NotificationManager.notifyMilestoneReached(milestone)
├─ Checks if streak at risk (< 25% progress)
│  └─ Calls NotificationManager.notifyStreakAtRisk()
└─ Both respect quiet hours via isInQuietHours()

5 PM Daily Reminder Trigger
├─ macOS delivers notification if:
│  ├─ isEnabled = true
│  ├─ dailyReminderEnabled = true
│  ├─ Not in quiet hours
│  └─ Notification permission granted
└─ User sees "📚 Time to Practice" with message

Sunday 6 PM Weekly Summary
├─ macOS delivers notification
├─ Contains weekly progress summary
└─ Encourages user to view stats
```

## Permission Handling

### Request Flow
1. **First Launch**: `requestPermissionIfNeeded()` called on app init
2. **User Grants Permission**: `permissionStatus` set to `.authorized`, `isEnabled` set to true
3. **User Denies Permission**: `permissionStatus` set to `.denied`, notifications disabled
4. **Manual Permission Change**: Check permission status in NotificationSettingsView
5. **Provisional Alerts**: If user hasn't responded, still deliver quietly to Notification Center

### UserDefaults Keys
```
notif_enabled            → Master toggle
notif_daily              → Daily reminder toggle
notif_weekly             → Weekly summary toggle
notif_milestone          → Milestone toggle
notif_quiet_start        → Quiet hours start time (Date)
notif_quiet_end          → Quiet hours end time (Date)
```

## Quiet Hours Implementation

### Logic
```swift
isInQuietHours() -> Bool {
    // Get current time components
    let nowMinutes = (hour * 60) + minute
    let startMinutes = (startHour * 60) + startMinute
    let endMinutes = (endHour * 60) + endMinute
    
    // Handle overnight ranges (9 PM to 9 AM)
    if startMinutes > endMinutes {
        return nowMinutes >= startMinutes || nowMinutes < endMinutes
    } else {
        return nowMinutes >= startMinutes && nowMinutes < endMinutes
    }
}
```

### Behavior
- All scheduled notifications respect quiet hours
- Immediate alerts (milestone, streak-at-risk) also suppressed
- User can customize both start and end times
- Default: 9 PM (21:00) to 9 AM (09:00)

## Notification Management

### Cancel Operations
- `cancelAll()` - Remove all pending and delivered notifications
- `cancel(type:)` - Remove by type: "daily", "weekly", "milestone"
- Useful when user toggles settings

### Logging
All notifications logged to console with timestamps:
```
[Notifications] Daily reminder scheduled for 5 PM
[Notifications] Milestone 7 notification sent
[Notifications] Streak at risk alert suppressed (quiet hours)
```

## Integration with GameEngine

### endGame() Method
After game concludes, triggers:

1. **Session Stats Creation**
   - Creates SessionStats struct with score, accuracy, words learned, etc.
   - Stores in `lastSessionStats` for OpeningScreenView

2. **Metrics Update**
   - Calls `updateMetrics()` to refresh StreakMetrics
   - Computes current streak, next milestone, days until

3. **Milestone Check**
   - If daily goal met and streak is milestone (7, 14, 30, 60, 100)
   - Calls `NotificationManager.shared.notifyMilestoneReached(streak)`

4. **Streak At Risk Check**
   - If progress is 0 < p < 0.25 (between 0% and 25%)
   - Calls `NotificationManager.shared.notifyStreakAtRisk()`

## Testing Checklist

- [x] Build succeeds with no errors/warnings
- [x] NotificationManager initializes on app launch
- [x] Permission request appears on first launch
- [x] Granted permissions persisted to UserDefaults
- [ ] Settings UI opens from gear icon
- [ ] Toggling notifications schedules/cancels requests
- [ ] Daily reminder appears at 5 PM (or manually trigger)
- [ ] Weekly summary appears Sunday 6 PM
- [ ] Quiet hours suppresses notifications
- [ ] Milestone notification triggers when streak = 7
- [ ] Streak at risk notification triggers when p < 0.25
- [ ] Permission status badge shows correct state
- [ ] Settings persist across app restarts
- [ ] macOS Notification Center shows messages

## Files Modified/Created

### Created
- `WordsOfTheDead/Sources/Engine/NotificationManager.swift` (500+ lines)
- `WordsOfTheDead/Sources/Views/NotificationSettingsView.swift` (200+ lines)

### Modified
- `WordsOfTheDead/Sources/Engine/GameEngine.swift` - endGame() integration
- `WordsOfTheDead/Sources/Views/OpeningScreenView.swift` - Settings sheet
- `WordsOfTheDead/Sources/WordsOfTheDeadApp.swift` - NotificationManager init

## macOS Compatibility

- **Deployment Target**: macOS 11.0+ (uses UserNotifications framework)
- **Notification Center**: Fully integrated with native macOS notifications
- **No Badge Numbers**: Badge feature removed (not available on macOS)
- **Quiet Hours**: Implemented via time checking (not using DNDStatus API)

## Future Enhancements

1. **Rich Notifications**
   - Add custom sounds for different notification types
   - Include app icon/badge in notifications

2. **User Customization**
   - Customize daily reminder time (not just 5 PM)
   - Customize weekly summary day/time
   - Custom notification messages

3. **Advanced Quiet Hours**
   - Multiple quiet hour periods
   - Quiet hours per notification type
   - Calendar integration (auto-quiet during meetings)

4. **Analytics**
   - Track notification delivery success
   - Monitor user engagement with notifications
   - Measure impact on daily streaks

5. **Breakthrough Notifications**
   - Super important alerts bypass quiet hours
   - User-configurable "emergency notification" settings
   - VIP modes for specific friends/milestones

## Known Limitations

1. **macOS Notifications**: No badge numbers (iOS-only feature)
2. **DND Detection**: macOS doesn't expose Do Not Disturb API, using time-based checking
3. **Timezone Handling**: Relies on system timezone; DST changes are handled by Calendar
4. **Recurring Notifications**: Calendar-based triggers fire once per day/week, not exactly 24h apart

## Troubleshooting

### Notifications Not Appearing
1. Check `NotificationManager.permissionStatus` is `.authorized`
2. Verify toggle is enabled (isEnabled = true)
3. Check System Preferences > Notifications > Words of the Dead
4. Confirm not in quiet hours

### Settings Not Persisting
1. Check UserDefaults keys in System Preferences > Advanced > Show Package Contents
2. Verify `onChange` handlers are properly wired to `@Published` properties
3. Check app not running with sandboxing restrictions

### Wrong Time Zones
1. Daily reminders fire at 5 PM local time
2. Weekly summary fires Sunday 6 PM local time
3. Respect system timezone setting in macOS
