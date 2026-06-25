# Engagement Features Implementation Guide

Detailed specifications for three key engagement features: streak visualization, notifications/reminders, and opening screen engagement.

---

## 1. Streak Visualization

### Current State

✅ **Already Implemented:**
- `DailyGoalTracker.currentStreak` calculates consecutive days meeting 20-word goal
- `DailyStreakView` displays streak in game (not yet verified in code)
- `DailyGoalActivity` tracks daily progress (met/not met)
- Streak persists across launches via JSON

❌ **Missing:**
- Prominent display on main/opening screen
- Milestone animations (7, 14, 30, 60 day achievements)
- "Streak at risk" warning when near deadline
- Break-in streak counter (motivation to rebuild)

### Design

#### Main Opening Screen (Player Select → Start)

```
┌─────────────────────────────────────────┐
│      Words of the Dead                  │
│                                         │
│  👤 Continue as: Alice                  │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 🔥 28-DAY STREAK                │   │
│  │ Keep the fire alive!            │   │
│  │                                 │   │
│  │ Next milestone: 30 days (2 away)│   │
│  └─────────────────────────────────┘   │
│                                         │
│  ⚠️ Daily goal: 12/20 words today      │
│     Complete before 11:59 PM           │
│                                         │
│  [Start Game] [Select Different]       │
└─────────────────────────────────────────┘
```

#### Streak Display Elements

**Primary Streak Counter:**
- Large bold number (72-point font)
- Flame emoji (🔥) or fire animation
- Color gradient (gold → orange → red based on length)
- Beneath player name on start screen

**Milestone Badges:**
- 7 days: 🌟 "Week Warrior"
- 14 days: ⭐ "Fortnight Master"
- 30 days: 🏆 "Month Champion"
- 60 days: 👑 "Season King/Queen"
- 100 days: 💎 "Century Collector"

**Streak at Risk Warning:**
- Show when < 5 words practiced today (< 25% of goal)
- Color: Orange/amber
- Message: "⚠️ Streak at risk! Complete 8 more words before midnight"
- Time remaining counter

**Break-in Streak Motivation:**
- After streak lost: Show "Rebuild Streak: 0 days"
- Lighter red color to show recovery mode
- Goal: Get back to previous streak length
- Example: "Rebuild streak: 0 days (was 28)"

### Implementation Details

#### Data Model Enhancement

```swift
// Add to DailyGoalTracker
struct StreakMetrics {
    let currentStreak: Int        // Currently maintained
    let longestStreak: Int        // All-time best
    let breakInStreak: Int        // Since last break
    let daysUntilMilestone: Int   // Days to next milestone
    let nextMilestone: Int        // 7, 14, 30, 60, 100
    let streakAtRisk: Bool        // Today's progress < 25%
    let timeUntilDeadline: TimeInterval
}
```

#### New Views/Components

**StreakCardView.swift** (Main streak display):
```swift
struct StreakCardView: View {
    let streak: Int
    let nextMilestone: Int
    let daysUntilMilestone: Int
    let atRisk: Bool
    let breakIn: Bool
    
    // Large centered flame + number
    // Progress bar to next milestone
    // At-risk warning if needed
    // Break-in message if streak lost
}
```

**MilestoneNotificationView.swift** (Celebration popup):
```swift
struct MilestoneNotificationView: View {
    let milestone: Int
    let badge: String  // "Week Warrior", "Champion", etc.
    
    // Large celebratory animation
    // Confetti effect (optional)
    // "Share" button to brag
}
```

#### Integration Points

**GameOverView:**
- Show updated streak at end of session
- Trigger milestone notification if reached
- Show progress to next milestone

**StartView (main menu):**
- Prominent streak display
- "Streak at risk" warning with time remaining
- Next play session countdown (if goal already met)

**Opening/Splash Screen:**
- Streak on player selection screen (first thing users see)
- Motivational message based on streak length

### Metrics & Analytics

Track:
- Current streak length
- Longest streak achieved
- Time spent rebuilding streak
- Milestone frequency (when players hit 7, 14, 30 days)
- Engagement drop rate when streak breaks

---

## 2. Notifications & Reminders

### Current State

❌ **Not Yet Implemented**

Required Permissions:
- macOS UNUserNotification (requires app permissions dialog)
- User Settings preferences
- Do Not Disturb handling

