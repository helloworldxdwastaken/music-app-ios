import Foundation

final class OfflineManager: ObservableObject, @unchecked Sendable {
    struct OfflinePlaylist: Identifiable, Codable {
        let playlist: Playlist
        var songIds: [Int]
        let downloadedAt: Date
        var artworkURL: String?
        
        var id: Int { playlist.id }
        
        var displayPlaylist: Playlist {
            Playlist(id: playlist.id,
                     name: playlist.name,
                     description: playlist.description,
                     coverURL: artworkURL ?? playlist.coverURL,
                     trackCount: songIds.count,
                     createdAt: playlist.createdAt,
                     userId: playlist.userId)
        }
    }
    
    struct OfflineTrack: Identifiable, Codable {
        var song: Song
        var localFileName: String
        var playlistIds: Set<Int>
        var artworkURL: String?
        let downloadedAt: Date
        
        var id: Int { song.id }
    }
    
    private struct OfflineCache: Codable {
        var playlists: [OfflinePlaylist]
        var tracks: [OfflineTrack]
    }
    
    @Published private(set) var playlists: [Int: OfflinePlaylist] = [:]
    @Published private(set) var tracks: [Int: OfflineTrack] = [:]
    @Published private(set) var downloadProgress: [Int: Double] = [:]
    @Published private(set) var activeDownloads: Set<Int> = []
    @Published private(set) var songDownloads: Set<Int> = []
    @Published var statusMessage: String?
    
    private let fileManager = FileManager.default
    private let downloadsDirectory: URL
    private let artworkDirectory: URL
    private let metadataURL: URL
    private var pendingArtworkFetches: Set<Int> = []
    
    init() {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        downloadsDirectory = docs.appendingPathComponent("OfflineCache", isDirectory: true)
        artworkDirectory = downloadsDirectory.appendingPathComponent("Artwork", isDirectory: true)
        metadataURL = downloadsDirectory.appendingPathComponent("offline-metadata.json")
        try? fileManager.createDirectory(at: downloadsDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: artworkDirectory, withIntermediateDirectories: true)
        loadCache()
    }
    
    // MARK: - Public Accessors
    func localURL(for song: Song) -> URL? {
        let filename: String?
        if Thread.isMainThread {
            filename = tracks[song.id]?.localFileName
        } else {
            var temp: String?
            DispatchQueue.main.sync {
                temp = tracks[song.id]?.localFileName
            }
            filename = temp
        }
        guard let name = filename else { return nil }
        return downloadsDirectory.appendingPathComponent(name)
    }
    
    func isPlaylistDownloaded(_ playlistId: Int) -> Bool {
        if Thread.isMainThread {
            return playlists[playlistId] != nil
        }
        var result = false
        DispatchQueue.main.sync {
            result = playlists[playlistId] != nil
        }
        return result
    }
    
    func isPlaylistDownloading(_ playlistId: Int) -> Bool {
        if Thread.isMainThread {
            return activeDownloads.contains(playlistId)
        }
        var result = false
        DispatchQueue.main.sync {
            result = activeDownloads.contains(playlistId)
        }
        return result
    }
    
    func songs(forPlaylist playlistId: Int) -> [Song] {
        var ids: [Int] = []
        if Thread.isMainThread {
            ids = playlists[playlistId]?.songIds ?? []
        } else {
            DispatchQueue.main.sync {
                ids = playlists[playlistId]?.songIds ?? []
            }
        }
        return ids.compactMap { songId in
            var track: OfflineTrack?
            if Thread.isMainThread {
                track = tracks[songId]
            } else {
                DispatchQueue.main.sync {
                    track = tracks[songId]
                }
            }
            return track?.song
        }
    }
    
    func isSongDownloaded(_ song: Song) -> Bool {
        if Thread.isMainThread {
            return tracks[song.id] != nil
        }
        var result = false
        DispatchQueue.main.sync {
            result = tracks[song.id] != nil
        }
        return result
    }
    
    func isSongDownloading(_ song: Song) -> Bool {
        if Thread.isMainThread {
            return songDownloads.contains(song.id)
        }
        var result = false
        DispatchQueue.main.sync {
            result = songDownloads.contains(song.id)
        }
        return result
    }
    
    func artworkURL(for song: Song) -> URL? {
        if Thread.isMainThread {
            let url = tracks[song.id]?.artworkURL.flatMap { URL(string: $0) }
            if url == nil && tracks[song.id] != nil {
                ensureArtwork(for: song)
            }
            return url
        }
        var result: URL?
        DispatchQueue.main.sync {
            result = tracks[song.id]?.artworkURL.flatMap { URL(string: $0) }
            if result == nil && tracks[song.id] != nil {
                ensureArtwork(for: song)
            }
        }
        return result
    }
    
    func playlistArtworkURL(_ playlistId: Int) -> URL? {
        if Thread.isMainThread {
            return playlists[playlistId]?.artworkURL.flatMap { URL(string: $0) }
        }
        var result: URL?
        DispatchQueue.main.sync {
            result = playlists[playlistId]?.artworkURL.flatMap { URL(string: $0) }
        }
        return result
    }
    
