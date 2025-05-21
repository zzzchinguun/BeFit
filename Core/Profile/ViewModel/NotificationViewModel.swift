//
//  NotificationViewModel.swift
//  BeFit
//
//  Created by AI Assistant
//

import Foundation
import SwiftUI
import UserNotifications
import Combine

struct AppNotification: Identifiable, Codable {
    var id: UUID
    var title: String
    var message: String
    var date: Date
    var isRead: Bool = false
    var type: NotificationType
    
    init(id: UUID = UUID(), title: String, message: String, date: Date, isRead: Bool = false, type: NotificationType) {
        self.id = id
        self.title = title
        self.message = message
        self.date = date
        self.isRead = isRead
        self.type = type
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, message, date, isRead, type
    }
    
    enum NotificationType: String, Codable {
        case workout
        case weight
        case meal
        case water
        case system
    }
}

@MainActor
class NotificationViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    
    // MARK: - Private Properties
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    init() {
        // Request notification permissions on init
        requestNotificationPermissions()
        
        // Load saved notifications from UserDefaults
        loadNotificationsFromStorage()
        
        // Load sample notifications for demo purposes only if they haven't been loaded before
        if !UserDefaults.standard.bool(forKey: "samplesNotificationsLoaded") && notifications.isEmpty {
            loadSampleNotifications()
            UserDefaults.standard.set(true, forKey: "samplesNotificationsLoaded")
            saveNotificationsToStorage()
        }
        
        // Calculate unread count
        updateUnreadCount()
    }
    
    // MARK: - Storage Methods
    
    /// Load notifications from UserDefaults
    private func loadNotificationsFromStorage() {
        if let savedData = UserDefaults.standard.data(forKey: "savedNotifications"),
           let decodedNotifications = try? JSONDecoder().decode([AppNotification].self, from: savedData) {
            self.notifications = decodedNotifications
        }
    }
    
    /// Save notifications to UserDefaults
    private func saveNotificationsToStorage() {
        if let encodedData = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(encodedData, forKey: "savedNotifications")
        }
    }
    
    // MARK: - Methods
    
    /// Request notification permissions from user
    func requestNotificationPermissions() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
                return
            }
            
            if granted {
                print("Notification permissions granted")
                Task { @MainActor in
                    self.configureNotificationCategories()
                }
            } else {
                print("Notification permissions denied")
            }
        }
    }
    
    /// Configure notification categories for different action types
    private func configureNotificationCategories() {
        // Configure workout reminder category
        let workoutAction = UNNotificationAction(
            identifier: "WORKOUT_ACTION",
            title: "Дасгал хийх",
            options: .foreground
        )
        
        let workoutCategory = UNNotificationCategory(
            identifier: "WORKOUT_CATEGORY",
            actions: [workoutAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Configure weight log reminder category
        let weightAction = UNNotificationAction(
            identifier: "WEIGHT_ACTION",
            title: "Жин бүртгэх",
            options: .foreground
        )
        
        let weightCategory = UNNotificationCategory(
            identifier: "WEIGHT_CATEGORY",
            actions: [weightAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register categories
        notificationCenter.setNotificationCategories([workoutCategory, weightCategory])
    }
    
    /// Schedule a local notification
    func scheduleNotification(title: String, body: String, timeInterval: TimeInterval, categoryIdentifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    /// Schedule a daily workout reminder
    func scheduleWorkoutReminder(hour: Int, minute: Int) {
        // Remove any existing workout reminders
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["workoutReminder", "workoutReminderAlternate"])
        
        let content = UNMutableNotificationContent()
        content.title = "Дасгалын цаг"
        content.body = "Өнөөдрийн дасгалаа хийх цаг болсон!"
        content.sound = .default
        content.categoryIdentifier = "WORKOUT_CATEGORY"
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        // Only send reminders on Monday, Wednesday and Friday (1, 3, 5)
        dateComponents.weekday = 1 // Sunday = 1, Monday = 2, etc.
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "workoutReminder", content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling workout reminder: \(error.localizedDescription)")
            }
        }
        
        // Add alternate days (Wednesday = 4)
        var altDateComponents = DateComponents()
        altDateComponents.hour = hour
        altDateComponents.minute = minute
        altDateComponents.weekday = 4
        
        let altTrigger = UNCalendarNotificationTrigger(dateMatching: altDateComponents, repeats: true)
        let altRequest = UNNotificationRequest(identifier: "workoutReminderAlternate", content: content, trigger: altTrigger)
        
        notificationCenter.add(altRequest) { error in
            if let error = error {
                print("Error scheduling alternate workout reminder: \(error.localizedDescription)")
            }
        }
    }
    
    /// Schedule a daily weight log reminder
    func scheduleWeightLogReminder(hour: Int, minute: Int) {
        // Remove any existing weight log reminders
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["weightLogReminder"])
        
        let content = UNMutableNotificationContent()
        content.title = "Жин бүртгэх"
        content.body = "Өнөөдрийн жингээ бүртгээгүй байна!"
        content.sound = .default
        content.categoryIdentifier = "WEIGHT_CATEGORY"
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        // Only send weight reminders twice a week (Monday and Friday)
        dateComponents.weekday = 2 // Monday = 2
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weightLogReminder", content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling weight log reminder: \(error.localizedDescription)")
            }
        }
        
        // Add another reminder for Friday
        var fridayComponents = DateComponents()
        fridayComponents.hour = hour
        fridayComponents.minute = minute
        fridayComponents.weekday = 6 // Friday = 6
        
        let fridayTrigger = UNCalendarNotificationTrigger(dateMatching: fridayComponents, repeats: true)
        let fridayRequest = UNNotificationRequest(identifier: "weightLogReminderFriday", content: content, trigger: fridayTrigger)
        
        notificationCenter.add(fridayRequest) { error in
            if let error = error {
                print("Error scheduling Friday weight log reminder: \(error.localizedDescription)")
            }
        }
    }
    
    /// Add a new notification to the list
    func addNotification(title: String, message: String, type: AppNotification.NotificationType) {
        let newNotification = AppNotification(
            id: UUID(),
            title: title,
            message: message,
            date: Date(),
            isRead: false,
            type: type
        )
        
        notifications.insert(newNotification, at: 0)
        updateUnreadCount()
        saveNotificationsToStorage()
    }
    
    /// Mark a notification as read
    func markAsRead(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
            updateUnreadCount()
            saveNotificationsToStorage()
        }
    }
    
    /// Mark all notifications as read
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        updateUnreadCount()
        saveNotificationsToStorage()
    }
    
    /// Delete a notification
    func deleteNotification(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications.remove(at: index)
            updateUnreadCount()
            saveNotificationsToStorage()
        }
    }
    
    /// Clear all notifications
    func clearAllNotifications() {
        notifications.removeAll()
        updateUnreadCount()
        // Also mark that we've cleared the samples
        UserDefaults.standard.set(true, forKey: "samplesNotificationsLoaded")
        saveNotificationsToStorage()
    }
    
    /// Update the unread count
    func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
        
        // Update the app badge
        UNUserNotificationCenter.current().setBadgeCount(unreadCount)
    }
    
    /// Load sample notifications for demo purposes
    private func loadSampleNotifications() {
        let sampleNotifications = [
            AppNotification(
                id: UUID(),
                title: "Дасгалын цаг",
                message: "Өнөөдрийн дасгалаа хийх цаг болсон!",
                date: Date().addingTimeInterval(-3600),
                isRead: false,
                type: .workout
            ),
            AppNotification(
                id: UUID(),
                title: "Жин бүртгэх",
                message: "Жинг бүртгэх цаг болсон",
                date: Date().addingTimeInterval(-7200),
                isRead: false,
                type: .weight
            ),
            AppNotification(
                id: UUID(),
                title: "Усны хэрэглээ",
                message: "Өнөөдөр ус уухаа мартаж байна!",
                date: Date().addingTimeInterval(-10800),
                isRead: true,
                type: .water
            ),
            AppNotification(
                id: UUID(),
                title: "Амжилт!",
                message: "Таны нийт жин 3 кг буурсан байна!",
                date: Date().addingTimeInterval(-86400),
                isRead: true,
                type: .system
            )
        ]
        
        self.notifications = sampleNotifications
    }
} 