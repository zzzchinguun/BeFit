# BeFit: Personal Fitness Tracker

BeFit is a comprehensive fitness tracking application designed to help users manage their health and fitness journey. This iOS app provides tools for tracking workouts, monitoring nutrition, logging weight, and setting personalized fitness goals.

## Features

### User Authentication
- Secure sign-up and login with email and password
- User profile management
- Account deletion and password reset functionality

### Fitness Profile
- Personalized onboarding process
- Age, weight, height, and body measurements tracking
- Custom fitness goal setting (weight loss, muscle gain, maintenance)
- Calculation of TDEE (Total Daily Energy Expenditure) and macro targets

### Weight Tracking
- Daily weight logging with optional notes
- Weight history and trend visualization
- Automatic reminders for daily weight logging

### Exercise Tracking
- Extensive exercise library with default exercises
- Custom exercise creation
- Exercise categorization (compound, isolation, cardio, etc.)
- Workout logging with sets, reps, and weight
- Exercise history and performance metrics

### Nutrition Management
- Daily meal logging (breakfast, lunch, dinner, snacks)
- Nutritional content tracking (calories, protein, carbs, fat)
- Macro goal progress visualization
- Remaining daily calorie and macro calculation

### Dashboard
- Overview of key metrics (current weight, goal weight, days remaining)
- Daily nutrition summary
- Weight and workout progress visualization

## Technology Stack

- **Swift** and **SwiftUI** for the UI and app logic
- **MVVM Architecture** for clean code organization
- **Firebase Authentication** for user management
- **Firebase Firestore** for data storage
- **Combine Framework** for reactive programming

## Installation and Setup

1. Clone the repository
```bash
git clone https://github.com/yourusername/BeFit.git
cd BeFit
```

2. Open the project in Xcode
```bash
open BeFit.xcodeproj
```

3. Install dependencies (if using CocoaPods or Swift Package Manager)
```bash
# If using CocoaPods
pod install
```

4. Configure Firebase
   - Create a Firebase project at [firebase.google.com](https://firebase.google.com)
   - Add an iOS app to your Firebase project
   - Download the `GoogleService-Info.plist` file and add it to your Xcode project
   - Enable Authentication and Firestore in the Firebase console

5. Build and run the application in Xcode

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+
- Active Firebase account

## Privacy Policy

### Information Collection and Use

BeFit collects and processes the following information to provide and improve our services:

#### Personal Information
- Email address (for authentication)
- Name (first and last)
- Age
- Weight and height measurements
- Body composition data
- Fitness goals and progress

#### Usage Data
- Workout history
- Nutrition logs
- Weight tracking data
- App usage statistics

### Data Storage and Security

- All data is stored securely using Firebase Firestore
- User authentication is handled through Firebase Authentication
- Data is encrypted in transit and at rest
- We implement appropriate security measures to protect your personal information

### Data Usage

We use your data to:
- Provide personalized fitness tracking
- Calculate nutrition and exercise recommendations
- Track your progress towards fitness goals
- Improve app functionality and user experience

### Third-Party Services

BeFit uses the following third-party services:
- Firebase (Authentication, Firestore, Storage)
- Apple HealthKit (optional, for health data integration)

### Your Rights

You have the right to:
- Access your personal data
- Correct inaccurate data
- Delete your account and associated data
- Export your data
- Opt-out of data collection

### Data Retention

- Your data is retained as long as your account is active
- You can request data deletion by deleting your account
- Some data may be retained for legal or business purposes

### Contact Information

For privacy-related questions or concerns, please contact:
   sharshuwuu@gmail.com or follow and dm on instagram(zzzchinguun)

### Updates to Privacy Policy

We may update this privacy policy from time to time. We will notify you of any changes by posting the new privacy policy on this page.

## License

MIT License

## Acknowledgements

- [List any third-party libraries, resources or inspirations]
