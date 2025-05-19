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

struct AppNotification: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let date: Date
    var isRead: Bool = false
    var type: NotificationType
    
    enum NotificationType {
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
        
        // Load sample notifications for demo purposes
        loadSampleNotifications()
        
        // Calculate unread count
        updateUnreadCount()
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
        let content = UNMutableNotificationContent()
        content.title = "Дасгалын цаг"
        content.body = "Өнөөдрийн дасгалаа хийх цаг болсон!"
        content.sound = .default
        content.categoryIdentifier = "WORKOUT_CATEGORY"
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "workoutReminder", content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling workout reminder: \(error.localizedDescription)")
            }
        }
    }
    
    /// Schedule a daily weight log reminder
    func scheduleWeightLogReminder(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Жин бүртгэх"
        content.body = "Өнөөдрийн жингээ бүртгээгүй байна!"
        content.sound = .default
        content.categoryIdentifier = "WEIGHT_CATEGORY"
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weightLogReminder", content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling weight log reminder: \(error.localizedDescription)")
            }
        }
    }
    
    /// Add a new notification to the list
    func addNotification(title: String, message: String, type: AppNotification.NotificationType) {
        let newNotification = AppNotification(
            title: title,
            message: message,
            date: Date(),
            isRead: false,
            type: type
        )
        
        notifications.insert(newNotification, at: 0)
        updateUnreadCount()
    }
    
    /// Mark a notification as read
    func markAsRead(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
            updateUnreadCount()
        }
    }
    
    /// Mark all notifications as read
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        updateUnreadCount()
    }
    
    /// Delete a notification
    func deleteNotification(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications.remove(at: index)
            updateUnreadCount()
        }
    }
    
    /// Clear all notifications
    func clearAllNotifications() {
        notifications.removeAll()
        updateUnreadCount()
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
                title: "Дасгалын цаг",
                message: "Өнөөдрийн дасгалаа хийх цаг болсон!",
                date: Date().addingTimeInterval(-3600),
                isRead: false,
                type: .workout
            ),
            AppNotification(
                title: "Жин бүртгэх",
                message: "Жинг бүртгэх цаг болсон",
                date: Date().addingTimeInterval(-7200),
                isRead: false,
                type: .weight
            ),
            AppNotification(
                title: "Усны хэрэглээ",
                message: "Өнөөдөр ус уухаа мартаж байна!",
                date: Date().addingTimeInterval(-10800),
                isRead: true,
                type: .water
            ),
            AppNotification(
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