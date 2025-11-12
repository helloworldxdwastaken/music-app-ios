//
//  Song.swift
//  Music Stream
//

import Foundation

struct Song: Identifiable, Codable {
    let id: Int
    let title: String
    let artist: String
    let album: String?
    let duration: Int?
    let filePath: String?
    private let albumCoverPath: String?
    let source: String?
    let trackId: String?
    let addedAt: String?
    let isLocal: Bool?
    var playlistTrackId: Int?
    
    var durationString: String {
        guard let duration = duration else { return "0:00" }
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // Make id String-compatible for Identifiable
    var stringId: String { String(id) }
    
    // Convert relative artwork paths to absolute URLs
    var albumArtURL: String? {
        guard let path = albumCoverPath, !path.isEmpty else { return nil }
        
        // If already absolute URL, return as-is
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return path
        }
        
        // Convert relative path to absolute URL
        let baseURL = UserDefaults.standard.string(forKey: "serverURL") ?? "https://stream.noxamusic.com"
        
        // Remove leading slash if present to avoid double slashes
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return "\(baseURL)/\(cleanPath)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artist
        case album
        case duration
        case filePath = "file_path"
        case albumCoverPath = "album_cover"
        case source
        case trackId = "track_id"
        case addedAt = "added_at"
        case isLocal
        case playlistTrackId = "playlist_track_id"
    }
}
