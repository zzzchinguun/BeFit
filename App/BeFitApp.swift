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
    @StateObject private var versionCheckService = VersionCheckService()
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .withInjectedEnvironment() // Injects all environment objects
                .task {
                    await versionCheckService.checkVersion()
                }
                .sheet(isPresented: $versionCheckService.shouldShowUpdatePrompt) {
                    UpdatePromptView(
                        isRequiredUpdate: versionCheckService.isRequiredUpdate,
                        appStoreURL: versionCheckService.appStoreURL
                    )
                    .interactiveDismissDisabled(versionCheckService.isRequiredUpdate)
                }
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
        
        // Initialize app defaults if not already set, but don't reset existing values
        setupAppDefaults()
        
        // Setup initial version data
        Task {
            await VersionSetup.setupInitialVersion()
        }
    }
    
    private func setupAppDefaults() {
        // Only set defaults if they haven't been set already
        let defaults = UserDefaults.standard
        
        // Setup language preference (default to Mongolian - false)
        if defaults.object(forKey: "isEnglishLanguage") == nil {
            defaults.set(false, forKey: "isEnglishLanguage")
        }
        
        // Setup dark mode preference to follow system by default (nil)
        if defaults.object(forKey: "isDarkMode") == nil {
            // Don't set a value - this will make the app follow system settings
            defaults.removeObject(forKey: "isDarkMode")
            defaults.set(true, forKey: "darkModeInitialized") // Just mark that we've considered this setting
        }
        
        // Make sure we're not resetting user notification settings
        if defaults.object(forKey: "samplesNotificationsLoaded") == nil {
            defaults.set(false, forKey: "samplesNotificationsLoaded")
        }
        
        // Clean up any potentially corrupted auth token data
        defaults.removeObject(forKey: "savedNotifications")
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
                // Only schedule notifications if user hasn't been notified in the last 24 hours
                let lastNotificationKey = "lastNotificationTimestamp"
                let currentTime = Date().timeIntervalSince1970
                let lastNotificationTime = UserDefaults.standard.double(forKey: lastNotificationKey)
                
                // Check if 24 hours have passed since the last notification
                if (currentTime - lastNotificationTime) > 24 * 60 * 60{
                    // Only if there are no unread notifications
                    if notificationViewModel.unreadCount == 0 {
                        // Schedule a weight reminder notification for the next day
                        notificationViewModel.scheduleNotification(
                            title: "Жин бүртгэх",
                            body: "Өглөө бүр жингээ бүртгээд ахицаа хянаарай",
                            timeInterval: 24 * 60 * 60, // Schedule for 24 hours later
                            categoryIdentifier: "WEIGHT_CATEGORY"
                        )
                        
                        // Update the last notification timestamp
                        UserDefaults.standard.set(currentTime, forKey: lastNotificationKey)
                    }
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
            id: UUID(),
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
        // Capture only the values we need before passing to async context
        let categoryIdentifier = response.notification.request.content.categoryIdentifier
        let notification = response.notification
        
        Task { @MainActor in
            do {
                // Get the NotificationViewModel safely from any context
                let notificationViewModel = try await ServiceContainer.shared.resolveOnMainActor(NotificationViewModel.self)
                
                // Add notification to our in-app list if needed
                let appNotification = self.createAppNotification(from: notification)
                
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
            } catch {
                print("Error accessing NotificationViewModel: \(error)")
            }
        }
        
        // Complete the response
        completionHandler()
    }
}
