
//
//  AddToPlaylistSheet.swift
//  Music Stream
//

import SwiftUI

struct AddToPlaylistSheet: View {
    let song: Song
    var completion: ((Result<String, Error>) -> Void)? = nil
    
    @EnvironmentObject private var apiService: APIService
    @Environment(\.dismiss) private var dismiss
    
    @State private var playlists: [Playlist] = []
    @State private var isLoading = false
    @State private var isProcessingSelection = false
    @State private var statusMessage: String?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading playlists...")
                        .progressViewStyle(.circular)
                } else if playlists.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.6))
                        Text("You don’t have any playlists yet.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("Create a playlist first to add this song.")
                            .font(.footnote)
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .multilineTextAlignment(.center)
                    .padding()
                } else {
                    List(playlists) { playlist in
                        Button(action: { addSong(to: playlist) }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(playlist.name)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    if let description = playlist.description, !description.isEmpty {
                                        Text(description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                if isProcessingSelection {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                        .disabled(isProcessingSelection)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .padding(.top, playlists.isEmpty ? 24 : 0)
            .navigationTitle("Add to Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear(perform: loadPlaylists)
            .alert("Add to Playlist", isPresented: Binding(get: { statusMessage != nil }, set: { if !$0 { statusMessage = nil } })) {
                Button("OK", role: .cancel) { statusMessage = nil }
            } message: {
                Text(statusMessage ?? "")
            }
        }
    }
    
    private func loadPlaylists() {
        isLoading = true
        apiService.fetchPlaylists { result in
            isLoading = false
            switch result {
            case .success(let fetched):
                playlists = fetched
            case .failure(let error):
                statusMessage = error.localizedDescription
            }
        }
    }
    
    private func addSong(to playlist: Playlist) {
        isProcessingSelection = true
        apiService.addTrackToPlaylist(playlistId: playlist.id, musicId: song.id, completion: { result in
            isProcessingSelection = false
            switch result {
            case .success:
                NotificationCenter.default.post(name: .playlistsDidChange, object: nil)
                completion?(.success(playlist.name))
                dismiss()
            case .failure(let error):
                statusMessage = error.localizedDescription
                completion?(.failure(error))
            }
        })
    }
}
