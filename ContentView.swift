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
    @EnvironmentObject var offlineManager: OfflineManager
    @State private var selectedTab = 0
    @State private var showingCreateSheet = false
    @State private var showingSearch = false

    private let tabItems: [CustomTabBarView.TabItem] = [
        .init(title: "Home", systemImage: "house.fill", tag: 0),
        .init(title: "Library", systemImage: "music.note.list", tag: 1),
        .init(title: "Create", systemImage: "plus.circle", tag: 2)
    ]

    init() {
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)

                LibraryView()
                    .tabItem {
                        Label("Library", systemImage: "music.note.list")
                    }
                    .tag(1)

                Color.clear
                    .tabItem {
                        Label("Create", systemImage: "plus.circle")
                    }
                    .tag(2)
            }
            .ignoresSafeArea()

            VStack(spacing: 18) {
                if audioPlayer.currentSong != nil {
                    MiniPlayerView()
                        .environmentObject(audioPlayer)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                }

                HStack(alignment: .center, spacing: 18) {
                    CustomTabBarView(items: tabItems, selection: $selectedTab)
                    SearchFloatingButton {
                        showingSearch = true
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 32)
        }
        .overlay(alignment: .top) {
            if connectivity.isOffline {
                OfflineBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreatePlaylistSheet()
                .presentationDetents([.medium, .large])
        }
        .fullScreenCover(isPresented: $showingSearch) {
            SearchView()
                .overlay(alignment: .topTrailing) {
                    Button {
                        showingSearch = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                            .padding(.top, 20)
                            .padding(.trailing, 20)
                    }
                }
        }
        .onChange(of: selectedTab) { newValue in
            if newValue == 2 {
                showingCreateSheet = true
                selectedTab = 1
            }
        }
        .onChange(of: connectivity.isOffline) { offline in
            if !offline {
                offlineManager.retryMissingArtwork()
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
