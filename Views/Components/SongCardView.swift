//
//  SongCardView.swift
//  Music Stream
//

import SwiftUI

struct SongCardView: View {
    let song: Song
    @EnvironmentObject private var apiService: APIService
    @EnvironmentObject private var offlineManager: OfflineManager
    
    @State private var songForPlaylist: Song?
    @State private var showingDeleteConfirmation = false
    @State private var statusMessage: String?
    @State private var isPerformingAction = false
    @State private var songPendingDelete: Song?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                let artURL = offlineManager.artworkURL(for: song) ?? URL(string: song.albumArtURL ?? "")
                AsyncImage(url: artURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 150, height: 150)
                .cornerRadius(10)
                
                // Song Info
                Text(song.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .frame(width: 150, alignment: .leading)
            
            Menu {
                Button {
                    prepareAddToPlaylist()
                } label: {
                    Label("Add to Playlist", systemImage: "plus")
                }
                
                Button(role: .destructive) {
                    removeFromLibrary()
                } label: {
                    Label("Remove from Library", systemImage: "minus.circle")
                }
                .disabled(isPerformingAction)
                
                Divider()
                
                Button(role: .destructive) {
                    prepareDelete()
                } label: {
                    Label("Delete Permanently", systemImage: "trash")
                }
                .disabled(isPerformingAction)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.black.opacity(0.45))
                    .clipShape(Circle())
            }
            .padding(6)
            .disabled(isPerformingAction)
        }
        .frame(width: 150, alignment: .topLeading)
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
                if let target = songPendingDelete {
                    performDelete(deleteFile: true, targetSong: target)
                } else {
                    performDelete(deleteFile: true, targetSong: song)
                }
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
    
    private func prepareAddToPlaylist() {
        guard apiService.isAuthenticated else {
            statusMessage = "Sign in to manage playlists."
            return
        }
        songForPlaylist = song
    }
    
    private func removeFromLibrary() {
        guard apiService.isAuthenticated else {
            statusMessage = "Sign in to manage your library."
            return
        }
        guard !isPerformingAction else { return }
        performDelete(deleteFile: false, targetSong: song)
    }
    
    private func prepareDelete() {
        guard apiService.isAuthenticated else {
            statusMessage = "Sign in to manage your library."
            return
        }
        guard !isPerformingAction else { return }
        songPendingDelete = song
        showingDeleteConfirmation = true
    }
    
    private func performDelete(deleteFile: Bool, targetSong: Song) {
        isPerformingAction = true
        apiService.deleteTrack(musicId: targetSong.id, deleteFile: deleteFile) { result in
            isPerformingAction = false
            switch result {
            case .success:
                offlineManager.removeSong(targetSong)
                statusMessage = deleteFile ? "Deleted permanently" : "Removed from library"
                NotificationCenter.default.post(name: .libraryDidChange, object: nil)
                NotificationCenter.default.post(name: .playlistsDidChange, object: nil)
            case .failure(let error):
                statusMessage = error.localizedDescription
            }
            if deleteFile {
                showingDeleteConfirmation = false
            }
            songPendingDelete = nil
        }
    }

}
