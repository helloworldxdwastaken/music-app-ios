//
//  APIService.swift
//  Music Stream
//

import Foundation
enum APIError: Error, LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case noData
    case unauthorized
    case decodingFailed
    case invalidRequest
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .noData: return "No data received from server"
        case .unauthorized: return "Session expired. Please sign in again."
        case .decodingFailed: return "Failed to decode server response"
        case .invalidRequest: return "The provided data is invalid"
        }
    }
}

class APIService: ObservableObject {
    @Published var isConnected = false
    @Published private(set) var authToken: String?
    @Published private(set) var currentUser: User?
    @Published private(set) var adminCredentials: AdminCredentials?
    @Published private(set) var isAuthenticating = false
    @Published private(set) var isAuthenticated = false
    
    private var baseURL: String
    
    private let tokenKey = "authToken"
    private let userKey = "currentUser"
    private let adminKey = "adminCredentials"
    
    init() {
        if let savedURL = UserDefaults.standard.string(forKey: "serverURL") {
            self.baseURL = savedURL
        } else {
            self.baseURL = "https://stream.noxamusic.com"
        }
        
        if let token = UserDefaults.standard.string(forKey: tokenKey) {
            self.authToken = token
        }
        if let userData = UserDefaults.standard.data(forKey: userKey),
           let savedUser = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = savedUser
        }
        if let adminData = UserDefaults.standard.data(forKey: adminKey),
           let creds = try? JSONDecoder().decode(AdminCredentials.self, from: adminData) {
            self.adminCredentials = creds
        }
        updateAuthState(token: authToken, user: currentUser)
    }
    
    func updateBaseURL(_ url: String) {
        self.baseURL = url
        UserDefaults.standard.set(url, forKey: "serverURL")
    }
    
    // MARK: - Session Handling
    private func updateAuthState(token: String?, user: User?) {
        DispatchQueue.main.async {
            self.authToken = token
            self.currentUser = user
            self.isAuthenticated = token != nil && user != nil
        }
    }
    
    private func persistSession(token: String?, user: User?, remember: Bool) {
        if remember, let token = token, let user = user,
           let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(token, forKey: tokenKey)
            UserDefaults.standard.set(userData, forKey: userKey)
        } else {
            UserDefaults.standard.removeObject(forKey: tokenKey)
            UserDefaults.standard.removeObject(forKey: userKey)
        }
    }
    
    private func clearSession() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        updateAuthState(token: nil, user: nil)
    }
    
    func setAdminCredentials(username: String, password: String, remember: Bool) {
        let credentials = AdminCredentials(username: username, password: password)
        adminCredentials = credentials
        if remember, let data = try? JSONEncoder().encode(credentials) {
            UserDefaults.standard.set(data, forKey: adminKey)
        } else {
            UserDefaults.standard.removeObject(forKey: adminKey)
        }
    }
    
    func clearAdminCredentials() {
        adminCredentials = nil
        UserDefaults.standard.removeObject(forKey: adminKey)
    }
    
    private func createRequest(url: URL, method: String = "GET", body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        return request
    }
    
    private func handleUnauthorized() {
        clearSession()
    }
    
    private func adminAuthHeader() -> String? {
        guard let creds = adminCredentials else { return nil }
        let login = "\(creds.username):\(creds.password)"
        guard let data = login.data(using: .utf8) else { return nil }
        return "Basic \(data.base64EncodedString())"
    }
    
    private func createAdminRequest(endpoint: String, method: String = "GET", body: Data? = nil) -> URLRequest? {
        guard let header = adminAuthHeader(),
              let url = URL(string: "\(baseURL)/api/admin\(endpoint)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(header, forHTTPHeaderField: "Authorization")
        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }
    
    private func parseBasicResponse(from data: Data) -> BasicResponse? {
        return try? JSONDecoder().decode(BasicResponse.self, from: data)
    }
    
    // MARK: - Connection Test
    func testConnection(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/library/library?limit=1") else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                let success = error == nil && (response as? HTTPURLResponse)?.statusCode == 200
                self.isConnected = success
                completion(success)
            }
        }.resume()
    }
    
    // MARK: - Songs API
    func fetchSongs(limit: Int? = nil, offset: Int = 0, completion: @escaping (Result<[Song], Error>) -> Void) {
        var urlString = "\(baseURL)/api/library/library?offset=\(offset)"
        if let limit = limit {
            urlString += "&limit=\(limit)"
        }
        
        guard let url = URL(string: urlString) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let request = createRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                    self.handleUnauthorized()
                    completion(.failure(APIError.unauthorized))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                
                do {
                    // Backend returns plain array, not wrapped in object
                    let songs = try JSONDecoder().decode([Song].self, from: data)
                    completion(.success(songs))
                } catch {
                    print("Decoding error: \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Response JSON: \(jsonString)")
                    }
                    completion(.failure(APIError.decodingFailed))
                }
            }
        }.resume()
    }
    
    // MARK: - Search API
    func searchSongs(query: String, completion: @escaping (Result<[Song], Error>) -> Void) {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/api/library/search?q=\(encodedQuery)&limit=50") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let request = createRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                    self.handleUnauthorized()
                    completion(.failure(APIError.unauthorized))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                
                do {
                    // Library search returns plain array
                    let searchResults = try JSONDecoder().decode([Song].self, from: data)
                    completion(.success(searchResults))
                } catch {
                    print("Search decoding error: \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Response JSON: \(jsonString)")
                    }
                    completion(.failure(APIError.decodingFailed))
                }
            }
        }.resume()
    }
    
    func searchOnlineTracks(query: String, type: OnlineSearchType = .tracks, completion: @escaping (Result<[RemoteTrack], Error>) -> Void) {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/api/music/search?q=\(encodedQuery)&type=\(type.rawValue)&limit=30") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let request = createRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                
                let decoder = JSONDecoder()
                if let response = try? decoder.decode(RemoteSearchResponse.self, from: data) {
                    completion(.success(response.resolvedTracks))
                } else if let list = try? decoder.decode([RemoteTrack].self, from: data) {
                    completion(.success(list))
                } else {
                    if let json = String(data: data, encoding: .utf8) {
                        print("Online search decode error: \(json)")
                    }
                    completion(.failure(APIError.decodingFailed))
                }
            }
        }.resume()
    }
    
    // MARK: - Playlists API
    // Note: Playlists require authentication. If not logged in, this will return 401
    func fetchPlaylists(completion: @escaping (Result<[Playlist], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/playlists") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let request = createRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // Check for 401 Unauthorized
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                    self.handleUnauthorized()
                    completion(.failure(APIError.unauthorized))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(PlaylistsResponse.self, from: data)
                    completion(.success(response.playlists))
                } catch {
                    print("Playlist decoding error: \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Response JSON: \(jsonString)")
                    }
                    completion(.failure(APIError.decodingFailed))
                }
            }
        }.resume()
    }
    
    func fetchPlaylistSongs(playlistId: Int, completion: @escaping (Result<[Song], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/playlists/\(playlistId)/tracks") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let request = createRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // Check for 401 Unauthorized
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                    self.handleUnauthorized()
                    completion(.failure(APIError.unauthorized))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(PlaylistTracksResponse.self, from: data)
                    let songs = response.tracks.map { item -> Song in
                        var song = item.song
                        if song.playlistTrackId == nil {
                            song.playlistTrackId = item.playlistTrackId
                        }
                        return song
                    }
                    completion(.success(songs))
                } catch {
                    print("Playlist songs decoding error: \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Response JSON: \(jsonString)")
                    }
                    completion(.failure(APIError.decodingFailed))
                }
            }
        }.resume()
    }
    
    func addSong(_ songId: Int, to playlistId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/playlists/\(playlistId)/tracks") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let payload: [String: Any] = ["musicId": songId]
        let body = try? JSONSerialization.data(withJSONObject: payload)
        let request = createRequest(url: url, method: "POST", body: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(APIError.invalidResponse))
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    self.handleUnauthorized()
                    completion(.failure(APIError.unauthorized))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                
                if let response = self.parseBasicResponse(from: data), response.success {
                    completion(.success(()))
                } else {
                    completion(.failure(APIError.decodingFailed))
                }
            }
        }.resume()
    }
    
    func updatePlaylist(playlistId: Int, name: String, description: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/playlists/\(playlistId)") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        var payload: [String: Any] = ["name": name]
        if let description = description { payload["description"] = description }
        let body = try? JSONSerialization.data(withJSONObject: payload)
        let request = createRequest(url: url, method: "PUT", body: body)
        performBasicOperation(request: request, defaultMessage: "Playlist updated", completion: completion)
    }
    
    func reorderPlaylist(playlistId: Int, orders: [PlaylistReorderItem], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/playlists/\(playlistId)/reorder") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        let payload: [String: Any] = ["trackOrders": orders.map { ["playlist_track_id": $0.playlistTrackId, "position": $0.position] }]
        let body = try? JSONSerialization.data(withJSONObject: payload)
        let request = createRequest(url: url, method: "PUT", body: body)
        performBasicOperation(request: request, defaultMessage: "Playlist reordered", completion: completion)
    }
    
    func fetchLibraryStats(completion: @escaping (Result<LibraryStats, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/library/stats") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let request = createRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                
                do {
                    let stats = try JSONDecoder().decode(LibraryStats.self, from: data)
                    completion(.success(stats))
                } catch {
                    completion(.failure(APIError.decodingFailed))
                }
            }
        }.resume()
    }
    
    // MARK: - Stream URL
    func getStreamURL(for song: Song) -> URL? {
        // All local library songs use /api/library/stream/:id
        return URL(string: "\(baseURL)/api/library/stream/\(song.id)")
    }
    
    // MARK: - Authentication
    func login(username: String, password: String, rememberMe: Bool, completion: @escaping (Result<User, Error>) -> Void) {
        authenticate(endpoint: "/api/auth/login",
                     payload: ["username": username, "password": password],
                     rememberMe: rememberMe,
                     completion: completion)
    }
    
    func signup(username: String, password: String, rememberMe: Bool, completion: @escaping (Result<User, Error>) -> Void) {
        authenticate(endpoint: "/api/auth/signup",
                     payload: ["username": username, "password": password],
                     rememberMe: rememberMe,
                     completion: completion)
    }
    
    private func authenticate(endpoint: String,
                              payload: [String: Any],
                              rememberMe: Bool,
                              completion: @escaping (Result<User, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)\(endpoint)"),
              let body = try? JSONSerialization.data(withJSONObject: payload) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        isAuthenticating = true
        let request = createRequest(url: url, method: "POST", body: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isAuthenticating = false
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(APIError.invalidResponse))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    self.handleUnauthorized()
                    completion(.failure(APIError.unauthorized))
                    return
                }
                
                do {
                    let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                    self.updateAuthState(token: authResponse.token, user: authResponse.user)
                    self.persistSession(token: authResponse.token, user: authResponse.user, remember: rememberMe)
                    completion(.success(authResponse.user))
                } catch {
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Auth decoding error response: \(jsonString)")
                    }
                    completion(.failure(APIError.decodingFailed))
                }
            }
        }.resume()
    }
    
    func logout() {
        clearSession()
    }
    
    // MARK: - Library Helpers
    func addAllToLibrary(completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/library/add-all-to-my-library") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let request = createRequest(url: url, method: "POST")
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(APIError.invalidResponse))
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    self.handleUnauthorized()
                    completion(.failure(APIError.unauthorized))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                
                if let response = self.parseBasicResponse(from: data) {
                    if response.success {
                        completion(.success(response.message ?? "Added music to your library"))
                    } else {
                        let message = response.error ?? response.message ?? "Operation failed"
                        completion(.failure(NSError(domain: "API", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                    }
                } else {
                    completion(.success("Added music to your library"))
                }
            }
        }.resume()
    }
    
    // MARK: - Downloads
    func fetchDownloads(completion: @escaping (Result<[DownloadItem], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/download/list") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let request = createRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(APIError.invalidResponse))
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    self.handleUnauthorized()
                    completion(.failure(APIError.unauthorized))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(DownloadListResponse.self, from: data)
                    completion(.success(response.downloads))
                } catch {
                    if let response = self.parseBasicResponse(from: data),
                       let message = response.error ?? response.message {
                        completion(.failure(NSError(domain: "API", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                    } else {
                        completion(.failure(APIError.decodingFailed))
                    }
                }
            }
        }.resume()
    }
    
    func addDownload(title: String, artist: String, album: String?, playlistId: Int? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        var payload: [String: Any] = ["title": title, "artist": artist]
        if let album = album, !album.isEmpty {
            payload["album"] = album
        }
        if let playlistId = playlistId {
            payload["playlistId"] = playlistId
        }
        performDownloadAction(endpoint: "/api/download/add", payload: payload, completion: completion)
    }
    
    func importSpotifyTrack(url: String, playlistId: Int? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        var payload: [String: Any] = ["url": url]
        if let playlistId = playlistId {
            payload["playlistId"] = playlistId
        }
        performDownloadAction(endpoint: "/api/url-download/song", payload: payload, completion: completion)
    }
    
    func importSpotifyPlaylist(playlistURL: String, playlistId: Int? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        var payload: [String: Any] = ["playlistUrl": playlistURL]
        if let playlistId = playlistId {
            payload["playlistId"] = playlistId
        }
        performDownloadAction(endpoint: "/api/spotify-playlist/import", payload: payload, completion: completion)
    }
    
    func cancelDownload(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/download/cancel/\(id)") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let request = createRequest(url: url, method: "DELETE")
        performBasicOperation(request: request, defaultMessage: "Download cancelled", completion: completion)
    }
    
    func deleteDownload(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/download/delete/\(id)") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let request = createRequest(url: url, method: "DELETE")
        performBasicOperation(request: request, defaultMessage: "Download deleted", completion: completion)
    }
    
    private func performBasicOperation(request: URLRequest, defaultMessage: String, completion: @escaping (Result<Void, Error>) -> Void) {
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(APIError.invalidResponse))
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    self.handleUnauthorized()
                    completion(.failure(APIError.unauthorized))
                    return
                }
                
                if let data = data, let response = self.parseBasicResponse(from: data) {
                    if response.success {
                        completion(.success(()))
                    } else {
                        let message = response.error ?? response.message ?? defaultMessage
                        completion(.failure(NSError(domain: "API", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                    }
                } else {
                    completion(.success(()))
                }
            }
        }.resume()
    }
    
    private func performDownloadAction(endpoint: String, payload: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        guard JSONSerialization.isValidJSONObject(payload),
              let body = try? JSONSerialization.data(withJSONObject: payload) else {
            completion(.failure(APIError.invalidRequest))
            return
        }
        let request = createRequest(url: url, method: "POST", body: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(APIError.invalidResponse))
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    self.handleUnauthorized()
                    completion(.failure(APIError.unauthorized))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                
                if let response = self.parseBasicResponse(from: data) {
                    if response.success {
                        completion(.success(()))
                    } else {
                        let message = response.error ?? response.message ?? "Request failed"
                        completion(.failure(NSError(domain: "API", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                    }
                } else {
                    completion(.failure(APIError.decodingFailed))
                }
            }
        }.resume()
    }
    
    // MARK: - Admin
    func fetchAdminStats(completion: @escaping (Result<AdminStats, Error>) -> Void) {
        guard let request = createAdminRequest(endpoint: "/stats") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        performAdminRequest(request: request, completion: completion)
    }
    
    func fetchAdminUserStatus(completion: @escaping (Result<AdminUserStatusResponse, Error>) -> Void) {
        guard let request = createAdminRequest(endpoint: "/user-status") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        performAdminRequest(request: request, completion: completion)
    }
    
    func checkAdminVersions(completion: @escaping (Result<AdminVersionInfo, Error>) -> Void) {
        guard let request = createAdminRequest(endpoint: "/check-versions") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        performAdminRequest(request: request, completion: completion)
    }
    
    func updateYtDlp(completion: @escaping (Result<String, Error>) -> Void) {
        guard let request = createAdminRequest(endpoint: "/update-ytdlp", method: "POST") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        performAdminAction(request: request, successMessage: "Updating yt-dlp…", completion: completion)
    }
    
    func updateSpotdl(completion: @escaping (Result<String, Error>) -> Void) {
        guard let request = createAdminRequest(endpoint: "/update-spotdl", method: "POST") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        performAdminAction(request: request, successMessage: "Updating spotdl…", completion: completion)
    }
    
    private func performAdminRequest<T: Decodable>(request: URLRequest, completion: @escaping (Result<T, Error>) -> Void) {
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(APIError.invalidResponse))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                
                guard httpResponse.statusCode != 401 else {
                    completion(.failure(APIError.unauthorized))
                    return
                }
                
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decoded))
                } catch {
                    if let response = self.parseBasicResponse(from: data),
                       let message = response.error ?? response.message {
                        completion(.failure(NSError(domain: "API", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                    } else {
                        completion(.failure(APIError.decodingFailed))
                    }
                }
            }
        }.resume()
    }
    
    private func performAdminAction(request: URLRequest, successMessage: String, completion: @escaping (Result<String, Error>) -> Void) {
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(APIError.invalidResponse))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                
                guard httpResponse.statusCode != 401 else {
                    completion(.failure(APIError.unauthorized))
                    return
                }
                
                if let response = self.parseBasicResponse(from: data) {
                    if response.success {
                        completion(.success(response.message ?? successMessage))
                    } else {
                        let message = response.error ?? response.message ?? successMessage
                        completion(.failure(NSError(domain: "API", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                    }
                } else {
                    completion(.success(successMessage))
                }
            }
        }.resume()
    }
}

