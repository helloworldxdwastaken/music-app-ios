//
//  PlaylistRowView.swift
//  Music Stream
//

import SwiftUI

struct PlaylistRowView: View {
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var offlineManager: OfflineManager
    let playlist: Playlist
    @State private var firstSongArtworkURL: String?
    @State private var isLoadingArtwork = false
    
    var body: some View {
        HStack(spacing: 15) {
            // Playlist Cover - Use first song's artwork or fallback
            AsyncImage(url: artworkURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.3))
                    .overlay(
                        Image(systemName: "music.note.list")
                            .foregroundColor(.white)
                            .font(.title)
                    )
            }
            .frame(width: 80, height: 80)
            .cornerRadius(10)
            
            // Playlist Info
            VStack(alignment: .leading, spacing: 6) {
                Text(playlist.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(playlist.songCount) songs")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if let description = playlist.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .onAppear {
            loadFirstSongArtwork()
        }
    }
    
    // Determine which artwork URL to use
    private var artworkURL: URL? {
        if let offlineURL = offlineManager.playlistArtworkURL(playlist.id) {
            return offlineURL
        }
        if let firstSongURL = firstSongArtworkURL, !firstSongURL.isEmpty {
            return URL(string: firstSongURL)
        } else if let coverURL = playlist.coverURL, !coverURL.isEmpty {
            if coverURL.hasPrefix("file://") {
                return URL(string: coverURL)
            }
            return URL(string: coverURL)
        }
        return nil
    }
    
    // Load the first song from the playlist to get its artwork
    private func loadFirstSongArtwork() {
        // Only fetch if we don't have artwork yet and playlist has songs
        guard firstSongArtworkURL == nil, playlist.songCount > 0, !isLoadingArtwork else { return }
        if offlineManager.isPlaylistDownloaded(playlist.id) { return }
        
        isLoadingArtwork = true
        apiService.fetchPlaylistSongs(playlistId: playlist.id) { result in
            isLoadingArtwork = false
            switch result {
            case .success(let songs):
                // Use the first song's artwork
                if let firstSong = songs.first, let artworkURL = firstSong.albumArtURL {
                    firstSongArtworkURL = artworkURL
                }
            case .failure:
                // Silently fail - will use placeholder
                break
            }
        }
    }
}
