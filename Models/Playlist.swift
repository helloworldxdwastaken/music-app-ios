//
//  Playlist.swift
//  Music Stream
//

import Foundation

struct Playlist: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String?
    let coverURL: String?
    let trackCount: Int
    let createdAt: String?
    let userId: Int?
    
    var songCount: Int { trackCount }
    
    // Make id String-compatible for Identifiable
    var stringId: String { String(id) }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case coverURL = "cover_url"
        case trackCount = "track_count"
        case createdAt = "created_at"
        case userId = "user_id"
    }
}

struct PlaylistsResponse: Codable {
    let success: Bool
    let playlists: [Playlist]
}

struct PlaylistTracksResponse: Codable {
    let success: Bool
    let tracks: [PlaylistTrackItem]
}

struct PlaylistTrackItem: Codable {
    let playlistTrackId: Int?
    let position: Int?
    let song: Song
    
    enum CodingKeys: String, CodingKey {
        case playlistTrackId = "playlist_track_id"
        case position
        case song
        case track
    }
    
    init(from decoder: Decoder) throws {
        if let directSong = try? Song(from: decoder) {
            self.song = directSong
            self.playlistTrackId = directSong.playlistTrackId
            self.position = nil
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.playlistTrackId = try container.decodeIfPresent(Int.self, forKey: .playlistTrackId)
        self.position = try container.decodeIfPresent(Int.self, forKey: .position)
        if let nestedSong = try container.decodeIfPresent(Song.self, forKey: .song) {
            self.song = nestedSong
        } else if let nestedTrack = try container.decodeIfPresent(Song.self, forKey: .track) {
            self.song = nestedTrack
        } else {
            self.song = try Song(from: decoder)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(playlistTrackId, forKey: .playlistTrackId)
        try container.encodeIfPresent(position, forKey: .position)
        try container.encode(song, forKey: .song)
    }
}