### Design

#### Permission Request

First launch after Day 2 of streak:
```
┌─────────────────────────────────────────┐
│  🔔 Stay Engaged                        │
│                                         │
│  Get gentle reminders to maintain your  │
│  28-day streak!                         │
│                                         │
│  [Enable] [Ask Later] [Never]           │
│                                         │
│  We respect your time:                  │
│  • Only 1 reminder per day (5 PM)       │
│  • No notifications 9 PM - 9 AM         │
│  • Customizable in Settings             │
└─────────────────────────────────────────┘
```

#### Notification Types

**1. Daily Reminder (if goal not met)**
```
Time: 5:00 PM (customizable)
Title: "Keep your streak alive!"
Body: "You've practiced 8/20 words today. 
       12 more to go before midnight."
Action: Open Game → Play immediately
```

**2. Streak Milestone Achievement**
```
Time: Immediate (when milestone reached)
Title: "🏆 28-Day Streak!"
Body: "You've mastered 28 days of daily practice.
       Share this achievement with friends!"
Action: Open App → Share Achievement
```

**3. Weekly Summary** (Sunday evening)
```
Time: 6:00 PM (customizable, Sunday only)
Title: "Weekly Progress Report"
Body: "This week: 5/7 days completed
       Accuracy: 82% | New Words: 12
       Streak: 28 days 🔥"
Action: Open App → View Stats
```

**4. Streak Broken Alert** (if streak ends)
```
Time: Next day at 9 AM
Title: "Your streak ended 😢"
Body: "Don't worry! Rebuild it starting today.
       You were on a 28-day streak."
Action: Open App → Start Rebuilding
```

**5. Return to Game Nudge** (inactive 3+ days)
```
Time: 6:00 PM on day 4
Title: "We miss you!"
Body: "Come back and practice. Your brain 
       needs to review 42 words."
Action: Open App → Resume
```

### Implementation Details

#### Settings Structure

```swift
struct NotificationSettings: Codable {
    var enabled: Bool = true
    var dailyReminderTime: Date = Date(hour: 17)  // 5 PM
    var weeklyReportDay: Int = 0  // 0 = Sunday
    var weeklyReportTime: Date = Date(hour: 18)   // 6 PM
    var quietHoursStart: Date = Date(hour: 21)    // 9 PM
    var quietHoursEnd: Date = Date(hour: 9)       // 9 AM
    var notifyOnMilestones: Bool = true
    var notifyOnStreakBreak: Bool = true
    var notifyOnInactivity: Bool = true
    var inactivityDays: Int = 3
}
```

#### Notification Manager

**NotificationManager.swift** (new):

```swift
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    
    private var settings: NotificationSettings
    
    // Request user permission (macOS)
    func requestAuthorization() async -> Bool
    
    // Schedule notifications based on settings
    func scheduleDailyReminder()
    func scheduleWeeklyReport()
    func scheduleStreakBreakNotification()
    func scheduleInactivityReminder()
    
    // Send immediate notifications
    func notifyMilestoneReached(_ days: Int)
    func notifyStreakEnded(_ wasDays: Int)
    
    // Respect Do Not Disturb and quiet hours
    func canNotifyNow() -> Bool
    
    // User action handling
    func handleNotificationTapped(_ type: NotificationType)
}
```

#### Integration with GameEngine

```swift
// In GameEngine, when daily goal is met:
if daily.goalMetToday && !daily.goalMetYesterday {
    NotificationManager.shared.notifyMilestoneReached(dayStreak)
}

// On app launch, check for missed notifications
NotificationManager.shared.checkAndSchedulePending()
```

#### macOS Specifics

Use `UserNotificationCenter`:
```swift
import UserNotifications

// Request permission
UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
    // Handle response
}

// Schedule notification
let content = UNMutableNotificationContent()
content.title = "Keep your streak alive!"
content.body = "You've practiced 8/20 words today."
content.sound = .default

let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
let request = UNNotificationRequest(identifier: "daily-reminder", content: content, trigger: trigger)
UNUserNotificationCenter.current().add(request)
```

### User Control

