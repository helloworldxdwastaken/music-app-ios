//
//  PlaylistDetailView.swift
//  Music Stream
//

import SwiftUI

struct PlaylistDetailView: View {
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var audioPlayer: AudioPlayerManager
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var offlineManager: OfflineManager
    @EnvironmentObject var connectivity: ConnectivityService
    let playlist: Playlist
    @State private var songs: [Song] = []
    @State private var isLoading = false
    @State private var showingPlayer = false
    @State private var playlistTitle: String
    @State private var playlistDescription: String
    @State private var showingEditDetails = false
    @State private var showingReorder = false
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var tempSongs: [Song] = []
    @State private var editStatus: String?
    @State private var usedOfflineDataset = false
    
    private var isOfflineDownloaded: Bool {
        offlineManager.isPlaylistDownloaded(playlist.id)
    }
    private var isOfflineDownloading: Bool {
        offlineManager.isPlaylistDownloading(playlist.id)
    }
    private var offlineProgress: Double {
        offlineManager.downloadProgress[playlist.id] ?? 0
    }
    
    init(playlist: Playlist) {
        self.playlist = playlist
        _playlistTitle = State(initialValue: playlist.name)
        _playlistDescription = State(initialValue: playlist.description ?? "")
    }
    
    // Get artwork URL - prioritize first song's artwork
    private var artworkURL: URL? {
        if let offlineURL = offlineManager.playlistArtworkURL(playlist.id) {
            return offlineURL
        }
        if let firstSong = songs.first {
            if let url = offlineManager.artworkURL(for: firstSong) {
                return url
            }
            if let artworkURL = firstSong.albumArtURL {
                return URL(string: artworkURL)
            }
        } else if let coverURL = playlist.coverURL, !coverURL.isEmpty {
            if coverURL.hasPrefix("file://") {
                return URL(string: coverURL)
            }
            return URL(string: coverURL)
        }
        return nil
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Playlist Header
                VStack(spacing: 15) {
                    AsyncImage(url: artworkURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.blue.opacity(0.3))
                            .overlay(
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(width: 200, height: 200)
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    
                    VStack(spacing: 8) {
                        Text(playlistTitle)
                            .font(.title)
                            .bold()
                        Button(action: toggleOfflineDownload) {
                            Label(isOfflineDownloaded ? "Downloaded" : "Download offline", systemImage: isOfflineDownloaded ? "arrow.down.circle.fill" : "arrow.down.circle")
                                .font(.subheadline.weight(.semibold))
                                .labelStyle(.titleAndIcon)
                                .foregroundColor(isOfflineDownloaded ? .green : .white)
                        }
                        .buttonStyle(.plain)
                        .disabled(connectivity.isOffline && !isOfflineDownloaded)
                    }
                    
                    if !playlistDescription.isEmpty {
                        Text(playlistDescription)
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    
                    Text("\(playlist.songCount) songs")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button(action: playAll) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Play All")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        )
                        .foregroundColor(.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    if isOfflineDownloading {
                        ProgressView(value: offlineProgress)
                            .tint(.green)
                            .padding(.horizontal)
                    }
                    if connectivity.isOffline && !isOfflineDownloaded {
                        Text("Offline mode: download when you're online.")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .padding(.horizontal)
                    } else if isOfflineDownloaded {
                        Text("Playlist ready for offline playback")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal)
                    }
                }
                .padding()
                
                // Songs List
                if isLoading {
                    ProgressView()
                        .padding()
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(songs) { song in
                            SongRowView(song: song, playlist: playlist, onRemoved: handleSongRemoval)
                                .onTapGesture {
                                    playSong(song)
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 32)
            .padding(.bottom, 80)
        }
        .navigationBarTitleDisplayMode(.inline)
        .applyDarkNavBar()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Edit Details") { showingEditDetails = true }
                    Button("Reorder Songs") {
                        tempSongs = songs
                        showingReorder = true
                    }
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Text("Delete Playlist")
                    }
                    .disabled(isDeleting)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingPlayer) {
            NowPlayingView()
        }
        .sheet(isPresented: $showingEditDetails) {
            editDetailsSheet
        }
        .sheet(isPresented: $showingReorder) {
            reorderSheet
        }
        .confirmationDialog("Delete Playlist?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Playlist", role: .destructive) {
                deletePlaylist()
            }
            Button("Cancel", role: .cancel) {
                showingDeleteConfirmation = false
            }
        } message: {
            Text("This playlist will be removed from your library.")
        }
        .alert("Playlist", isPresented: Binding(get: { editStatus != nil }, set: { if !$0 { editStatus = nil } })) {
            Button("OK") { editStatus = nil }
        } message: {
            Text(editStatus ?? "")
        }
        .onAppear {
            loadPlaylistSongs()
        }
        .onChange(of: connectivity.isOffline) { offline in
            if offline {
                songs = offlineManager.songs(forPlaylist: playlist.id)
            } else if usedOfflineDataset {
                loadPlaylistSongs()
            }
        }
    }
    
