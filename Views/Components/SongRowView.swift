//
//  SongRowView.swift
//  Music Stream
//

import SwiftUI

struct SongRowView: View {
    let song: Song
    var playlist: Playlist? = nil
    @EnvironmentObject private var offlineManager: OfflineManager
    @EnvironmentObject private var apiService: APIService
    @EnvironmentObject private var connectivity: ConnectivityService
    
    private var isDownloaded: Bool { offlineManager.isSongDownloaded(song) }
    private var isDownloading: Bool { offlineManager.isSongDownloading(song) }
    private var canDownload: Bool { !connectivity.isOffline || isDownloaded }
    
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
            
            // Song Info
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
            
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func toggleDownload() {
        if isDownloaded {
            offlineManager.removeSong(song)
        } else {
            guard canDownload else { return }
            offlineManager.downloadSong(song, playlist: playlist, apiService: apiService)
        }
    }
}