**Settings Screen:**
```
Notifications
├── Enable All Notifications [Toggle]
├── Daily Reminder
│   ├── Time: [5:00 PM ▼]
│   └── Enabled [Toggle]
├── Weekly Summary
│   ├── Day: [Sunday ▼]
│   ├── Time: [6:00 PM ▼]
│   └── Enabled [Toggle]
├── Streak Milestones [Toggle]
├── Quiet Hours
│   ├── Start: [9:00 PM ▼]
│   ├── End: [9:00 AM ▼]
│   └── Respect Do Not Disturb [Toggle]
└── Inactivity Reminders
    ├── After [3 ▼] days
    └── Enabled [Toggle]
```

---

## 3. Opening Screen Engagement

### Current State

✅ **Already Implemented:**
- Player select screen (continue as previous player)
- Level intro screen

❌ **Missing:**
- Motivational context on opening
- Streak visualization
- Daily progress summary
- "Today's challenge" teaser
- Contextual messages based on streak length

### Design

#### Opening Screen (First Thing User Sees)

```
┌──────────────────────────────────────────┐
│    Words of the Dead                     │
│                                          │
│  🔥 28-DAY STREAK                        │
│    "On fire! Keep it up!" 🚀             │
│                                          │
│  👤 Continue as: Alice                   │
│                                          │
│  Today's Challenge:                      │
│  ├─ Practice 20 new words (+2 exp)       │
│  ├─ Achieve 80%+ accuracy                │
│  ├─ Master "perspicacious"               │
│  └─ Beat yesterday's score: 8,450 pts    │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │ Daily Progress: ████░░░░░░░░░░░░ │   │
│  │ 8/20 words today                 │   │
│  │ Complete before 11:59 PM ⏰       │   │
│  └──────────────────────────────────┘   │
│                                          │
│  Last Session: 4,200 pts | 82% accuracy │
│                                          │
│  [Start Game] [Select Different] [Stats]│
└──────────────────────────────────────────┘
```

#### Motivational Messages (Based on Streak)

| Streak | Message | Emoji |
|--------|---------|-------|
| 1 day | "Starting strong!" | 💪 |
| 3 days | "Momentum building!" | 🚀 |
| 7 days | "Week Warrior!" | 🌟 |
| 14 days | "Unstoppable force!" | ⚡ |
| 30 days | "Legend status!" | 👑 |
| 50+ days | "Absolutely legendary!" | 💎 |
| 0 (broken) | "Let's rebuild together" | 🤝 |

#### Daily Challenge Teaser

Show 3 rotating challenges:
1. **New Words**: "Learn 3 new words today"
2. **Mastery Goal**: "Master the word 'cacophony'"
3. **Score Challenge**: "Beat yesterday's score (8,450 pts)"

Rotate every time user plays.

#### Progress Bar

Visual representation of daily goal:
```
Progress: ████░░░░░░░░░░░░░░  40%
          8/20 words
```

Color coding:
- Green (0-50%): Starting strong
- Yellow (50-75%): Getting there
- Orange (75-90%): Almost there
- Green (90-100%): Goal met! ✅

### Implementation Details

#### New View: OpeningScreenView

```swift
struct OpeningScreenView: View {
    @ObservedObject var engine: GameEngine
    @ObservedObject var dailyGoal: DailyGoalTracker
    
    var streakMessage: String {
        switch dayStreak {
        case 0:
            return "Let's rebuild together"
        case 1...3:
            return "Starting strong!"
        case 4...7:
            return "Momentum building!"
        case 8...14:
            return "Week Warrior!"
        case 15...30:
            return "Month Champion!"
        case 31...60:
            return "Legend status!"
        default:
            return "Absolutely legendary!"
        }
    }
    
    var dailyChallenges: [DailyChallenge] {
        // Rotate challenges based on last session date
        [
            DailyChallenge(
                title: "Learn 3 new words",
                description: "Expand your vocabulary",
                reward: "+2 XP"
            ),
            DailyChallenge(
                title: "Master: \(nextWordToMaster.word)",
                description: "Review this challenging word",
                reward: "+5 XP"
            ),
            DailyChallenge(
                title: "Beat yesterday's score",
                description: "You scored \(yesterdayScore) pts",
                reward: "+1 XP"
            )
        ]
    }
}
```

#### Components

