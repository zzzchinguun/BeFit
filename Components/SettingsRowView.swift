//
//  SettingsRowView.swift
//  BeFit
//
//  Created by Chinguun Khongor on 3/14/25.
//

import SwiftUI

struct SettingsRowView: View {
    let imageName: String
    let title: String
    let tintColor: Color
    let isDeleteButton: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: imageName)
                .imageScale(.small)
                .font(.title)
                .foregroundStyle(tintColor)
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(isDeleteButton ? Color.red : Color.primary)
        }
    }
}

#Preview {
    SettingsRowView(imageName: "gear", title: "Version", tintColor: Color(.systemGray), isDeleteButton: true)
}
