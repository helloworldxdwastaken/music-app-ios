//
//  DownloadsView.swift
//  Music Stream
//

import SwiftUI
import Combine

struct DownloadsView: View {
    @EnvironmentObject private var apiService: APIService
    @State private var downloads: [DownloadItem] = []
    @State private var isLoading = false
    @State private var showNewDownloadSheet = false
    @State private var titleInput = ""
    @State private var artistInput = ""
    @State private var albumInput = ""
    @State private var feedbackMessage: String?
    @State private var errorMessage: String?
    
    @State private var importMode: ImportMode?
    
    var body: some View {
        NavigationView {
            Group {
                if !apiService.isAuthenticated {
                    VStack(spacing: 16) {
                        Image(systemName: "lock.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("Sign in to manage downloads")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                } else if isLoading && downloads.isEmpty {
                    ProgressView("Loading downloads…")
                } else if downloads.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No downloads yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Button("Start a download") {
                            showNewDownloadSheet = true
                        }
                    }
                } else {
                    List {
                        Section(header: Text("Active Downloads")) {
                            ForEach(activeDownloads) { item in
                                DownloadRow(item: item,
                                            cancelAction: { cancel(download: item) },
                                            deleteAction: { delete(download: item) })
                            }
                        }
                        if !completedDownloads.isEmpty {
                            Section(header: Text("Completed")) {
                                ForEach(completedDownloads) { item in
                                    DownloadRow(item: item,
                                                cancelAction: { cancel(download: item) },
                                                deleteAction: { delete(download: item) })
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await reloadDownloads() }
                }
            }
            .navigationTitle("Downloads")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        Task { await reloadDownloads(force: true) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(!apiService.isAuthenticated)
                    
                    Menu {
                        Button {
                            startImport(mode: .spotifyTrack)
                        } label: {
                            Label("Import Spotify Track", systemImage: "music.note")
                        }
                        Button {
                            startImport(mode: .spotifyPlaylist)
                        } label: {
                            Label("Import Spotify Playlist", systemImage: "music.note.list")
                        }
                        Button {
                            showNewDownloadSheet = true
                        } label: {
                            Label("Manual Entry", systemImage: "square.and.pencil")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(!apiService.isAuthenticated)
                }
            }
            .onAppear {
                Task { await reloadDownloads() }
            }
            .task {
                for await _ in Timer.publish(every: 10, tolerance: 2, on: .main, in: .common).autoconnect().values {
                    if apiService.isAuthenticated && !showNewDownloadSheet {
                        await reloadDownloads()
                    }
                }
            }
            .sheet(isPresented: $showNewDownloadSheet) {
                downloadForm()
                    .presentationCompat()
            }
            .sheet(item: $importMode) { mode in
                spotifyImportForm(mode: mode)
            }
            .alert("Download Error", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }
    
    private var activeDownloads: [DownloadItem] {
        downloads.filter { !($0.status == .completed) }
    }
    
    private var completedDownloads: [DownloadItem] {
        downloads.filter { $0.status == .completed }
    }
    private var feedbackSection: some View {
        Group {
            if let feedback = feedbackMessage {
                Text(feedback)
                    .foregroundColor(.green)
            }
        }
    }
    
    @MainActor
    private func reloadDownloads(force: Bool = false) async {
        guard apiService.isAuthenticated else {
            downloads = []
            isLoading = false
            return
        }
        if !force && isLoading { return }
        isLoading = true
        apiService.fetchDownloads { result in
            self.isLoading = false
            switch result {
            case .success(let list):
                self.downloads = list
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func startDownload() {
        feedbackMessage = nil
        apiService.addDownload(title: titleInput, artist: artistInput, album: albumInput.isEmpty ? nil : albumInput) { result in
            switch result {
            case .success:
                feedbackMessage = "Download queued"
                titleInput = ""
                artistInput = ""
                albumInput = ""
                Task { await reloadDownloads(force: true) }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func cancel(download: DownloadItem) {
        apiService.cancelDownload(id: download.id) { result in
            if case .failure(let error) = result {
                errorMessage = error.localizedDescription
            } else {
                Task { await reloadDownloads(force: true) }
            }
        }
    }
    
    private func delete(download: DownloadItem) {
        apiService.deleteDownload(id: download.id) { result in
            if case .failure(let error) = result {
                errorMessage = error.localizedDescription
            } else {
                Task { await reloadDownloads(force: true) }
            }
        }
    }
    
    private func resetForm() {
        titleInput = ""
        artistInput = ""
        albumInput = ""
        feedbackMessage = nil
    }
    
    @ViewBuilder
    private func downloadForm() -> some View {
        NavigationView {
            Form {
                Section(header: Text("Track")) {
                    TextField("Title", text: $titleInput)
                    TextField("Artist", text: $artistInput)
                    TextField("Album (optional)", text: $albumInput)
                }
                Section(footer: feedbackSection) {}
            }
            .navigationTitle("New Download")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        resetForm()
                        showNewDownloadSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") { startDownload() }
                        .disabled(titleInput.isEmpty || artistInput.isEmpty)
                }
            }
        }
    }
    
    @ViewBuilder
    private func spotifyImportForm(mode: ImportMode) -> some View {
        SpotifyImportView(apiService: apiService, mode: mode)
    }
    
    private func startImport(mode: ImportMode) {
        importMode = mode
    }
}

private struct DownloadRow: View {
    let item: DownloadItem
    let cancelAction: () -> Void
    let deleteAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                    Text(item.artist)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if let album = item.album, !album.isEmpty {
                        Text(album)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                statusLabel
            }
            if let progress = item.progress, item.status == .downloading {
                ProgressView(value: Double(progress) / 100.0)
            }
            HStack(spacing: 16) {
                if item.status == .downloading || item.status == .searching {
                    Button("Cancel", role: .destructive, action: cancelAction)
                }
                Button("Remove", role: .destructive, action: deleteAction)
                    .buttonStyle(.bordered)
            }
            .font(.footnote)
        }
        .padding(.vertical, 6)
    }
    
    private var statusLabel: some View {
        let status = item.status
        return Label(status.displayName, systemImage: icon(for: status))
            .labelStyle(.titleAndIcon)
            .foregroundColor(color(for: status))
            .font(.subheadline)
    }
    
    private func icon(for status: DownloadStatus) -> String {
        switch status {
        case .downloading: return "arrow.down.circle"
        case .searching: return "magnifyingglass"
        case .completed: return "checkmark.circle"
        case .failed: return "xmark.octagon"
        case .cancelled: return "stop.circle"
        case .unknown: return "questionmark.circle"
        }
    }
    
    private func color(for status: DownloadStatus) -> Color {
        switch status {
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        case .downloading, .searching: return .blue
        case .unknown: return .secondary
        }
    }
}

struct DownloadsView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadsView()
            .environmentObject(APIService())
    }
}

enum ImportMode: Identifiable {
    case spotifyTrack
    case spotifyPlaylist
    
    var id: Int {
        hashValue
    }
    
    var title: String {
        switch self {
        case .spotifyTrack: return "Spotify Track"
        case .spotifyPlaylist: return "Spotify Playlist"
        }
    }
}

extension ImportMode {
    var sheetTitle: String {
        switch self {
        case .spotifyTrack: return "Import Track"
        case .spotifyPlaylist: return "Import Playlist"
        }
    }
    
    var sectionTitle: String {
        switch self {
        case .spotifyTrack: return "Track Link"
        case .spotifyPlaylist: return "Playlist Link"
        }
    }
    
    var hintText: String {
        switch self {
        case .spotifyTrack:
            return "Paste a Spotify track link or YouTube URL that spotdl can resolve."
        case .spotifyPlaylist:
            return "Paste a Spotify playlist link. Tracks will queue sequentially."
        }
    }
    
    var placeholder: String {
        switch self {
        case .spotifyTrack: return "https://open.spotify.com/track/..."
        case .spotifyPlaylist: return "https://open.spotify.com/playlist/..."
        }
    }
    
    var ctaTitle: String {
        switch self {
        case .spotifyTrack: return "Import"
        case .spotifyPlaylist: return "Queue"
        }
    }
    
    var successMessage: String {
        switch self {
        case .spotifyTrack: return "Track queued for download"
        case .spotifyPlaylist: return "Playlist import started"
        }
    }
}