enum OnlineSearchType: String, CaseIterable, Identifiable {
    case tracks = "track"
    case artists = "artist"
    case albums = "album"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .tracks: return "Tracks"
        case .artists: return "Artists"
        case .albums: return "Albums"
        }
    }
}

struct RemoteTrack: Identifiable, Codable {
    let id: String
    let title: String
    let artistName: String
    let albumTitle: String?
    let duration: Int?
    let image: String?
    let preview: String?
    let source: String?
    let type: String?
    
    var displayTitle: String { title }
    
    var subtitle: String {
        if !artistName.isEmpty { return artistName }
        if let albumTitle, !albumTitle.isEmpty { return albumTitle }
        if let source, !source.isEmpty { return source.capitalized }
        return ""
    }
    
    var artworkURL: URL? {
        guard let image, let url = URL(string: image) else { return nil }
        return url
    }
    
    var durationString: String {
        guard let duration, duration > 0 else { return "" }
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case name
        case artist
        case artistName = "artist_name"
        case album
        case albumName = "album_name"
        case duration
        case durationMs = "duration_ms"
        case image
        case preview
        case source
        case type
        case picture
        case cover
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let stringId = try? container.decode(String.self, forKey: .id) {
            self.id = stringId
        } else if let intId = try? container.decode(Int.self, forKey: .id) {
            self.id = String(intId)
        } else {
            self.id = UUID().uuidString
        }
        
        self.title = (try? container.decode(String.self, forKey: .title)) ??
            (try? container.decode(String.self, forKey: .name)) ??
            "Unknown Title"
        
        if let artistObject = try? container.decode(RemoteArtist.self, forKey: .artist) {
            self.artistName = artistObject.name
        } else if let artistString = try? container.decode(String.self, forKey: .artist) {
            self.artistName = artistString
        } else if let artistFromKey = try? container.decode(String.self, forKey: .artistName) {
            self.artistName = artistFromKey
        } else {
            self.artistName = ""
        }
        
        if let albumObject = try? container.decode(RemoteAlbum.self, forKey: .album) {
            self.albumTitle = albumObject.title
        } else if let albumString = try? container.decode(String.self, forKey: .album) {
            self.albumTitle = albumString
        } else if let albumName = try? container.decode(String.self, forKey: .albumName) {
            self.albumTitle = albumName
        } else {
            self.albumTitle = nil
        }
        
        if let duration = try? container.decode(Int.self, forKey: .duration) {
            self.duration = duration
        } else if let durationMs = try? container.decode(Int.self, forKey: .durationMs) {
            self.duration = durationMs / 1000
        } else {
            self.duration = nil
        }
        
        self.image = (try? container.decode(String.self, forKey: .image))
            ?? (try? container.decode(String.self, forKey: .picture))
            ?? (try? container.decode(String.self, forKey: .cover))
        self.preview = try? container.decodeIfPresent(String.self, forKey: .preview)
        self.source = try? container.decodeIfPresent(String.self, forKey: .source)
        self.type = try? container.decodeIfPresent(String.self, forKey: .type)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(artistName, forKey: .artistName)
        if let albumTitle {
            try container.encode(albumTitle, forKey: .albumName)
        }
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encodeIfPresent(preview, forKey: .preview)
        try container.encodeIfPresent(source, forKey: .source)
        try container.encodeIfPresent(type, forKey: .type)
    }
}

struct RemoteSearchResponse: Codable {
    let success: Bool?
    let data: [RemoteTrack]?
    let items: [RemoteTrack]?
    let results: [RemoteTrack]?
    let tracks: [RemoteTrack]?
    
    var resolvedTracks: [RemoteTrack] {
        data ?? items ?? results ?? tracks ?? []
    }
}

struct RemoteArtist: Codable {
    let id: String?
    let name: String
}

struct RemoteAlbum: Codable {
    let id: String?
    let title: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case name
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try? container.decodeIfPresent(String.self, forKey: .id)
        self.title = (try? container.decode(String.self, forKey: .title))
            ?? (try? container.decode(String.self, forKey: .name))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(title, forKey: .title)
    }
}

struct PlaylistReorderItem {
    let playlistTrackId: Int
    let position: Int
}

struct LibraryStats: Codable {
    let totalSongs: Int
    let totalArtists: Int
    let totalAlbums: Int
    let totalStorage: String?
    let totalStorageBytes: Int?
    
    enum CodingKeys: String, CodingKey {
        case totalSongs
        case totalArtists
        case totalAlbums
        case totalStorage
        case totalStorageBytes
    }
}
