//
//  BeFitApp.swift
//  BeFit
//
//  Created by Chinguun Khongor on 3/9/25.
//

import SwiftUI
import Firebase
import UserNotifications
import Combine

@main
struct BeFitApp: App {
    // MARK: - Initialize Firebase
    
    // This initializes the Firebase app and begins loading user data in the background
    private let appInitializer = AppInitializer()
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .withInjectedEnvironment() // Injects all environment objects
        }
    }
}

// Helper class to handle app initialization
// This allows us to do setup work without requiring an async init in the App struct
class AppInitializer {
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = NotificationHandler.shared
    }
}

// Notification handler to process incoming notifications
class NotificationHandler: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    static let shared = NotificationHandler()
    
    private override init() {
        super.init()
        
        // Listen for notifications from the NotificationCenter (system)
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, 
                                      selector: #selector(handleSystemNotification(_:)), 
                                      name: UIApplication.didBecomeActiveNotification, 
                                      object: nil)
    }
    
    // Handle system notifications from NotificationCenter
    @objc private func handleSystemNotification(_ notification: Foundation.Notification) {
        // Process specific notifications
        switch notification.name {
        case UIApplication.didBecomeActiveNotification:
            // App became active, check for any pending notifications
            Task {
                await self.checkPendingNotifications()
            }
        default:
            break
        }
    }
    
    // Check for any pending notifications when the app becomes active
    nonisolated private func checkPendingNotifications() async {
        do {
            // Get the NotificationViewModel safely from any context
            let notificationViewModel = try await ServiceContainer.shared.resolveOnMainActor(NotificationViewModel.self)
            
            // Now dispatch to MainActor for any UI operations
            await MainActor.run {
                // For demonstration, we'll just schedule a local notification if there are no unread notifications
                if notificationViewModel.unreadCount == 0 {
                    // Schedule a weight reminder notification for 30 seconds from now (for testing)
                    notificationViewModel.scheduleNotification(
                        title: "Жин бүртгэх",
                        body: "Өнөөдрийн жингээ бүртгээгүй байна!",
                        timeInterval: 30,
                        categoryIdentifier: "WEIGHT_CATEGORY"
                    )
                }
            }
        } catch {
            print("Error accessing NotificationViewModel: \(error)")
        }
    }
    
    // Convert a UNNotification to an AppNotification
    nonisolated private func createAppNotification(from notification: UNNotification) -> AppNotification {
        let content = notification.request.content
        let type: AppNotification.NotificationType
        
        // Determine notification type based on category
        switch content.categoryIdentifier {
        case "WORKOUT_CATEGORY":
            type = .workout
        case "WEIGHT_CATEGORY":
            type = .weight
        default:
            type = .system
        }
        
        return AppNotification(
            title: content.title,
            message: content.body,
            date: notification.date,
            isRead: false,
            type: type
        )
    }
    
    // Called when a notification is delivered to a foreground app
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               willPresent notification: UNNotification, 
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification even when the app is in the foreground
        completionHandler([.banner, .sound, .badge])
        
        // Also add to our in-app notification system
        Task {
            do {
                // Get the NotificationViewModel safely from any context
                let notificationViewModel = try await ServiceContainer.shared.resolveOnMainActor(NotificationViewModel.self)
                
                // Create the AppNotification on the main actor
                await MainActor.run {
                    let appNotification = self.createAppNotification(from: notification)
                    notificationViewModel.notifications.insert(appNotification, at: 0)
                    notificationViewModel.updateUnreadCount()
                }
            } catch {
                print("Error accessing NotificationViewModel: \(error)")
            }
        }
    }
    
    // Called when a user selects an action in a delivered notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               didReceive response: UNNotificationResponse, 
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification based on category identifier
        let categoryIdentifier = response.notification.request.content.categoryIdentifier
        
        Task {
            do {
                // Get the NotificationViewModel safely from any context
                let notificationViewModel = try await ServiceContainer.shared.resolveOnMainActor(NotificationViewModel.self)
                
                await MainActor.run {
                    // Add notification to our in-app list if needed
                    let appNotification = self.createAppNotification(from: response.notification)
                    
                    // Only add if it doesn't already exist
                    if !notificationViewModel.notifications.contains(where: { $0.title == appNotification.title && $0.message == appNotification.message }) {
                        notificationViewModel.notifications.insert(appNotification, at: 0)
                        notificationViewModel.updateUnreadCount()
                    }
                    
                    // Handle specific actions
                    switch categoryIdentifier {
                    case "WORKOUT_CATEGORY":
                        // Handle workout notification action
                        print("User responded to workout notification")
                        
                    case "WEIGHT_CATEGORY":
                        // Handle weight log notification action
                        print("User responded to weight log notification")
                        
                    default:
                        break
                    }
                }
            } catch {
                print("Error accessing NotificationViewModel: \(error)")
            }
        }
        
        // Complete the response
        completionHandler()
    }
}
