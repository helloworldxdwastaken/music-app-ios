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
    @State private var songForPlaylist: Song?
    @State private var songPendingDelete: Song?
    @State private var showingDeleteConfirmation = false
    @State private var statusMessage: String?
    @State private var isPerformingAction = false
    
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
                    .overlay(Color.black.opacity(0.6))
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
                                prepareAddToPlaylist()
                            } label: {
                                Label("Add to Playlist", systemImage: "text.badge.plus")
                            }

                            if hasPlaylistContext {
                                Button(role: .destructive) {
                                    removeCurrentSongFromPlaylist()
                                } label: {
                                    Label("Remove from Playlist", systemImage: "minus.circle")
                                }
                                .disabled(isPerformingAction)
                            }

                            Divider()

                            Button(role: .destructive) {
                                prepareDeleteCurrentSong()
                            } label: {
                                Label("Delete Permanently", systemImage: "trash")
                            }
                            .disabled(isPerformingAction)
                        } label: {
                            circleToolbarLabel(icon: "ellipsis")
                        }
                        .disabled(audioPlayer.currentSong == nil)
                    }
                    .padding()

                    Spacer()

                    // Album Art & Details
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
                .padding(.horizontal)
            }
        }
        .sheet(item: $songForPlaylist) { song in
            AddToPlaylistSheet(song: song) { result in
                switch result {
                case .success(let playlistName):
                    statusMessage = "Added to \(playlistName)"
                    NotificationCenter.default.post(name: .playlistsDidChange, object: nil)
                case .failure(let error):
                    statusMessage = error.localizedDescription
                }
            }
        }
        .confirmationDialog("Delete Song?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Permanently", role: .destructive) {
                deleteCurrentSong(deleteFile: true)
            }
            Button("Cancel", role: .cancel) {
                songPendingDelete = nil
            }
        } message: {
            Text("This removes the song from your library and deletes any downloaded file.")
        }
        .alert("Song Action", isPresented: Binding(get: { statusMessage != nil }, set: { if !$0 { statusMessage = nil } })) {
            Button("OK") { statusMessage = nil }
        } message: {
            Text(statusMessage ?? "")
        }
    }
    private func timeString(from seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension NowPlayingView {
    private var hasPlaylistContext: Bool {
        audioPlayer.currentPlaylist != nil
    }
    
    private func prepareAddToPlaylist() {
        guard apiService.isAuthenticated else {
            statusMessage = "Sign in to manage playlists."
            return
        }
        guard let song = audioPlayer.currentSong else { return }
        songForPlaylist = song
    }
    
    private func removeCurrentSongFromPlaylist() {
        guard !isPerformingAction,
              let playlist = audioPlayer.currentPlaylist,
              let song = audioPlayer.currentSong else { return }
        isPerformingAction = true
        apiService.removeTrackFromPlaylist(playlistId: playlist.id, musicId: song.id) { result in
            isPerformingAction = false
            switch result {
            case .success:
                statusMessage = "Removed from \(playlist.name)"
                offlineManager.detach(song: song, from: playlist)
                audioPlayer.removeCurrentSongFromQueue()
                NotificationCenter.default.post(name: .playlistsDidChange, object: nil)
            case .failure(let error):
                statusMessage = error.localizedDescription
            }
        }
    }
    
    private func prepareDeleteCurrentSong() {
        guard !isPerformingAction,
              let song = audioPlayer.currentSong else { return }
        songPendingDelete = song
        showingDeleteConfirmation = true
    }
    
    private func deleteCurrentSong(deleteFile: Bool) {
        guard let song = songPendingDelete else { return }
        isPerformingAction = true
        apiService.deleteTrack(musicId: song.id, deleteFile: deleteFile) { result in
            isPerformingAction = false
            switch result {
            case .success:
                offlineManager.removeSong(song)
                audioPlayer.removeCurrentSongFromQueue()
                NotificationCenter.default.post(name: .libraryDidChange, object: nil)
                NotificationCenter.default.post(name: .playlistsDidChange, object: nil)
                statusMessage = deleteFile ? "Deleted permanently" : "Removed from library"
            case .failure(let error):
                statusMessage = error.localizedDescription
            }
            showingDeleteConfirmation = false
            songPendingDelete = nil
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
