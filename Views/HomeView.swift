//
//  HomeView.swift
//  Music Stream
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var audioPlayer: AudioPlayerManager
    @EnvironmentObject var offlineManager: OfflineManager
    @State private var songs: [Song] = []
    @State private var isLoading = false
    @State private var showingPlayer = false
    @State private var stats: LibraryStats?
    @State private var isLoadingStats = false
    @State private var heroArtworkURL: URL?
    @State private var artworkTimer: Timer?
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [Color.black, Color(red: 0.05, green: 0.05, blue: 0.08)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if !apiService.isAuthenticated {
                            stateCard(
                                systemImage: "lock.shield.fill",
                                title: "Sign in to view your library",
                                subtitle: "Sync your playlists and keep downloads up to date."
                            ) {
                                apiService.logout()
                            }
                        }
                        
                        heroCard
                        
                        statsSection
                        
                        // Recently Added Grid
                        if !songs.isEmpty {
                            sectionContainer(title: "Recently Added") {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 2), spacing: 14) {
                                    ForEach(songs.prefix(9)) { song in
                                        SongCardView(song: song)
                                            .frame(maxWidth: .infinity)
                                            .onTapGesture {
                                                playSong(song)
                                            }
                                    }
                                }
                            }
                        } else if apiService.isAuthenticated {
                            sectionContainer(title: "Recently Added") {
                                emptySectionPlaceholder(
                                    icon: "sparkles",
                                    title: "No recent plays yet",
                                    subtitle: "Start listening and your latest tracks will appear here."
                                )
                            }
                        }
                    }
                    .padding(.vertical)
                    .padding(.bottom, 80)
                }
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .applyDarkNavBar()
            .onAppear {
                if songs.isEmpty && apiService.isAuthenticated {
                    loadSongs()
                }
                if stats == nil && apiService.isAuthenticated {
                    loadStats()
                }
                startArtworkRotation()
                refreshHeroArtwork()
            }
            .onDisappear { stopArtworkRotation() }
            .sheet(isPresented: $showingPlayer) {
                NowPlayingView()
            }
        }
        .onChange(of: audioPlayer.currentSong?.id) { _ in
            refreshHeroArtwork()
        }
        .onChange(of: songs.count) { _ in
            if audioPlayer.currentSong == nil {
                refreshHeroArtwork()
            }
        }
    }
    
    private func loadSongs() {
        guard apiService.isAuthenticated else {
            songs = []
            return
        }
        isLoading = true
        apiService.fetchSongs { result in
            isLoading = false
            switch result {
            case .success(let fetchedSongs):
                songs = Array(fetchedSongs.prefix(9))
                if audioPlayer.currentSong == nil {
                    refreshHeroArtwork()
                }
            case .failure(let error):
                print("Error loading songs: \(error.localizedDescription)")
                if let apiError = error as? APIError, apiError == .unauthorized {
                    songs = []
                }
            }
        }
    }
    
    private func loadStats() {
        guard apiService.isAuthenticated else {
            stats = nil
            return
        }
        isLoadingStats = true
        apiService.fetchLibraryStats { result in
            isLoadingStats = false
            switch result {
            case .success(let fetched):
                stats = fetched
            case .failure(let error):
                print("Stats error: \(error.localizedDescription)")
                stats = nil
            }
        }
    }
    
    private func playSong(_ song: Song) {
        audioPlayer.play(song: song)
        showingPlayer = true
    }
    
    private func refreshHeroArtwork() {
        if let currentSong = audioPlayer.currentSong {
            if let url = offlineManager.artworkURL(for: currentSong) ?? URL(string: currentSong.albumArtURL ?? "") {
                heroArtworkURL = url
                return
            }
        }
        heroArtworkURL = randomArtworkURL()
    }
    
    private func startArtworkRotation() {
        artworkTimer?.invalidate()
        artworkTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            if audioPlayer.currentSong == nil {
                heroArtworkURL = randomArtworkURL()
            }
        }
        if let timer = artworkTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopArtworkRotation() {
        artworkTimer?.invalidate()
        artworkTimer = nil
    }
    
    private func randomArtworkURL() -> URL? {
        let candidates = songs + offlineManager.allDownloadedSongs
        let shuffled = candidates.shuffled()
        for song in shuffled {
            if let url = offlineManager.artworkURL(for: song) {
                return url
            }
            if let art = song.albumArtURL, let url = URL(string: art) {
                return url
            }
        }
        return nil
    }
    
    private var heroCard: some View {
        let cardShape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        return VStack(alignment: .leading, spacing: 16) {
            Text(greetingMessage)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            Text("Welcome to Noxa Music")
                .font(.system(.largeTitle, design: .rounded))
                .bold()
                .foregroundColor(.white)
                .lineLimit(2)
            
            if let currentSong = audioPlayer.currentSong {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Continue listening")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Text(currentSong.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(currentSong.artist)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Button(action: resumePlayback) {
                Label(audioPlayer.currentSong == nil ? "Shuffle Library" : "Resume Playback", systemImage: "play.fill")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 18)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.15), radius: 12, y: 6)
            }
            .disabled(songs.isEmpty && audioPlayer.currentSong == nil)
            .opacity((songs.isEmpty && audioPlayer.currentSong == nil) ? 0.6 : 1)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            GeometryReader { geo in
                let size = geo.size
                cardShape
                    .fill(
                        LinearGradient(colors: [.green.opacity(0.95), .blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay {
                if let artwork = heroArtworkURL {
                    AsyncImage(url: artwork) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: size.width, height: size.height)
                                    .clipped()
                            } placeholder: {
                                Color.clear
                            }
                            .opacity(0.35)
                            .blur(radius: 6)
                            .allowsHitTesting(false)
                        }
                    }
                    .overlay {
                        cardShape
                            .stroke(Color.white.opacity(0.1), lineWidth: 0)
                            .background(
                                cardShape
                                    .fill(
                                        LinearGradient(colors: [Color.black.opacity(0.15), Color.black.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                                    )
                            )
                    }
            }
            .clipShape(cardShape)
        )
        .overlay(
            cardShape
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.green.opacity(0.35), radius: 20, y: 10)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var statsSection: some View {
        if let stats = stats {
            HStack(spacing: 16) {
                statsMetric(label: "Songs", value: "\(stats.totalSongs)")
                statsMetric(label: "Artists", value: "\(stats.totalArtists)")
                statsMetric(label: "Albums", value: "\(stats.totalAlbums)")
                statsMetric(label: "Storage", value: formattedStorage(bytes: stats.totalStorageBytes))
            }
            .padding(.horizontal)
        } else if isLoadingStats {
            ProgressView("Loading library stats…")
                .tint(.white)
                .padding(.horizontal)
        }
    }
    
    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }
    
    private func statsMetric(label: String, value: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value ?? "--")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func formattedStorage(bytes: Int?) -> String? {
        guard let bytes else { return nil }
        let gigabytes = Double(bytes) / 1_073_741_824
        if gigabytes >= 1 {
            return "\(Int(gigabytes)) GB"
        }
        let megabytes = Double(bytes) / 1_048_576
        return "\(Int(max(megabytes, 1))) MB"
    }
    
    @ViewBuilder
    private func sectionContainer<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2.bold())
                .padding(.horizontal)
                .padding(.top, 8)
            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .padding(.top, 12)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 18, y: 8)
        )
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func emptySectionPlaceholder(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private func stateCard(systemImage: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(subtitle)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.7))
            Button(action: action) {
                Text("Open Sign In")
                    .fontWeight(.semibold)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 24)
                    .background(Color.white.opacity(0.18))
                    .foregroundColor(.black)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    private func resumePlayback() {
        if let currentSong = audioPlayer.currentSong {
            audioPlayer.play(song: currentSong)
            showingPlayer = true
        } else if let song = songs.randomElement() {
            playSong(song)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(APIService())
            .environmentObject(AudioPlayerManager())
    }
}
