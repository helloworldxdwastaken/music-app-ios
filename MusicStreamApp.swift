//
//  MusicStreamApp.swift
//  Music Stream
//
//  Created for AltStore Installation
//

import SwiftUI

@main
struct MusicStreamApp: App {
    @StateObject private var audioPlayer = AudioPlayerManager()
    @StateObject private var apiService = APIService()
    @StateObject private var offlineManager = OfflineManager()
    @StateObject private var connectivity = ConnectivityService()
    
    init() {
        configureNavigationAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(audioPlayer)
                .environmentObject(apiService)
                .environmentObject(offlineManager)
                .environmentObject(connectivity)
                .preferredColorScheme(.dark)
                .onAppear {
                    audioPlayer.configure(with: apiService, offlineManager: offlineManager)
                }
        }
    }
    
    private func configureNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        appearance.shadowColor = UIColor(white: 1.0, alpha: 0.05)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 32, weight: .bold)
        ]
        
        let navigationBar = UINavigationBar.appearance()
        navigationBar.standardAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.isTranslucent = false
    }
}

extension View {
    @ViewBuilder
    func applyDarkNavBar() -> some View {
        if #available(iOS 16.0, *) {
            self
                .toolbarBackground(Color.black.opacity(0.95), for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        } else {
            self
        }
    }
}