    var downloadedPlaylists: [OfflinePlaylist] {
        if Thread.isMainThread {
            return Array(playlists.values)
        }
        var snapshot: [OfflinePlaylist] = []
        DispatchQueue.main.sync {
            snapshot = Array(playlists.values)
        }
        return snapshot
    }
    
    var allDownloadedSongs: [Song] {
        if Thread.isMainThread {
            return tracks.values.map { $0.song }
        }
        var snapshot: [Song] = []
        DispatchQueue.main.sync {
            snapshot = tracks.values.map { $0.song }
        }
        return snapshot
    }
    
    // MARK: - Download Management
    func downloadPlaylist(playlist: Playlist, songs: [Song], apiService: APIService) {
        guard !songs.isEmpty else { return }
        if isPlaylistDownloading(playlist.id) { return }
        DispatchQueue.main.async {
            self.activeDownloads.insert(playlist.id)
            self.downloadProgress[playlist.id] = 0
        }
        Task(priority: .background) { [weak self] in
            guard let self = self else { return }
            await self.performDownload(playlist: playlist, songs: songs, apiService: apiService)
        }
    }
    
    func removePlaylist(_ playlist: Playlist) {
        DispatchQueue.main.async {
            guard let entry = self.playlists[playlist.id] else { return }
            self.playlists[playlist.id] = nil
            for songId in entry.songIds {
                if var track = self.tracks[songId] {
                    track.playlistIds.remove(playlist.id)
                    if track.playlistIds.isEmpty {
                        self.tracks[songId] = nil
                        self.deleteFile(named: track.localFileName)
                        self.deleteArtwork(from: track.artworkURL)
                    } else {
                        self.tracks[songId] = track
                    }
                }
            }
            self.downloadProgress[playlist.id] = nil
            self.activeDownloads.remove(playlist.id)
            self.persistCache()
        }
    }
    
    func removeSong(_ song: Song) {
        DispatchQueue.main.async {
            guard let track = self.tracks[song.id] else { return }
            for playlistId in track.playlistIds {
                if var playlist = self.playlists[playlistId] {
                    playlist.songIds.removeAll { $0 == song.id }
                    if playlist.songIds.isEmpty {
                        self.playlists[playlistId] = nil
                    } else {
                        self.playlists[playlistId] = playlist
                    }
                }
            }
            self.tracks[song.id] = nil
            self.deleteFile(named: track.localFileName)
            self.deleteArtwork(from: track.artworkURL)
            self.persistCache()
        }
    }
    
    func downloadSong(_ song: Song, playlist: Playlist? = nil, apiService: APIService) {
        if isSongDownloading(song) { return }
        if isSongDownloaded(song) {
            attach(song: song, to: playlist)
            return
        }
        DispatchQueue.main.async {
            self.songDownloads.insert(song.id)
        }
        Task(priority: .background) { [weak self] in
            guard let self = self else { return }
            guard let fileURL = await self.downloadFile(for: song, apiService: apiService) else {
                DispatchQueue.main.async { self.songDownloads.remove(song.id) }
                return
            }
            let artworkPath = await self.fetchArtwork(for: song)
            self.store(song: song, playlist: playlist, fileURL: fileURL, artworkURL: artworkPath)
            DispatchQueue.main.async {
                self.songDownloads.remove(song.id)
            }
        }
    }
    
    // MARK: - Internal flow
    private func performDownload(playlist: Playlist, songs: [Song], apiService: APIService) async {
        let total = songs.count
        var completed = 0
        for song in songs {
            if self.localURL(for: song) != nil {
                attach(song: song, to: playlist)
                completed += 1
                updateProgress(Double(completed) / Double(total), for: playlist.id)
                continue
            }
            guard let fileURL = await downloadFile(for: song, apiService: apiService) else {
                continue
            }
            let artworkPath = await fetchArtwork(for: song)
            store(song: song, playlist: playlist, fileURL: fileURL, artworkURL: artworkPath)
            completed += 1
            updateProgress(Double(completed) / Double(total), for: playlist.id)
        }
        finalizeDownload(for: playlist.id)
    }
    
    private func downloadFile(for song: Song, apiService: APIService) async -> URL? {
        guard let streamURL = apiService.getStreamURL(for: song) else { return nil }
        var request = URLRequest(url: streamURL)
        if let token = apiService.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        do {
            let (tempURL, response) = try await URLSession.shared.download(for: request)
            let ext = response.suggestedFilename.flatMap { URL(fileURLWithPath: $0).pathExtension }
            let safeExt = ext?.isEmpty == false ? ext! : "mp3"
            let filename = "song_\(song.id)_\(UUID().uuidString).\(safeExt)"
            let destination = downloadsDirectory.appendingPathComponent(filename)
            try? fileManager.removeItem(at: destination)
            try fileManager.createDirectory(at: downloadsDirectory, withIntermediateDirectories: true)
            try fileManager.moveItem(at: tempURL, to: destination)
            return destination
        } catch {
            print("Offline download failed for \(song.title): \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.statusMessage = "Failed to download \(song.title)"
            }
            return nil
        }
    }
    
