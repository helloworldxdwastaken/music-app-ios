//
//  AdminModels.swift
//  Music Stream
//

import Foundation

struct AdminCredentials: Codable, Equatable {
    let username: String
    let password: String
}

struct AdminStats: Codable {
    let totalSongs: Int?
    let totalPlays: Int?
    let avgPlays: Double?
    let uniqueArtists: Int?
    let uniqueAlbums: Int?
    let totalSizeBytes: Int?
    
    enum CodingKeys: String, CodingKey {
        case totalSongs = "total_songs"
        case totalPlays = "total_plays"
        case avgPlays = "avg_plays"
        case uniqueArtists = "unique_artists"
        case uniqueAlbums = "unique_albums"
        case totalSizeBytes = "total_size_bytes"
    }
}

struct AdminVersionInfo: Codable {
    let versions: [String: String]
}

struct AdminUserStatusResponse: Codable {
    let users: [AdminUser]
    let summary: AdminUserSummary
}

struct AdminUserSummary: Codable {
    let totalUsers: Int
    let activeToday: Int
    let onlineNow: Int
    
    enum CodingKeys: String, CodingKey {
        case totalUsers = "total_users"
        case activeToday = "active_today"
        case onlineNow = "online_now"
    }
}

struct AdminUser: Identifiable, Codable {
    let id: Int
    let username: String
    let email: String?
    let createdAt: String?
    let lastLogin: String?
    let isActive: Int?
    let lastActivity: String?
    let wasActiveToday: Bool?
    let isOnline: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case createdAt = "created_at"
        case lastLogin = "last_login"
        case isActive = "is_active"
        case lastActivity = "last_activity"
        case wasActiveToday = "was_active_today"
        case isOnline = "is_online"
    }
}
