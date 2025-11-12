//
//  MiniPlayerView.swift
//  Music Stream
//

import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject var audioPlayer: AudioPlayerManager
    @EnvironmentObject var offlineManager: OfflineManager
    @State private var showingPlayer = false
    
    var body: some View {
        if let currentSong = audioPlayer.currentSong {
            HStack(spacing: 16) {
                albumArt(for: currentSong)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentSong.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(currentSong.artist)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 12)
                
                Button(action: {
                    audioPlayer.togglePlayPause()
                }) {
                    Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green, Color.mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: Color.green.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.8)
                    )
            )
            .shadow(color: Color.black.opacity(0.25), radius: 14, y: 6)
            .contentShape(Rectangle())
            .onTapGesture {
                showingPlayer = true
            }
            .gesture(
                DragGesture(minimumDistance: 15, coordinateSpace: .local)
                    .onEnded { value in
                        if value.translation.height < -30 {
                            showingPlayer = true
                        }
                    }
            )
            .sheet(isPresented: $showingPlayer) {
                NowPlayingView()
            }
        }
    }
    
    @ViewBuilder
    private func albumArt(for song: Song) -> some View {
        let artURL = offlineManager.artworkURL(for: song) ?? URL(string: song.albumArtURL ?? "")
        AsyncImage(url: artURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.gray.opacity(0.2))
                Image(systemName: "music.note")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: audioPlayer.isPlaying ? Color.green.opacity(0.25) : Color.black.opacity(0.08), radius: 12, y: 6)
    }
}

struct MiniPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        MiniPlayerView()
            .environmentObject(AudioPlayerManager())
            .environmentObject(OfflineManager())
    }
}