    private func attach(song: Song, to playlist: Playlist?) {
        DispatchQueue.main.async {
            if let playlist = playlist {
                var entry = self.playlists[playlist.id] ?? OfflinePlaylist(playlist: playlist, songIds: [], downloadedAt: Date(), artworkURL: nil)
                if entry.artworkURL == nil {
                    entry.artworkURL = self.artworkURL(for: song)?.absoluteString ?? playlist.coverURL ?? song.albumArtURL
                }
                if !entry.songIds.contains(song.id) {
                    entry.songIds.append(song.id)
                }
                self.playlists[playlist.id] = entry
            }
            if var track = self.tracks[song.id] {
                if let playlist = playlist {
                    track.playlistIds.insert(playlist.id)
                }
                self.tracks[song.id] = track
            }
            self.persistCache()
        }
    }
    
    private func store(song: Song, playlist: Playlist?, fileURL: URL, artworkURL: String?) {
        DispatchQueue.main.async {
            var track = self.tracks[song.id] ?? OfflineTrack(song: song, localFileName: fileURL.lastPathComponent, playlistIds: [], artworkURL: nil, downloadedAt: Date())
            track.song = song
            track.localFileName = fileURL.lastPathComponent
            if let playlist = playlist {
                track.playlistIds.insert(playlist.id)
            }
            if let artworkURL = artworkURL {
                track.artworkURL = artworkURL
            } else if track.artworkURL == nil {
                track.artworkURL = song.albumArtURL
            }
            self.tracks[song.id] = track
            if let playlist = playlist {
                var entry = self.playlists[playlist.id] ?? OfflinePlaylist(playlist: playlist, songIds: [], downloadedAt: Date(), artworkURL: nil)
                if entry.artworkURL == nil {
                    entry.artworkURL = track.artworkURL ?? playlist.coverURL ?? song.albumArtURL
                }
                if !entry.songIds.contains(song.id) {
                    entry.songIds.append(song.id)
                }
                self.playlists[playlist.id] = entry
            }
            self.persistCache()
        }
    }

    private func fetchArtwork(for song: Song) async -> String? {
        guard let urlString = song.albumArtURL, let url = URL(string: urlString), !urlString.isEmpty else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let ext = URL(fileURLWithPath: url.lastPathComponent).pathExtension
            let safeExt = ext.isEmpty ? "jpg" : ext
            let filename = "art_\(song.id)_\(UUID().uuidString).\(safeExt)"
            let destination = artworkDirectory.appendingPathComponent(filename)
            try data.write(to: destination)
            return destination.absoluteString
        } catch {
            return nil
        }
    }
    
    private func ensureArtwork(for song: Song) {
        precondition(Thread.isMainThread)
        guard pendingArtworkFetches.contains(song.id) == false,
              let _ = song.albumArtURL, !(song.albumArtURL ?? "").isEmpty else { return }
        pendingArtworkFetches.insert(song.id)
        Task(priority: .background) { [weak self] in
            guard let self else { return }
            let path = await self.fetchArtwork(for: song)
            await MainActor.run {
                self.pendingArtworkFetches.remove(song.id)
                guard let path, var track = self.tracks[song.id] else { return }
                track.artworkURL = path
                self.tracks[song.id] = track
                self.persistCache()
            }
        }
    }
    
    private func updateProgress(_ value: Double, for playlistId: Int) {
        DispatchQueue.main.async {
            self.downloadProgress[playlistId] = min(1.0, value)
        }
    }
    
    private func finalizeDownload(for playlistId: Int) {
        DispatchQueue.main.async {
            self.activeDownloads.remove(playlistId)
            self.downloadProgress[playlistId] = nil
            self.statusMessage = "Offline download ready"
        }
    }
    
    private func deleteFile(named fileName: String) {
        let url = downloadsDirectory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: url)
    }
    
    private func deleteArtwork(from urlString: String?) {
        guard let urlString, let url = URL(string: urlString), url.isFileURL else { return }
        try? fileManager.removeItem(at: url)
    }
    
    // MARK: - Persistence
    private func loadCache() {
        guard let data = try? Data(contentsOf: metadataURL) else { return }
        do {
            let cache = try JSONDecoder().decode(OfflineCache.self, from: data)
            playlists = Dictionary(uniqueKeysWithValues: cache.playlists.map { ($0.id, $0) })
            tracks = Dictionary(uniqueKeysWithValues: cache.tracks.map { ($0.id, $0) })
        } catch {
            print("Failed to load offline cache: \(error)")
        }
    }
    
    private func persistCache() {
        assert(Thread.isMainThread)
        let cache = OfflineCache(playlists: Array(self.playlists.values), tracks: Array(self.tracks.values))
        do {
            let data = try JSONEncoder().encode(cache)
            try data.write(to: metadataURL, options: .atomic)
        } catch {
            print("Failed to save offline cache: \(error)")
        }
    }
}
