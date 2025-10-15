# Stairs Tracking Features

## Overview
The Movic Steps app now includes comprehensive stairs tracking functionality with social features, user authentication, and 2FA security.

## New Features

### 🏢 Stairs View
- **Main Dashboard**: Track daily, weekly, monthly, and yearly stair climbing progress
- **Real-time Metrics**: Floors climbed, calories burned, active time, and goal progress
- **Time Frame Selection**: Switch between different time periods for historical data
- **Visual Progress**: Animated progress rings and gradient cards
- **Goal Setting**: Customizable daily stairs goals

### 👥 Leaderboard System
- **Global Rankings**: See how you compare with other users
- **Time-based Leaderboards**: Different leaderboards for today, week, month, year
- **User Profiles**: Display usernames, avatars, and activity status
- **Achievement System**: Badges and milestones for stair climbing achievements
- **Real-time Updates**: Live leaderboard updates as users climb stairs

### 🔐 User Authentication
- **Account Creation**: Register with username, email, and phone number
- **Secure Login**: Username/password authentication
- **2FA Security**: Two-factor authentication via SMS using Clicksend
- **User Profiles**: Personalized user experience with custom avatars
- **Session Management**: Persistent login sessions

### 📱 Clicksend SMS Integration
- **2FA Codes**: Send verification codes via SMS
- **International Support**: Global SMS delivery
- **Reliable Delivery**: Enterprise-grade SMS service
- **Cost Effective**: Pay-per-message pricing

## Technical Implementation

### Files Added/Modified

#### New Files:
- `StairsView.swift` - Main stairs tracking interface
- `AuthenticationManager.swift` - User authentication and 2FA
- `LeaderboardManager.swift` - Leaderboard data management
- `STAIRS_FEATURES.md` - This documentation

#### Modified Files:
- `ContentView.swift` - Added stairs tab to navigation
- `UserSettings.swift` - Added daily stairs goal setting

### Key Components

#### StairsView
```swift
struct StairsView: View {
    // Main stairs tracking dashboard
    // Time frame selection
    // Progress visualization
    // Quick actions
}
```

#### AuthenticationManager
```swift
class AuthenticationManager: ObservableObject {
    // User registration/login
    // 2FA code generation
    // Clicksend SMS integration
    // Session management
}
```

#### LeaderboardManager
```swift
class LeaderboardManager: ObservableObject {
    // Leaderboard data management
    // User rankings
    // Achievement tracking
    // Real-time updates
}
```

## Usage

### Getting Started
1. **Open the Stairs Tab**: Tap the "Stairs" tab in the main navigation
2. **Create Account**: Tap "Login" to register or sign in
3. **Set Goals**: Configure your daily stairs goal
4. **Start Tracking**: The app automatically tracks floors climbed
5. **View Leaderboard**: See your ranking among other users

### Authentication Flow
1. **Registration**: Enter username, email, phone, and password
2. **2FA Setup**: Receive SMS verification code
3. **Code Verification**: Enter 6-digit code to complete setup
4. **Login**: Use username/password for future logins

### Leaderboard Features
- **View Rankings**: See top performers globally
- **Filter Options**: All users, friends, or global rankings
- **Time Periods**: Today, this week, this month, this year
- **Your Progress**: Track your personal ranking and progress

## Configuration

### Clicksend SMS Setup
1. **Get API Key**: Sign up at [Clicksend](https://clicksend.com)
2. **Update API Key**: Replace `YOUR_CLICKSEND_API_KEY` in `AuthenticationManager.swift`
3. **Configure Sender ID**: Set your preferred sender name

### Stairs Goal Settings
- **Default Goal**: 10 floors per day
- **Customizable**: Users can set any goal from 1-100 floors
- **Persistent**: Goals saved across app sessions

## Data Models

### User
```swift
struct User: Identifiable, Codable {
    let id: UUID
    let username: String
    let email: String
    let phoneNumber: String
    let isVerified: Bool
    let createdAt: Date
    let lastLoginAt: Date?
}
```

### LeaderboardUser
```swift
struct LeaderboardUser: Identifiable, Codable {
    let id: UUID
    let username: String
    let floors: Int
    let rank: Int
    let isCurrentUser: Bool
    let avatar: String?
    let lastActive: Date
}
```

## Security Features

### 2FA Implementation
- **SMS Codes**: 6-digit verification codes
- **Time-limited**: Codes expire after 10 minutes
- **Rate Limiting**: Prevents spam attempts
- **Secure Storage**: User data encrypted locally

### Data Privacy
- **Local Storage**: User data stored securely on device
- **No Cloud Sync**: All data remains private
- **Optional Sharing**: Users choose what to share on leaderboard

## Future Enhancements

### Planned Features
- **Friend System**: Add friends and see their progress
- **Challenges**: Create and join stair climbing challenges
- **Achievements**: Unlock badges for milestones
- **Social Sharing**: Share progress on social media
- **Apple Watch**: Native watchOS app for stairs tracking
- **HealthKit Integration**: Sync with Apple Health floors data

### Technical Improvements
- **Real-time Updates**: WebSocket connections for live leaderboard
- **Push Notifications**: Goal reminders and achievement notifications
- **Offline Support**: Continue tracking without internet
- **Data Export**: Export stairs data for analysis

## Troubleshooting

### Common Issues
1. **SMS Not Received**: Check phone number format and try again
2. **Login Failed**: Verify username/password combination
3. **Leaderboard Not Loading**: Check internet connection
4. **Goals Not Saving**: Ensure app has proper permissions

### Support
- **In-App Support**: Use the AI assistant in settings
- **Email Support**: Contact support@airforcerp.com
- **Documentation**: Check this file for technical details

## API Reference

### Clicksend SMS API
```swift
func sendSMS(to phoneNumber: String, message: String) async throws -> Bool
```

### Authentication Methods
```swift
func login(username: String, password: String) async
func register(username: String, email: String, phoneNumber: String, password: String) async
func send2FACode(phoneNumber: String) async -> Bool
func verify2FACode(_ code: String) async -> Bool
```

### Leaderboard Methods
```swift
func fetchLeaderboardData()
func updateUserFloors(_ floors: Int)
func getLeaderboardForTimeframe(_ timeframe: StairsView.TimeFrame) -> [LeaderboardUser]
```

## License
This feature implementation is part of the Movic Steps app. All rights reserved.
