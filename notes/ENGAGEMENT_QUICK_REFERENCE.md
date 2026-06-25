# Engagement Features - Quick Reference

## What's New

✨ **Streak Tracking** - Shows current streak with flame emoji, daily/weekly/all-time records
📊 **Progress Visualization** - Real-time progress bar toward daily 20-word goal
🎯 **Daily Challenges** - 3 rotating challenges per day for variety and rewards
🔔 **Smart Notifications** - Daily 5 PM reminders, Sunday summaries, milestone alerts
⏰ **Quiet Hours** - Customizable time window (default 9 PM - 9 AM) to suppress notifications
⚙️ **Settings UI** - Easy access to all preferences via gear icon in app

## User Journey

1. **Create Player** → See opening screen with streak (0), challenges, progress bar
2. **Play Game** → Complete words, track toward 20-word daily goal
3. **Reach Goal** → Celebrate in-game, unlock next level, update metrics
4. **Next Day** → Return to opening screen, see 1-day streak 🔥
5. **Day 7** → Hit milestone, get "Week Warrior" notification 🔥
6. **Keep Playing** → Build longer streaks, get notifications at 14, 30, 60, 100 days

## Key Numbers

- **Daily Goal**: 20 words
- **Milestone Streaks**: 7, 14, 30, 60, 100 days
- **Daily Reminder**: 5 PM (if goal not met)
- **Weekly Summary**: Sunday 6 PM
- **At-Risk Threshold**: < 25% daily progress
- **Quiet Hours**: 9 PM - 9 AM (default)

## Files to Know

### UI Components
- `OpeningScreenView.swift` - Main entry screen (integrates all features)
- `StreakCardView.swift` - Large streak display with milestone
- `DailyProgressView.swift` - Progress bar to daily goal
- `DailyChallengeView.swift` - Today's 3 challenges
- `NotificationSettingsView.swift` - Settings popup

### Core Logic
- `StreakMetrics.swift` - Metrics data model
- `NotificationManager.swift` - All notification scheduling
- `GameEngine.swift` - Integration points

### Data Files
- `DailyGoalStore.swift` - Daily tracking & metrics computation

## Notification Types

| Type | When | Message | Sound |
|------|------|---------|-------|
| Daily Reminder | 5 PM (repeating) | "Time to Practice" | Yes |
| Weekly Summary | Sunday 6 PM | "Weekly Summary" | Yes |
| Milestone | Immediately | "Week Warrior!" at 7 days | Yes |
| Streak at Risk | During game | "Streak at Risk!" | Yes |

## Settings

### Master Toggle
- **Enable Notifications** - Turn all notifications on/off

### Individual Toggles
- **Daily Reminder at 5 PM** - Daily push notification
- **Weekly Summary (Sunday 6 PM)** - Weekly progress summary
- **Milestone Achievements** - Alerts for 7, 14, 30, 60, 100 day streaks

### Quiet Hours
- **Start Time** - When to stop notifications (default 9 PM)
- **End Time** - When to resume notifications (default 9 AM)

### Status
- **Permission Status** - Shows "✅ Allowed", "❌ Denied", etc.

## Developer Notes

### Accessing Notifications
```swift
// From anywhere in app
let notifMgr = NotificationManager.shared

// Check if enabled
if notifMgr.isEnabled { ... }

// Trigger milestone notification
notifMgr.notifyMilestoneReached(7)

// Trigger at-risk warning
notifMgr.notifyStreakAtRisk()

// Cancel all notifications
notifMgr.cancelAll()
```

### Accessing Metrics
```swift
// From GameEngine
let metrics = gameEngine.metrics

// Access streak data
let currentStreak = metrics.currentStreak
let emoji = metrics.streakEmoji  // 🔥, ⚡, 👑, etc.
let message = metrics.streakMessage  // "Week Warrior!"
let nextMilestone = metrics.nextMilestone  // 7, 14, 30, 60, 100
```

### Adding New Notifications
```swift
// Pattern: func notify[Type]()
func notifyCustomAlert() {
    guard isEnabled else { return }
    guard !isInQuietHours() else { return }
    
    let content = UNMutableNotificationContent()
    content.title = "Title"
    content.body = "Message"
    content.sound = .default
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let request = UNNotificationRequest(identifier: "unique_id", content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request)
}
```

## Testing Checklist

- [ ] App launches without errors
- [ ] First-time: Permission request appears
- [ ] Gear icon opens settings
- [ ] Toggling notifications works
- [ ] Settings persist on restart
- [ ] Play game, check last session displays
- [ ] Streak card shows correct emoji
- [ ] Progress bar shows correct percentage
- [ ] Challenges display correctly
- [ ] Milestone notification on day 7
- [ ] At-risk warning when progress < 25%

## Troubleshooting

### Notifications Not Showing
1. Check System Preferences > Notifications > Words of the Dead
2. Verify notifications enabled in app settings (gear icon)
3. Check time - if between 9 PM - 9 AM, in quiet hours
4. Check app in Activity Monitor - if frozen, restart

### Settings Lost on Restart
1. Check ~/Library/Preferences for app plist
2. Check app has Full Disk Access in System Preferences
3. Try force-quitting and relaunching
4. Check UserDefaults in Terminal: `defaults read com.yourcompany.WordsOfTheDead`

### Streak Shows Wrong Number
1. Check daily goal tracker at ~/Library/Application Support/WordsOfTheDead/daily/
2. Verify JSON is valid (use jq or online JSON validator)
3. Check for gaps in practice history
4. Create new player to reset

## Performance Tips

- Metrics are computed on-demand (no caching)
- Notifications are scheduled async (non-blocking)
- Settings loaded once at app start
- Challenge generation uses simple math (O(1))

## Future Ideas

- 🎯 Custom reminder times per user
- 🏆 Achievement badges
- 👥 Friend comparison (optional)
- 🎁 Rewards for milestones
- 📊 Weekly stats email
- 🌍 Timezone-aware scheduling
- 🤖 ML-optimized notification timing

---

**Last Updated**: June 23, 2026
**Version**: 1.0
**Status**: Production Ready ✅
