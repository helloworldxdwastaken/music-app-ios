//
//  SearchView.swift
//  Music Stream
//

import SwiftUI
import AVFoundation

struct SearchView: View {
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var audioPlayer: AudioPlayerManager
    @EnvironmentObject var offlineManager: OfflineManager
    @State private var searchText = ""
    @State private var searchResults: [Song] = []
    @State private var rawSearchResults: [Song] = []
    @State private var isSearching = false
    @State private var showingPlayer = false
    @State private var selectedScope: SearchScope = .all
    @State private var searchMode: SearchMode = .offline
    @State private var onlineResults: [RemoteTrack] = []
    @StateObject private var previewPlayer = PreviewPlayer.shared
    @State private var selectedRemoteTrack: RemoteTrack?
    @State private var showingRemoteOptions = false
    @State private var showingPlaylistSheet = false
    @State private var availablePlaylists: [Playlist] = []
    @State private var isLoadingPlaylists = false
    @State private var downloadStatus: String?
    @State private var showingDownloadAlert = false
    @State private var isProcessingDownload = false
    @FocusState private var isSearchFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        modePicker
                        searchBar
                        if searchMode == .offline {
                            scopeSelector
                        }
                        resultsSection
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Search")
            .applyDarkNavBar()
            .sheet(isPresented: $showingPlayer) {
                NowPlayingView()
            }
            .confirmationDialog("Actions", isPresented: $showingRemoteOptions, titleVisibility: .visible) {
                Button("Download to Library") {
                    downloadSelectedTrack()
                }
                Button("Download & Add to Playlist") {
                    preparePlaylistSelection()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showingPlaylistSheet) {
                playlistPickerSheet
            }
            .alert("Download", isPresented: $showingDownloadAlert) {
                Button("OK") { downloadStatus = nil }
            } message: {
                Text(downloadStatus ?? "Done")
            }
        }
    }
    
    private func playSong(_ song: Song) {
        previewPlayer.stop()
        audioPlayer.play(song: song)
        showingPlayer = true
    }
    
    @ViewBuilder
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.7))
            
            TextField("Search songs, artists, albums...", text: $searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFieldFocused)
                .onChange(of: searchText) { newValue in
                    performSearch(query: newValue)
                }
                .submitLabel(.search)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    searchResults = []
                    rawSearchResults = []
                    onlineResults = []
                    isSearchFieldFocused = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .transition(.scale)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 20, y: 10)
        )
    }
    
    @ViewBuilder
    private var scopeSelector: some View {
        Picker("Filter", selection: $selectedScope) {
            ForEach(SearchScope.allCases) { scope in
                Text(scope.title).tag(scope)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedScope) { _ in
            if !searchResults.isEmpty {
                searchResults = applyScopeFilter(to: rawSearchResults)
            }
        }
    }
    
    @ViewBuilder
    private var modePicker: some View {
        HStack(spacing: 16) {
            modeButton(icon: "folder", title: "Offline", selected: searchMode == .offline) {
                searchMode = .offline
            }
            modeButton(icon: "globe", title: "Online", selected: searchMode == .online) {
                searchMode = .online
            }
        }
        .onChange(of: searchMode) { _ in
            searchResults = []
            rawSearchResults = []
            onlineResults = []
            performSearch(query: searchText)
        }
    }
    
    @ViewBuilder
    private var onlineTypeSelector: some View {
        EmptyView()
    }
    
    @ViewBuilder
    private var resultsSection: some View {
        let hasResults = searchMode == .offline ? !searchResults.isEmpty : !onlineResults.isEmpty
        if isSearching {
            SearchPlaceholderView(
                icon: "waveform.path.ecg",
                title: "Searching Library",
                subtitle: "Hang tight while we look for matches."
            )
        } else if searchMode == .offline && !apiService.isAuthenticated {
            SearchPlaceholderView(
                icon: "lock.shield.fill",
                title: "Sign in to search",
                subtitle: "Connect your account to browse the full catalog."
            )
        } else if !hasResults && !searchText.isEmpty {
            SearchPlaceholderView(
                icon: "questionmark.circle",
                title: "No results found",
                subtitle: searchMode == .offline ? "Try a different keyword or check your spelling." : "Try different keywords or switch result type."
            )
        } else if !hasResults {
            SearchPlaceholderView(
                icon: "music.note.list",
                title: "Search your music",
                subtitle: searchMode == .offline ? "Look up songs, artists, or albums from your connected server." : "Search online sources for more music."
            )
        } else {
            if searchMode == .offline {
                LazyVStack(spacing: 12) {
                    ForEach(searchResults) { song in
                        SongRowView(song: song)
                            .onTapGesture {
                                playSong(song)
                            }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.black.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(onlineResults) { track in
                        let isPreviewing = previewPlayer.currentTrackID == track.id && previewPlayer.isPlaying
                        RemoteTrackRow(
                            track: track,
                            isPreviewing: isPreviewing,
                            onPlayPreview: {
                                audioPlayer.pause()
                                previewPlayer.playPreview(urlString: track.preview, trackID: track.id)
                            },
                            onOptions: {
                                selectedRemoteTrack = track
                                showingRemoteOptions = true
                            }
                        )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.black.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            rawSearchResults = []
            onlineResults = []
            return
        }

        isSearching = true
        
        switch searchMode {
        case .offline:
            guard apiService.isAuthenticated else {
                searchResults = []
                rawSearchResults = []
                isSearching = false
                return
            }
            apiService.searchSongs(query: query) { result in
                isSearching = false
                switch result {
                case .success(let songs):
                    rawSearchResults = songs
                    searchResults = applyScopeFilter(to: songs)
                case .failure(let error):
                    print("Search error: \(error.localizedDescription)")
                    searchResults = []
                    rawSearchResults = []
                    if let apiError = error as? APIError, apiError == .unauthorized {
                        apiService.logout()
                    }
                }
            }
        case .online:
            apiService.searchOnlineTracks(query: query) { result in
                isSearching = false
                switch result {
                case .success(let tracks):
                    onlineResults = tracks
                case .failure(let error):
                    print("Online search error: \(error.localizedDescription)")
                    onlineResults = []
                }
            }
        }
    }
    
    private func applyScopeFilter(to songs: [Song]) -> [Song] {
        switch selectedScope {
        case .all, .songs:
            return songs
        case .artists:
            return songs.filter { $0.artist.localizedCaseInsensitiveContains(searchText) }
        case .albums:
            return songs.filter { ($0.album ?? "").localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private func preparePlaylistSelection() {
        showingRemoteOptions = false
        guard apiService.isAuthenticated else {
            downloadStatus = "Sign in to add downloads."
            showingDownloadAlert = true
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
                    downloadStatus = "Failed to load playlists: \(error.localizedDescription)"
                    showingDownloadAlert = true
                    showingPlaylistSheet = false
                }
            }
        }
    }
    
    private func downloadSelectedTrack(playlist: Playlist? = nil) {
        guard let track = selectedRemoteTrack else { return }
        guard apiService.isAuthenticated else {
            downloadStatus = "Sign in to download music."
            showingDownloadAlert = true
            return
        }
        if searchMode == .online {
            showingRemoteOptions = false
        }
        let finalArtist: String
        if !track.artistName.isEmpty {
            finalArtist = track.artistName
        } else if let album = track.albumTitle, !album.isEmpty {
            finalArtist = album
        } else {
            finalArtist = "Unknown Artist"
        }
        isProcessingDownload = true
        apiService.addDownload(title: track.displayTitle, artist: finalArtist, album: track.albumTitle, playlistId: playlist?.id) { result in
            isProcessingDownload = false
            switch result {
            case .success:
                downloadStatus = "Download started. Check Downloads tab for progress."
            case .failure(let error):
                downloadStatus = error.localizedDescription
            }
            showingDownloadAlert = true
        }
    }
    
    private var playlistPickerSheet: some View {
        NavigationView {
            List {
                if isLoadingPlaylists {
                    ProgressView("Loading playlists…")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if availablePlaylists.isEmpty {
                    Text("No playlists available.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(availablePlaylists) { playlist in
                        Button {
                            showingPlaylistSheet = false
                            downloadSelectedTrack(playlist: playlist)
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
                }
            }
            .navigationTitle("Select Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showingPlaylistSheet = false }
                }
            }
        }
        .presentationCompat()
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
            .environmentObject(APIService())
            .environmentObject(AudioPlayerManager())
            .environmentObject(OfflineManager())
    }
}

enum SearchScope: String, CaseIterable, Identifiable {
    case all
    case songs
    case artists
    case albums
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .all: return "All"
        case .songs: return "Songs"
        case .artists: return "Artists"
        case .albums: return "Albums"
        }
    }
}

struct SearchPlaceholderView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(18)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.05))
                )
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

enum SearchMode: String, CaseIterable, Identifiable {
    case offline
    case online
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .offline: return "Offline"
        case .online: return "Online"
        }
    }
}