**StreakBannerView.swift**:
```swift
struct StreakBannerView: View {
    let streak: Int
    let message: String
    
    var backgroundColor: Color {
        switch streak {
        case 0:
            return Color.gray.opacity(0.3)
        case 1..<7:
            return Color.green.opacity(0.3)
        case 7..<30:
            return Color.blue.opacity(0.3)
        default:
            return Color.purple.opacity(0.3)
        }
    }
}
```

**DailyChallengeView.swift**:
```swift
struct DailyChallengeView: View {
    let challenge: DailyChallenge
    let index: Int
    let isHighlighted: Bool
}
```

**DailyProgressView.swift**:
```swift
struct DailyProgressView: View {
    let completed: Int
    let goal: Int
    let timeRemaining: TimeInterval
    
    var progress: Double {
        Double(completed) / Double(goal)
    }
}
```

#### Data Model

```swift
struct DailyChallenge: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let reward: String
    let isCompleted: Bool = false
}

struct SessionStats {
    let score: Int
    let accuracy: Double
    let wordsLearned: Int
    let timestamp: Date
}
```

#### Integration with GameEngine

On app launch:
```swift
// Fetch streak, today's progress, yesterday's stats
engine.loadOpeningScreenData()

// Determine motivational message
engine.streakMessage = getStreakMessage(dayStreak: engine.dayStreak)

// Set up daily challenges
engine.dailyChallenges = generateDailyChallenges()

// Load last session stats
engine.sessionStats = SessionStats.load()
```

### User Experience Flow

1. **App Launch** → Opening Screen (0.5s load)
2. **See Streak** → Immediately motivating (🔥 28 days!)
3. **Scan Challenges** → Quick overview of goals (3s)
4. **Start Game** → Play immediately with context
5. **End Session** → See if daily challenge completed

---

## Implementation Roadmap

### Phase 1: Streak Visualization (1-2 hours)
- [ ] Add StreakMetrics to DailyGoalTracker
- [ ] Create StreakCardView component
- [ ] Integrate into StartView
- [ ] Add milestone badge system
- [ ] Test streak calculations

### Phase 2: Opening Screen (2-3 hours)
- [ ] Create OpeningScreenView with player select
- [ ] Implement DailyProgressView progress bar
- [ ] Add daily challenges rotation
- [ ] Integrate SessionStats loading
- [ ] Test motivational messaging

### Phase 3: Notifications (3-4 hours)
- [ ] Create NotificationManager
- [ ] Implement UNUserNotificationCenter setup
- [ ] Add NotificationSettings to settings screen
- [ ] Create notification scheduling logic
- [ ] Test macOS notification delivery
- [ ] Handle quiet hours and Do Not Disturb

### Phase 4: Polish (1 hour)
- [ ] Animation/transitions between screens
- [ ] Sound effects for milestones
- [ ] Toast notifications for daily challenges
- [ ] Settings persistence

---

## Testing Checklist

### Streak Visualization
- [ ] Streak displays correctly on opening screen
- [ ] Milestones trigger at 7, 14, 30, 60, 100 days
- [ ] Streak at risk warning shows when < 5 words practiced
- [ ] Break-in counter shows after streak broken
- [ ] Color gradients work correctly
- [ ] Motivational messages change at streak thresholds

### Opening Screen
- [ ] Player info loads correctly
- [ ] Daily challenges rotate properly
- [ ] Progress bar updates in real-time
- [ ] Last session stats display correctly
- [ ] Time remaining countdown accurate
- [ ] All motivational messages appear

### Notifications
- [ ] Permission request dialog shows appropriately
- [ ] Daily reminder scheduled at correct time
- [ ] Weekly summary appears on Sunday
- [ ] Milestone notifications trigger immediately
- [ ] Streak break notification sends next day
- [ ] Inactivity reminder only after 3 days
- [ ] Quiet hours respected
- [ ] Do Not Disturb respected
- [ ] Settings panel works correctly
- [ ] Notifications clear properly

---

## Future Enhancements

1. **Leaderboard** — Compare streaks with friends
2. **Achievement Sharing** — Share milestones to social media
3. **Streak Freeze** — Ability to freeze streak for 1 day (premium?)
4. **Streak Challenges** — "Beat friend's streak" competitions
5. **Custom Notifications** — User-defined reminder times per challenge
6. **Streak Insurance** — Recover from streak break once per month
7. **Habit Stacking** — Integrate with Apple Health/Reminders
