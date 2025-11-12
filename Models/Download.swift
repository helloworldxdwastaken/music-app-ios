//
//  Download.swift
//  Music Stream
//

import Foundation

enum DownloadStatus: String, Codable {
    case searching
    case downloading
    case completed
    case failed
    case cancelled
    case unknown
    
    init(rawValue: String) {
        switch rawValue.lowercased() {
        case "searching": self = .searching
        case "downloading": self = .downloading
        case "completed": self = .completed
        case "failed": self = .failed
        case "cancelled", "canceled": self = .cancelled
        default: self = .unknown
        }
    }
    
    var displayName: String {
        switch self {
        case .searching: return "Searching"
        case .downloading: return "Downloading"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        case .unknown: return "Unknown"
        }
    }
    
    var tint: String {
        switch self {
        case .completed: return "success"
        case .failed: return "destructive"
        case .cancelled: return "secondary"
        case .searching, .downloading: return "accent"
        case .unknown: return "secondary"
        }
    }
}

struct DownloadItem: Identifiable, Codable {
    let id: String
    let title: String
    let artist: String
    let album: String?
    let statusRaw: String
    let progress: Int?
    let createdAt: String?
    let completedAt: String?
    let playlistId: Int?
    let userId: Int?
    let filePath: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artist
        case album
        case statusRaw = "status"
        case progress
        case createdAt = "created_at"
        case completedAt = "completed_at"
        case playlistId = "playlist_id"
        case userId = "user_id"
        case filePath = "file_path"
    }
    
    var status: DownloadStatus {
        DownloadStatus(rawValue: statusRaw)
    }
}

struct DownloadListResponse: Codable {
    let success: Bool
    let downloads: [DownloadItem]
}

struct BasicResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}

