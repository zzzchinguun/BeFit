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

## License

none 

## Acknowledgements


