# Critical Bug Fix: Notification Manager Main Thread Hang

## Issue Summary
**Severity:** CRITICAL  
**Status:** FIXED (Pending Verification)  
**Symptoms:** App beachballs/becomes unresponsive on new player creation

## Root Cause Analysis

### The Problem
When creating a new player in Words of the Dead, the following sequence occurred:

1. Player created via `PlayerStore.createNewPlayer()`
2. `activate()` called to initialize player state
3. Engine engages all features, including `NotificationManager`
4. `NotificationManager.init()` was calling `requestPermissionIfNeeded()` **synchronously on the main thread**
5. This function could:
   - Trigger macOS system permission dialogs
   - Block the main thread waiting for user response
   - Cause UI freezing/beachball behavior

### Code Timeline
**Before Fix:**
```swift
private init() {
    // ... load settings ...
    
    // ❌ BLOCKING: Synchronous permission request on MainActor
    requestPermissionIfNeeded()  // Could trigger dialog, blocking main thread
}
```

**After Fix:**
```swift
private init() {
    // ... load settings ...
    
    // ✅ NON-BLOCKING: Deferred async permission check
    Task {
        await self.checkPermissionStatus()  // Only reads status, doesn't request
    }
}
```

## Solution Implemented

### 1. Deferred Permission Check (Line 64-68)
Moved permission request from synchronous init to deferred async task:
- Checks current permission status asynchronously
- Does NOT request new permissions during app startup
- Prevents blocking the main thread during initialization

### 2. New checkPermissionStatus() Method (Line 72-78)
```swift
private func checkPermissionStatus() async {
    let center = UNUserNotificationCenter.current()
    let settings = await center.notificationSettings()
    await MainActor.run {
        self.permissionStatus = settings.authorizationStatus
    }
}
```
- Only reads current authorization status (non-blocking)
- Updates UI state asynchronously
- Safe to call during app startup

### 3. Preserved Permission Request Path (Line 80-104)
Kept `requestPermissionIfNeeded()` intact for on-demand use:
- Called explicitly when user accesses notification settings
- Still requests permissions when appropriate
- Works correctly when called after app is fully initialized

## Files Modified
- **WordsOfTheDead/Sources/Engine/NotificationManager.swift**
  - Lines 64-68: Deferred async permission check in init
  - Lines 72-78: New checkPermissionStatus() method
  - Lines 80-104: requestPermissionIfNeeded() unchanged (called explicitly)

## Verification Plan
1. Build clean app from current source
2. Create new DMG distribution package
3. Test on clean system:
   - Extract DMG
   - Create new player named "Tester"
   - Monitor for hang/beachball during player creation
   - Verify app reaches opening screen successfully
4. Verify notifications still work:
   - Access notification settings
   - Permissions still requested/granted as expected
   - Existing settings respected

## Expected Outcomes
- ✅ No hang/beachball on new player creation
- ✅ App initialization completes smoothly
- ✅ Opening screen displays without freezing
- ✅ Notification permissions still requested when user visits settings
- ✅ All existing notification features continue working

## Technical Notes
- `checkPermissionStatus()` is private—only called during deferred init
- `requestPermissionIfNeeded()` remains public for settings screen usage
- Permission request happens asynchronously, ensuring UI responsiveness
- Status updates propagate to UI via `@Published` property

## Related Code Sections
- **Where NotificationManager is created:** WordsOfTheDead/Sources/WordsOfTheDeadApp.swift (@StateObject)
- **Where requestPermissionIfNeeded() is called:** NotificationSettingsView.swift (when user enables notifications)
- **Data types:** UNAuthorizationStatus enum from UserNotifications framework
