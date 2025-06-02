//
//  NotificationsView.swift
//  BeFit
//
//  Created by Chinguun Khongor
//

import SwiftUI

struct NotificationsView: View {
    @ObservedObject var viewModel: NotificationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.notifications.isEmpty {
                    Section {
                        VStack(spacing: 20) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("Одоогоор мэдэгдэл байхгүй байна")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .listRowBackground(Color.clear)
                    }
                } else {
                    ForEach(viewModel.notifications) { notification in
                        NotificationRow(notification: notification) {
                            viewModel.markAsRead(notification)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            viewModel.deleteNotification(viewModel.notifications[index])
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Мэдэгдэлүүд")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Хаах") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.notifications.isEmpty {
                        Menu {
                            Button {
                                viewModel.markAllAsRead()
                            } label: {
                                Label("Бүгдийг уншсан болгох", systemImage: "checkmark.circle")
                            }
                            
                            Button(role: .destructive) {
                                viewModel.clearAllNotifications()
                            } label: {
                                Label("Бүгдийг устгах", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotification
    let onReadAction: () -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            notificationIcon
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)
                    .fontWeight(notification.isRead ? .regular : .semibold)
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.leading, 4)
            .contentShape(Rectangle())
            .onTapGesture {
                if !notification.isRead {
                    onReadAction()
                }
            }
            
            Spacer()
            
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 8)
        
    }
    
    private var notificationIcon: some View {
        Image(systemName: iconName)
    }
    
    private var iconName: String {
        switch notification.type {
        case .workout:
            return "figure.walk"
        case .weight:
            return "scalemass.fill"
        case .meal:
            return "fork.knife"
        case .water:
            return "drop.fill"
        case .system:
            return "bell.fill"
        }
    }
    
    private var iconColor: Color {
        switch notification.type {
        case .workout:
            return .green
        case .weight:
            return .blue
        case .meal:
            return .orange
        case .water:
            return .cyan
        case .system:
            return .purple
        }
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: notification.date, relativeTo: Date())
    }
}

#Preview {
    NotificationsView(viewModel: NotificationViewModel())
} 
