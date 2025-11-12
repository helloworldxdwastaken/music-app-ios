//
//  CustomTabBarView.swift
//  Music Stream
//

import SwiftUI

struct CustomTabBarView: View {
    struct TabItem: Identifiable {
        let id = UUID()
        let title: String
        let systemImage: String
        let tag: Int
    }

    let items: [TabItem]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 24) {
            ForEach(items) { item in
                Button {
                    selection = item.tag
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 18, weight: .semibold))
                        Text(item.title)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(selection == item.tag ? .white : Color.white.opacity(0.7))
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 58, height: 58)
                .background(LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.25), radius: 10, y: 8)
        }
    }
}

struct SearchFloatingButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 52, height: 52)
                .background(Color.black.opacity(0.8))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.25), radius: 10, y: 8)
        }
    }
}
