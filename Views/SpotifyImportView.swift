import SwiftUI

struct SpotifyImportView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var apiService: APIService
    let mode: ImportMode
    
    @State private var urlText = ""
    @State private var playlistIdText = ""
    @State private var isSubmitting = false
    @State private var feedbackMessage: String?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(mode.sectionTitle), footer: Text(mode.hintText)) {
                    TextField(mode.placeholder, text: $urlText)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                }
                Section(header: Text("Playlist (optional)"), footer: Text("Provide the numeric playlist ID if you want the import to file tracks directly into an existing playlist.")) {
                    TextField("Playlist ID", text: $playlistIdText)
                        .keyboardType(.numberPad)
                }
                if isSubmitting {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Processing…")
                        }
                    }
                }
                if let feedbackMessage {
                    Section {
                        Text(feedbackMessage)
                            .foregroundColor(.green)
                    }
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(mode.sheetTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.ctaTitle, action: startImport)
                        .disabled(isSubmitting || urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func startImport() {
        let trimmedURL = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else {
            errorMessage = "Paste a valid link first."
            return
        }
        let playlistId = Int(playlistIdText.trimmingCharacters(in: .whitespacesAndNewlines))
        feedbackMessage = nil
        errorMessage = nil
        isSubmitting = true
        
        let completion: (Result<Void, Error>) -> Void = { result in
            isSubmitting = false
            switch result {
            case .success:
                feedbackMessage = mode.successMessage
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    dismiss()
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
        
        switch mode {
        case .spotifyTrack:
            apiService.importSpotifyTrack(url: trimmedURL, playlistId: playlistId, completion: completion)
        case .spotifyPlaylist:
            apiService.importSpotifyPlaylist(playlistURL: trimmedURL, playlistId: playlistId, completion: completion)
        }
    }
}

struct SpotifyImportView_Previews: PreviewProvider {
    static var previews: some View {
        SpotifyImportView(apiService: APIService(), mode: .spotifyTrack)
    }
}
