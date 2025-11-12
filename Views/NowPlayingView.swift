//
//  NowPlayingView.swift
//  Music Stream
//

import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var audioPlayer: AudioPlayerManager
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var offlineManager: OfflineManager
    @Environment(\.dismiss) var dismiss
    @State private var showingPlaylistSheet = false
    @State private var availablePlaylists: [Playlist] = []
    @State private var isLoadingPlaylists = false
    @State private var downloadStatus: String?
    @State private var showingDownloadAlert = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Blurred artwork background
                if let currentSong = audioPlayer.currentSong {
                    let artURL = offlineManager.artworkURL(for: currentSong) ?? URL(string: currentSong.albumArtURL ?? "")
                    AsyncImage(url: artURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.black
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .blur(radius: 50)
                    .overlay(
                        Color.black.opacity(0.6)
                    )
                    .ignoresSafeArea()
                } else {
                    Color.black
                        .ignoresSafeArea()
                }
            
            VStack {
                // Header
                HStack {
                    circleToolbarButton(icon: "chevron.down") {
                        dismiss()
                    }
                    Spacer()
                    Text("Now Playing")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Menu {
                        Button {
                            presentPlaylistSheet()
                        } label: {
                            Label("Add to Playlist", systemImage: "text.badge.plus")
                        }
                    } label: {
                        circleToolbarLabel(icon: "ellipsis")
                    }
                }
                .padding()
                
                Spacer()
                
                // Album Art
                if let currentSong = audioPlayer.currentSong {
                    let artURL = offlineManager.artworkURL(for: currentSong) ?? URL(string: currentSong.albumArtURL ?? "")
                    AsyncImage(url: artURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 80))
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 300, height: 300)
                    .cornerRadius(20)
                    .shadow(color: audioPlayer.isPlaying ? Color.green.opacity(0.6) : Color.clear, radius: audioPlayer.isPlaying ? 30 : 10, x: 0, y: audioPlayer.isPlaying ? 15 : 5)
                    .scaleEffect(audioPlayer.isPlaying ? 1.0 : 0.93)
                    .animation(.spring(response: 0.45, dampingFraction: 0.65), value: audioPlayer.isPlaying)
                    
                    // Song Info
                    VStack(spacing: 8) {
                        Text(currentSong.title)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                        Text(currentSong.artist)
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 30)
                    
                    // Progress Bar
                    VStack(spacing: 8) {
                        Slider(value: $audioPlayer.currentTime, in: 0...audioPlayer.duration) { editing in
                            if !editing {
                                audioPlayer.seek(to: audioPlayer.currentTime)
                            }
                        }
                        .accentColor(.green)
                        
                        HStack {
                            Text(timeString(from: audioPlayer.currentTime))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            Text(timeString(from: audioPlayer.duration))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    
                    // Controls
                    HStack(spacing: 40) {
                        Button(action: audioPlayer.previousTrack) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: audioPlayer.togglePlayPause) {
                            Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 70))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: audioPlayer.nextTrack) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 20)
                    
                } else {
                    Text("No song playing")
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            }
        }
        .sheet(isPresented: $showingPlaylistSheet) {
            playlistSheet
        }
        .alert("Playlist", isPresented: Binding(get: { downloadStatus != nil }, set: { if !$0 { downloadStatus = nil } })) {
            Button("OK") { downloadStatus = nil }
        } message: {
            Text(downloadStatus ?? "")
        }
    }
    
    private func timeString(from seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension NowPlayingView {
    private func presentPlaylistSheet() {
        guard apiService.isAuthenticated else {
            downloadStatus = "Sign in to manage playlists."
            return
        }
        showingPlaylistSheet = true
        if availablePlaylists.isEmpty {
            isLoadingPlaylists = true
            apiService.fetchPlaylists { result in
                isLoadingPlaylists = false
                switch result {
                case .success(let playlists):
                    availablePlaylists = playlists
                case .failure(let error):
                    downloadStatus = error.localizedDescription
                    showingPlaylistSheet = false
                }
            }
        }
    }
    
    private var playlistSheet: some View {
        NavigationView {
            VStack {
                if isLoadingPlaylists {
                    ProgressView("Loading playlists…")
                        .padding()
                } else if availablePlaylists.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "music.note.list")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No playlists available.")
                            .foregroundColor(.secondary)
                        Button("Create Playlist in Library") {
                            showingPlaylistSheet = false
                        }
                        .padding(.top, 10)
                    }
                } else {
                    List(availablePlaylists) { playlist in
                        Button {
                            addCurrentSong(to: playlist)
                        } label: {
                            HStack {
                                Text(playlist.name)
                                Spacer()
                                Text("\(playlist.songCount) songs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Add to Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showingPlaylistSheet = false }
                }
            }
        }
        .presentationCompat()
    }
    
    private func addCurrentSong(to playlist: Playlist) {
        guard let song = audioPlayer.currentSong else { return }
        showingPlaylistSheet = false
        apiService.addSong(song.id, to: playlist.id) { result in
            switch result {
            case .success:
                downloadStatus = "Added to \(playlist.name)."
            case .failure(let error):
                downloadStatus = error.localizedDescription
            }
        }
    }
    
    private func circleToolbarButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            circleToolbarLabel(icon: icon)
        }
        .buttonStyle(.plain)
    }
    
    private func circleToolbarLabel(icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 34, height: 34)
            .background(Color.white.opacity(0.2))
            .clipShape(Circle())
    }
}

struct NowPlayingView_Previews: PreviewProvider {
    static var previews: some View {
        NowPlayingView()
            .environmentObject(AudioPlayerManager())
            .environmentObject(APIService())
            .environmentObject(OfflineManager())
    }
}