    @ViewBuilder
    private var editDetailsSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField("Playlist Name", text: $playlistTitle)
                }
                Section(header: Text("Description")) {
                    TextField("Description", text: $playlistDescription)
                }
            }
            .navigationTitle("Edit Playlist")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        playlistTitle = playlist.name
                        playlistDescription = playlist.description ?? ""
                        showingEditDetails = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDetails()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var reorderSheet: some View {
        NavigationView {
            List {
                ForEach(tempSongs) { song in
                    Text(song.title)
                }
                .onMove { indices, newOffset in
                    tempSongs.move(fromOffsets: indices, toOffset: newOffset)
                }
            }
            .environment(\.editMode, .constant(EditMode.active))
            .navigationTitle("Reorder Songs")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingReorder = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveReorder() }
                }
            }
        }
    }
    
    private func loadPlaylistSongs() {
        if connectivity.isOffline {
            songs = offlineManager.songs(forPlaylist: playlist.id)
            usedOfflineDataset = true
            return
        }
        isLoading = true
        apiService.fetchPlaylistSongs(playlistId: playlist.id) { result in
            isLoading = false
            switch result {
            case .success(let fetchedSongs):
                songs = fetchedSongs
                usedOfflineDataset = false
            case .failure(let error):
                print("Error loading playlist songs: \(error.localizedDescription)")
                let offline = offlineManager.songs(forPlaylist: playlist.id)
                if !offline.isEmpty {
                    songs = offline
                    usedOfflineDataset = true
                }
            }
        }
    }
    
    private func playSong(_ song: Song) {
        // Find the index of the selected song in the playlist
        if let index = songs.firstIndex(where: { $0.id == song.id }) {
            // Play the entire playlist starting from the selected song
            audioPlayer.playQueue(songs: songs, startAt: index, playlist: playlist)
        } else {
            // Fallback if song not found in playlist
            audioPlayer.play(song: song)
        }
        showingPlayer = true
    }
    
    private func playAll() {
        if !songs.isEmpty {
            audioPlayer.playQueue(songs: songs, playlist: playlist)
            showingPlayer = true
        }
    }
    
    private func toggleOfflineDownload() {
        if isOfflineDownloaded {
            offlineManager.removePlaylist(playlist)
            songs = connectivity.isOffline ? offlineManager.songs(forPlaylist: playlist.id) : songs
        } else {
            guard !songs.isEmpty else { return }
            offlineManager.downloadPlaylist(playlist: playlist, songs: songs, apiService: apiService)
        }
    }
    
    private func saveDetails() {
        let trimmedName = playlistTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = playlistDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            editStatus = "Playlist name cannot be empty."
            return
        }
        apiService.updatePlaylist(playlistId: playlist.id, name: trimmedName, description: trimmedDescription.isEmpty ? nil : trimmedDescription) { result in
            switch result {
            case .success:
                playlistTitle = trimmedName
                playlistDescription = trimmedDescription
                editStatus = "Playlist updated."
                showingEditDetails = false
                let updatedPlaylist = Playlist(id: playlist.id, name: trimmedName, description: trimmedDescription.isEmpty ? nil : trimmedDescription, coverURL: playlist.coverURL, trackCount: playlist.trackCount, createdAt: playlist.createdAt, userId: playlist.userId)
                offlineManager.updatePlaylistMetadata(updatedPlaylist)
                NotificationCenter.default.post(name: .playlistsDidChange, object: nil)
            case .failure(let error):
                editStatus = error.localizedDescription
            }
        }
    }
    
    private func deletePlaylist() {
        guard !isDeleting else { return }
        isDeleting = true
        showingDeleteConfirmation = false
        apiService.deletePlaylist(playlistId: playlist.id) { result in
            switch result {
            case .success:
                offlineManager.removePlaylist(playlist)
                songs.removeAll()
                NotificationCenter.default.post(name: .playlistsDidChange, object: nil)
                editStatus = "Playlist deleted."
                isDeleting = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    dismiss()
                }
            case .failure(let error):
                editStatus = error.localizedDescription
                isDeleting = false
            }
        }
    }

    private func handleSongRemoval(_ removedSong: Song) {
        withAnimation {
            songs.removeAll { $0.id == removedSong.id }
        }
        tempSongs.removeAll { $0.id == removedSong.id }
        editStatus = "Song removed from playlist."
    }

    private func saveReorder() {
        let orders = tempSongs.enumerated().map { index, song in
            PlaylistReorderItem(musicId: song.id, position: index)
        }
        apiService.reorderPlaylist(playlistId: playlist.id, orders: orders) { result in
            switch result {
            case .success:
                songs = tempSongs
                editStatus = "Playlist order updated."
                showingReorder = false
            case .failure(let error):
                editStatus = error.localizedDescription
            }
        }
    }
}