extension SearchView {
    private func modeButton(icon: String, title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.headline)
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selected ? Color.green.opacity(0.8) : Color.white.opacity(0.05))
            )
            .foregroundColor(selected ? .black : .white)
        }
        .buttonStyle(.plain)
    }
}

struct RemoteTrackRow: View {
    let track: RemoteTrack
    var isPreviewing: Bool = false
    var onPlayPreview: (() -> Void)? = nil
    var onOptions: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 14) {
            AsyncImage(url: track.artworkURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                    Image(systemName: "music.note")
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                if !track.artistName.isEmpty {
                    Text(track.artistName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                } else if let album = track.albumTitle, !album.isEmpty {
                    Text(album)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                } else if !track.subtitle.isEmpty {
                    Text(track.subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
            Spacer()
            if !track.durationString.isEmpty {
                Text(track.durationString)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            if let onPlayPreview = onPlayPreview, track.preview != nil {
                Button(action: onPlayPreview) {
                    Image(systemName: isPreviewing ? "pause.circle.fill" : "play.circle")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                }
            }
            if let onOptions = onOptions {
                Button(action: onOptions) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 6)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

private struct PresentationCompat: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.presentationDetents([.medium, .large])
        } else {
            content
        }
    }
}

extension View {
    func presentationCompat() -> some View {
        modifier(PresentationCompat())
    }
}

final class PreviewPlayer: ObservableObject {
    static let shared = PreviewPlayer()
    private var player: AVPlayer?
    @Published var currentTrackID: String?
    @Published var isPlaying = false

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioPlaybackStart), name: .audioPlaybackDidStart, object: nil)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func playPreview(urlString: String?, trackID: String) {
        guard let urlString, let url = URL(string: urlString) else { return }
        if currentTrackID == trackID, isPlaying {
            pause()
            return
        }
        currentTrackID = trackID
        let item = AVPlayerItem(url: url)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinish), name: .AVPlayerItemDidPlayToEndTime, object: item)
        player = AVPlayer(playerItem: item)
        NotificationCenter.default.post(name: .previewPlaybackDidStart, object: nil)
        player?.play()
        isPlaying = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func stop() {
        player?.pause()
        player = nil
        currentTrackID = nil
        isPlaying = false
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    @objc private func playerDidFinish() {
        stop()
    }
    @objc private func handleAudioPlaybackStart() {
        stop()
    }
}
