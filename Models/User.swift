//
//  User.swift
//  Music Stream
//

import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String?
    let isAdmin: Bool?
    let lastLogin: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case isAdmin = "is_admin"
        case lastLogin = "last_login"
    }
    
    init(id: Int, username: String, email: String?, isAdmin: Bool?, lastLogin: String?) {
        self.id = id
        self.username = username
        self.email = email
        self.isAdmin = isAdmin
        self.lastLogin = lastLogin
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        
        if let boolValue = try? container.decode(Bool.self, forKey: .isAdmin) {
            isAdmin = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isAdmin) {
            isAdmin = intValue != 0
        } else {
            isAdmin = nil
        }
        
        lastLogin = try container.decodeIfPresent(String.self, forKey: .lastLogin)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encodeIfPresent(email, forKey: .email)
        if let isAdmin = isAdmin {
            try container.encode(isAdmin, forKey: .isAdmin)
        }
        try container.encodeIfPresent(lastLogin, forKey: .lastLogin)
    }
}

struct AuthResponse: Codable {
    let success: Bool?
    let user: User
    let token: String
}
