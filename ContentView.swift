//
//  ContentView.swift
//  Music Stream
//

import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var audioPlayer: AudioPlayerManager
    @EnvironmentObject var connectivity: ConnectivityService
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                
                SearchView()
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .tag(1)
                
                LibraryView()
                    .tabItem {
                        Label("Library", systemImage: "music.note.list")
                    }
                    .tag(2)
                
                DownloadsView()
                    .tabItem {
                        Label("Downloads", systemImage: "tray.and.arrow.down")
                    }
                    .tag(3)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(4)
                
            }
            .accentColor(.green)
            .onAppear {
                // Configure native tab bar appearance
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor.systemBackground
                
                // Selected tab item
                appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemGreen
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                    .foregroundColor: UIColor.systemGreen
                ]
                
                // Normal tab item
                appearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                    .foregroundColor: UIColor.secondaryLabel
                ]
                
                UITabBar.appearance().standardAppearance = appearance
                if #available(iOS 15.0, *) {
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
            }
            
            // Mini Player above tab bar
            if audioPlayer.currentSong != nil {
                VStack(spacing: 10) {
                    Capsule()
                        .fill(Color.primary.opacity(0.15))
                        .frame(width: 36, height: 4)
                    MiniPlayerView()
                        .environmentObject(audioPlayer)
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 72) // Lift mini player slightly above tab bar
            }
        }
        .overlay(alignment: .top) {
            if connectivity.isOffline {
                OfflineBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(APIService())
            .environmentObject(AudioPlayerManager())
            .environmentObject(ConnectivityService())
            .environmentObject(OfflineManager())
    }
}
