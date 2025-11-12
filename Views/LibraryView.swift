//
//  LibraryView.swift
//  Music Stream
//

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var offlineManager: OfflineManager
    @EnvironmentObject var connectivity: ConnectivityService
    @State private var playlists: [Playlist] = []
    @State private var isLoading = false
    @State private var layoutMode: LibraryLayoutMode = .list
    @State private var librarySongs: [Song] = []
    @State private var isLoadingSongs = false
    @State private var section: LibrarySection = .playlists
    
    private var usingOfflineData: Bool { connectivity.isOffline }
    private var displayedPlaylists: [Playlist] {
        usingOfflineData ? offlineManager.downloadedPlaylists.map { $0.displayPlaylist } : playlists
    }
    private var displayedSongs: [Song] {
        usingOfflineData ? offlineManager.allDownloadedSongs : librarySongs
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if !apiService.isAuthenticated {
                    PlaceholderView(
                        symbol: "lock.shield.fill",
                        title: "Sign in to view your library",
                        message: "Access your playlists, downloads, and favorites across devices.",
                        buttonTitle: "Go to Sign In",
                        action: apiService.logout
                    )
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            sectionFilterBar
                            libraryContent
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                        .padding(.top, section == .playlists ? 32 : 64)
                        .padding(.bottom, 80)
                    }
                    
                    if (section == .playlists && isLoading) || (section != .playlists && isLoadingSongs) {
                        ProgressView()
                            .scaleEffect(1.2)
                    }
                }
            }
            .navigationTitle("Library")
            .applyDarkNavBar()
            .onReceive(NotificationCenter.default.publisher(for: .playlistsDidChange)) { _ in
                if connectivity.isOffline {
                    syncOfflineLibrary()
                } else {
                    loadPlaylists()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .libraryDidChange)) { _ in
                if connectivity.isOffline {
                    syncOfflineLibrary()
                } else if apiService.isAuthenticated {
                    loadSongs()
                }
            }
            .onChange(of: connectivity.isOffline) { isOffline in
                if isOffline {
                    syncOfflineLibrary()
                } else if apiService.isAuthenticated {
                    loadPlaylists()
                    loadSongs()
                }
            }
            .onAppear {
                if connectivity.isOffline {
                    syncOfflineLibrary()
                } else {
                    if playlists.isEmpty && apiService.isAuthenticated {
                        loadPlaylists()
                    }
                    if librarySongs.isEmpty && apiService.isAuthenticated {
                        loadSongs()
                    }
                }
            }
        }
    }
    
    private func loadPlaylists() {
        guard apiService.isAuthenticated else {
            playlists = []
            return
        }
        isLoading = true
        apiService.fetchPlaylists { result in
            isLoading = false
            switch result {
            case .success(let fetchedPlaylists):
                playlists = fetchedPlaylists
            case .failure(let error):
                print("Error loading playlists: \(error.localizedDescription)")
                if let apiError = error as? APIError, apiError == .unauthorized {
                    apiService.logout()
                }
            }
        }
    }
    
    private func loadSongs() {
        guard apiService.isAuthenticated else {
            librarySongs = []
            return
        }
        isLoadingSongs = true
        apiService.fetchSongs(limit: nil, offset: 0) { result in
            isLoadingSongs = false
            switch result {
            case .success(let songs):
                librarySongs = songs
            case .failure(let error):
                print("Error loading songs: \(error.localizedDescription)")
                if let apiError = error as? APIError, apiError == .unauthorized {
                    apiService.logout()
                }
            }
        }
    }
    
    private func syncOfflineLibrary() {
        playlists = offlineManager.downloadedPlaylists.map { $0.displayPlaylist }
        librarySongs = offlineManager.allDownloadedSongs
    }
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    }
    
    private var layoutSelector: some View {
        Picker("Layout", selection: $layoutMode) {
            ForEach(LibraryLayoutMode.allCases) { mode in
                Label(mode.title, systemImage: mode.systemImage).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var sectionFilterBar: some View {
        HStack(spacing: 16) {
            ForEach(LibrarySection.allCases) { item in
                Button {
                    section = item
                    if item != .playlists && librarySongs.isEmpty {
                        loadSongs()
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: item.icon)
                            .font(.headline)
                        Text(item.title)
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(section == item ? Color.green.opacity(0.8) : Color.white.opacity(0.05))
                    )
                    .foregroundColor(section == item ? Color.black : Color.white)
                }
            }
        }
    }
    
    @ViewBuilder
    private var libraryContent: some View {
        switch section {
        case .playlists:
            playlistsSection
        case .artists:
            artistsSection
        case .albums:
            albumsSection
        }
    }
    
    @ViewBuilder
    private var playlistsSection: some View {
        if displayedPlaylists.isEmpty {
            PlaceholderView(
                symbol: "music.note",
                title: usingOfflineData ? "No offline playlists" : "Your library is empty",
                message: usingOfflineData ? "Download playlists while online to keep them here." : "Import playlists from the server or add songs manually to get started.",
                buttonTitle: usingOfflineData ? "" : "Refresh Library",
                action: loadPlaylists
            )
            .padding(.top, 40)
        } else {
            LazyVStack(spacing: 20) {
                if playlists.count > 1 && !usingOfflineData {
                    layoutSelector
                }
                
                if layoutMode == .list || usingOfflineData {
                    LazyVStack(spacing: 15) {
                        ForEach(usingOfflineData ? displayedPlaylists : playlists) { playlist in
                            NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                                PlaylistRowView(playlist: playlist)
                            }
                        }
                    }
                } else {
                    LazyVGrid(columns: gridColumns, spacing: 18) {
                        ForEach(displayedPlaylists) { playlist in
                            NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                                PlaylistGridTile(playlist: playlist)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var artistsSection: some View {
        if displayedSongs.isEmpty {
            PlaceholderView(
                symbol: "person.2.fill",
                title: usingOfflineData ? "No offline artists" : "No artists yet",
                message: usingOfflineData ? "Download playlists to browse artists offline." : "Start scanning your library or add downloads to populate artists.",
                buttonTitle: usingOfflineData ? "" : "Refresh",
                action: loadSongs
            )
            .padding(.top, 40)
        } else {
            LazyVGrid(columns: gridColumns, spacing: 18) {
                ForEach(artistGroups) { artist in
                    NavigationLink(destination: FilteredSongListView(title: artist.name, songs: artist.songs)) {
                        ArtistCard(artist: artist)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    @ViewBuilder
    private var albumsSection: some View {
        if displayedSongs.isEmpty {
            PlaceholderView(
                symbol: "square.stack.fill",
                title: usingOfflineData ? "No offline albums" : "No albums yet",
                message: usingOfflineData ? "Download playlists to populate albums offline." : "Add music to your library to browse by album.",
                buttonTitle: usingOfflineData ? "" : "Refresh",
                action: loadSongs
            )
            .padding(.top, 40)
        } else {
            LazyVGrid(columns: gridColumns, spacing: 18) {
                ForEach(albumGroups) { album in
                    NavigationLink(destination: FilteredSongListView(title: album.title, songs: album.songs)) {
                        AlbumCard(album: album)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var artistGroups: [LibraryArtist] {
        let grouped = Dictionary(grouping: displayedSongs) { $0.artist.trimmingCharacters(in: .whitespacesAndNewlines) }
        return grouped
            .filter { !$0.key.isEmpty }
            .map { key, songs in
                LibraryArtist(name: key, songs: songs)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    private var albumGroups: [LibraryAlbum] {
        let grouped = Dictionary(grouping: displayedSongs) { ($0.album ?? "Unknown Album").trimmingCharacters(in: .whitespacesAndNewlines) }
        return grouped
            .map { key, songs in
                LibraryAlbum(title: key.isEmpty ? "Unknown Album" : key, songs: songs)
            }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
            .environmentObject(APIService())
            .environmentObject(OfflineManager())
            .environmentObject(ConnectivityService())
    }
}

struct PlaceholderView: View {
    let symbol: String
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: symbol)
                .font(.system(size: 54, weight: .medium))
                .foregroundStyle(LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(24)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.08))
                )
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
            if !buttonTitle.isEmpty {
                Button(action: action) {
                    Text(buttonTitle)
                        .fontWeight(.semibold)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 28)
                        .background(Color.white.opacity(0.18))
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.black.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 20, y: 12)
        )
    }
}

struct PlaylistGridTile: View {
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var offlineManager: OfflineManager
    let playlist: Playlist
    @State private var firstSongArtworkURL: String?
    @State private var isLoadingArtwork = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AsyncImage(url: artworkURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ZStack {
                    LinearGradient(colors: [.blue.opacity(0.5), .purple.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "music.note.list")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            
            Text(playlist.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Text("\(playlist.songCount) songs")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 16, y: 8)
        )
        .onAppear(perform: loadFirstSongArtwork)
    }
    
    private var artworkURL: URL? {
        if let offlineURL = offlineManager.playlistArtworkURL(playlist.id) {
            return offlineURL
        }
        if let firstSongArtworkURL,
           let url = URL(string: firstSongArtworkURL) {
            return url
        }
        guard let coverURL = playlist.coverURL, !coverURL.isEmpty else { return nil }
        if coverURL.hasPrefix("file://") {
            return URL(string: coverURL)
        }
        if coverURL.hasPrefix("http://") || coverURL.hasPrefix("https://") {
            return URL(string: coverURL)
        }
        let baseURL = UserDefaults.standard.string(forKey: "serverURL") ?? "https://stream.noxamusic.com"
        let cleanPath = coverURL.hasPrefix("/") ? String(coverURL.dropFirst()) : coverURL
        return URL(string: "\(baseURL)/\(cleanPath)")
    }
    
    private func loadFirstSongArtwork() {
        guard firstSongArtworkURL == nil,
              playlist.songCount > 0,
              !isLoadingArtwork else { return }
        if offlineManager.isPlaylistDownloaded(playlist.id) { return }
        
        isLoadingArtwork = true
        apiService.fetchPlaylistSongs(playlistId: playlist.id) { result in
            isLoadingArtwork = false
            if case .success(let songs) = result,
               let firstSong = songs.first,
               let artworkURL = firstSong.albumArtURL {
                firstSongArtworkURL = artworkURL
            }
        }
    }
}

enum LibraryLayoutMode: String, CaseIterable, Identifiable {
    case list
    case grid
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .list: return "List"
        case .grid: return "Grid"
        }
    }
    
    var systemImage: String {
        switch self {
        case .list: return "list.bullet"
        case .grid: return "square.grid.2x2"
        }
    }
}

enum LibrarySection: String, CaseIterable, Identifiable {
    case playlists
    case artists
    case albums
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .playlists: return "Playlists"
        case .artists: return "Artists"
        case .albums: return "Albums"
        }
    }
    
    var icon: String {
        switch self {
        case .playlists: return "music.note.list"
        case .artists: return "person.2.fill"
        case .albums: return "square.stack.fill"
        }
    }
}

struct LibraryArtist: Identifiable {
    let name: String
    let songs: [Song]
    var id: String { name }
    
    var artworkURL: URL? {
        if let song = songs.first, let urlString = song.albumArtURL {
            return URL(string: urlString)
        }
        return nil
    }
}

struct LibraryAlbum: Identifiable {
    let title: String
    let songs: [Song]
    var id: String { title }
    
    var artworkURL: URL? {
        if let song = songs.first, let urlString = song.albumArtURL {
            return URL(string: urlString)
        }
        return nil
    }
}

struct ArtistCard: View {
    let artist: LibraryArtist
    @EnvironmentObject var offlineManager: OfflineManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            let artURL = artist.songs.compactMap { offlineManager.artworkURL(for: $0) ?? URL(string: $0.albumArtURL ?? "") }.first
            AsyncImage(url: artURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            
            Text(artist.name)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
            Text("\(artist.songs.count) songs")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

struct AlbumCard: View {
    let album: LibraryAlbum
    @EnvironmentObject var offlineManager: OfflineManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            let artURL = album.songs.compactMap { offlineManager.artworkURL(for: $0) ?? URL(string: $0.albumArtURL ?? "") }.first
            AsyncImage(url: artURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                    Image(systemName: "square.stack.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            
            Text(album.title)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(2)
            Text("\(album.songs.count) songs")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

struct FilteredSongListView: View {
    let title: String
    let songs: [Song]
    @EnvironmentObject private var audioPlayer: AudioPlayerManager
    
    var body: some View {
        List {
            ForEach(songs) { song in
                SongRowView(song: song)
                    .onTapGesture {
                        audioPlayer.play(song: song)
                    }
            }
        }
        .listStyle(.plain)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .applyDarkNavBar()
    }
}
