
//
//  SongRowView.swift
//  Music Stream
//

import SwiftUI

struct SongRowView: View {
    let song: Song
    var playlist: Playlist? = nil
    var onRemoved: ((Song) -> Void)? = nil
    
    @EnvironmentObject private var offlineManager: OfflineManager
    @EnvironmentObject private var apiService: APIService
    @EnvironmentObject private var connectivity: ConnectivityService
    
    @State private var showingAddToPlaylist = false
    @State private var showingDeleteConfirmation = false
    @State private var statusMessage: String?
    @State private var isPerformingAction = false
    
    private var isDownloaded: Bool { offlineManager.isSongDownloaded(song) }
    private var isDownloading: Bool { offlineManager.isSongDownloading(song) }
    private var canDownload: Bool { !connectivity.isOffline || isDownloaded }
    private var hasPlaylistContext: Bool { playlist != nil }
    
    var body: some View {
        HStack(spacing: 12) {
            let artURL = offlineManager.artworkURL(for: song) ?? URL(string: song.albumArtURL ?? "")
            AsyncImage(url: artURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 50, height: 50)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.body)
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(song.durationString)
                .font(.caption)
                .foregroundColor(.gray)
            
            Button(action: toggleDownload) {
                if isDownloading {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: isDownloaded ? "arrow.down.circle.fill" : "arrow.down.circle")
                        .foregroundColor(isDownloaded ? .green : .gray)
                }
            }
            .buttonStyle(.plain)
            .disabled(!canDownload || isDownloading)
            
            Menu {
                Button {
                    showingAddToPlaylist = true
                } label: {
                    Label("Add to Playlist", systemImage: "plus")
                }
                
                if hasPlaylistContext {
                    Button(role: .destructive) {
                        removeFromPlaylist()
                    } label: {
                        Label("Remove from Playlist", systemImage: "minus.circle")
                    }
                    .disabled(isPerformingAction)
                }
                
                Divider()
                
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete Permanently", systemImage: "trash")
                }
                .disabled(isPerformingAction)
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            .disabled(isPerformingAction)
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingAddToPlaylist) {
            AddToPlaylistSheet(song: song) { result in
                switch result {
                case .success(let playlistName):
                    statusMessage = "Added to \(playlistName)"
                case .failure(let error):
                    statusMessage = error.localizedDescription
                }
            }
        }
        .confirmationDialog("Delete \(song.title)?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Permanently", role: .destructive) {
                deleteSong()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes the song from your library and deletes any downloaded file.")
        }
        .alert("Song Action", isPresented: Binding(get: { statusMessage != nil }, set: { if !$0 { statusMessage = nil } })) {
            Button("OK", role: .cancel) { statusMessage = nil }
        } message: {
            Text(statusMessage ?? "")
        }
    }
    
    private func toggleDownload() {
        if isDownloaded {
            offlineManager.removeSong(song)
        } else {
            guard canDownload else { return }
            offlineManager.downloadSong(song, playlist: playlist, apiService: apiService)
        }
    }
    
    private func removeFromPlaylist() {
        guard let playlist = playlist else { return }
        let playlistName = playlist.name
        statusMessage = nil
        isPerformingAction = true
        apiService.removeTrackFromPlaylist(playlistId: playlist.id, musicId: song.id) { result in
            isPerformingAction = false
            switch result {
            case .success:
                statusMessage = "Removed from \(playlistName)"
                offlineManager.detach(song: song, from: playlist)
                NotificationCenter.default.post(name: .playlistsDidChange, object: nil)
                onRemoved?(song)
            case .failure(let error):
                statusMessage = error.localizedDescription
            }
        }
    }

    private func deleteSong() {
        statusMessage = nil
        isPerformingAction = true
        apiService.deleteTrack(musicId: song.id, deleteFile: true) { result in
            isPerformingAction = false
            switch result {
            case .success:
                offlineManager.removeSong(song)
                statusMessage = "Deleted permanently"
                NotificationCenter.default.post(name: .libraryDidChange, object: nil)
                NotificationCenter.default.post(name: .playlistsDidChange, object: nil)
                onRemoved?(song)
            case .failure(let error):
                statusMessage = error.localizedDescription
            }
        }
    }
}
