//
//  CreatePlaylistSheet.swift
//  Music Stream
//

import SwiftUI

struct CreatePlaylistSheet: View {
    @EnvironmentObject private var apiService: APIService
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var isSaving = false
    @State private var statusMessage: String?


    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField("Playlist Name", text: $name)
                        .autocorrectionDisabled()
                }

                Section(header: Text("Description")) {
                    TextField("Optional description", text: $description)
                        .autocorrectionDisabled()
                }

                if let statusMessage {
                    Section {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Create") { createPlaylist() }
                            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }

    private func createPlaylist() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            statusMessage = "Playlist name cannot be empty."
            return
        }

        isSaving = true
        statusMessage = nil

        apiService.createPlaylist(name: trimmedName, description: description.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty()) { result in
            isSaving = false
            switch result {
            case .success:
                NotificationCenter.default.post(name: .playlistsDidChange, object: nil)
                dismiss()
            case .failure(let error):
                statusMessage = error.localizedDescription
            }
        }
    }
}

private extension String {
    func nilIfEmpty() -> String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct CreatePlaylistSheet_Previews: PreviewProvider {
    static var previews: some View {
        CreatePlaylistSheet()
            .environmentObject(APIService())
    }
}
