//
//  SongCardView.swift
//  Music Stream
//

import SwiftUI

struct SongCardView: View {
    let song: Song
    @EnvironmentObject private var offlineManager: OfflineManager
    
    var body: some View {
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
        .frame(width: 150)
    }
}
