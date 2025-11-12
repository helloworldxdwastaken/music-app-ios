//
//  AdminView.swift
//  Music Stream
//

import SwiftUI

struct AdminView: View {
    @EnvironmentObject private var apiService: APIService
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var rememberCredentials = true
    @State private var stats: AdminStats?
    @State private var userStatus: AdminUserStatusResponse?
    @State private var versions: AdminVersionInfo?
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    @State private var isLoadingStats = false
    @State private var isLoadingUsers = false
    @State private var isCheckingVersions = false
    @State private var isUpdatingTools = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [Color.black, Color(red: 0.04, green: 0.05, blue: 0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        credentialsSection
                        actionsSection
                        statsSection
                        versionsSection
                        usersSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 32)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Admin Tools")
            .applyDarkNavBar()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") { clearStoredCredentials() }
                        .disabled(apiService.adminCredentials == nil && username.isEmpty && password.isEmpty)
                        .foregroundColor(.red)
                }
            }
            .onAppear(perform: syncCredentials)
            .alert("Admin Error", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
            .alert("Success", isPresented: Binding(get: { statusMessage != nil }, set: { if !$0 { statusMessage = nil } })) {
                Button("OK") { statusMessage = nil }
            } message: {
                Text(statusMessage ?? "")
            }
        }
    }
    
    private var credentialsSection: some View {
        adminCard(title: "Credentials", icon: "key.fill", accent: .orange) {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Username")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    TextField("Enter username", text: $username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .foregroundColor(.white)
                        .padding(14)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    SecureField("Enter password", text: $password)
                        .textContentType(.password)
                        .foregroundColor(.white)
                        .padding(14)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                
                Toggle("Remember on device", isOn: $rememberCredentials)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                    .tint(.green)
                
                Button(action: saveCredentials) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Credentials")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        Group {
                            if username.isEmpty || password.isEmpty {
                                Color.white.opacity(0.08)
                            } else {
                                LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
                            }
                        }
                    )
                    .foregroundColor((username.isEmpty || password.isEmpty) ? .white.opacity(0.6) : .black)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(username.isEmpty || password.isEmpty)
                
                if hasCredentials {
                    Text("Credentials stored securely on this device only.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    private var actionsSection: some View {
        adminCard(title: "Actions", icon: "gearshape.fill", accent: .blue) {
            VStack(spacing: 12) {
                actionButton(title: "Library Stats", icon: "chart.bar.fill", color: .blue, action: loadStats, isLoading: isLoadingStats)
                actionButton(title: "User Activity", icon: "person.2.fill", color: .green, action: loadUserStatus, isLoading: isLoadingUsers)
                actionButton(title: "Check Tool Versions", icon: "wrench.fill", color: .purple, action: checkVersions, isLoading: isCheckingVersions)
                actionButton(title: "Update yt-dlp", icon: "arrow.triangle.2.circlepath", color: .orange, action: updateYtDlp, isLoading: isUpdatingTools)
                actionButton(title: "Update spotdl", icon: "arrow.triangle.2.circlepath", color: .pink, action: updateSpotdl, isLoading: isUpdatingTools)
            }
        }
    }
    
    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void, isLoading: Bool) -> some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .frame(width: 24)
                }
                Text(title)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.4))
                    .font(.caption)
            }
            .padding()
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(!hasCredentials || isLoading)
        .opacity((!hasCredentials || isLoading) ? 0.6 : 1.0)
    }
    
    private var statsSection: some View {
        adminCard(title: "Library Stats", icon: "chart.bar.fill", accent: .blue) {
            if let stats = stats {
                VStack(spacing: 16) {
                    statRow(icon: "music.note", title: "Total Songs", value: "\(stats.totalSongs ?? 0)")
                    Divider()
                    statRow(icon: "play.fill", title: "Total Plays", value: "\(stats.totalPlays ?? 0)")
                    Divider()
                    statRow(icon: "chart.line.uptrend.xyaxis", title: "Average Plays", value: String(format: "%.2f", stats.avgPlays ?? 0))
                    Divider()
                    statRow(icon: "person.2.fill", title: "Unique Artists", value: "\(stats.uniqueArtists ?? 0)")
                    Divider()
                    statRow(icon: "square.stack.fill", title: "Unique Albums", value: "\(stats.uniqueAlbums ?? 0)")
                    if let bytes = stats.totalSizeBytes {
                        Divider()
                        statRow(icon: "internaldrive.fill", title: "Storage", value: ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file))
                    }
                }
            } else {
                Text("No stats loaded yet")
                    .foregroundColor(.white.opacity(0.65))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }
    
    private func statRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.mint)
                .frame(width: 24)
            Text(title)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
    
    private var versionsSection: some View {
        adminCard(title: "Tool Versions", icon: "wrench.fill", accent: .purple) {
            if let versions = versions?.versions, !versions.isEmpty {
                VStack(spacing: 16) {
                    ForEach(Array(versions.keys.sorted().enumerated()), id: \.element) { index, key in
                        if index > 0 {
                            Divider()
                        }
                        HStack {
                            Image(systemName: "app.badge.fill")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            Text(key.uppercased())
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(versions[key] ?? "-")
                                .foregroundColor(.primary)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else {
                Text("Check versions to populate")
                    .foregroundColor(.white.opacity(0.65))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }
    
    private var usersSection: some View {
        adminCard(title: "User Activity", icon: "person.2.fill", accent: .green) {
            if let summary = userStatus?.summary {
                VStack(spacing: 16) {
                    HStack {
                        statRow(icon: "person.3.fill", title: "Total Users", value: "\(summary.totalUsers)")
                    }
                    Divider()
                    HStack {
                        statRow(icon: "clock.fill", title: "Active Today", value: "\(summary.activeToday)")
                    }
                    Divider()
                    HStack {
                        statRow(icon: "circle.fill", title: "Online Now", value: "\(summary.onlineNow)")
                    }
                    
                    if let users = userStatus?.users, !users.isEmpty {
                        Divider()
                            .padding(.vertical, 8)
                        
                        Text("Recent Users")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 4)
                        
                        ForEach(users.prefix(5)) { user in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(user.username)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if user.isOnline == true {
                                        HStack(spacing: 4) {
                                            Circle()
                                                .fill(Color.green)
                                                .frame(width: 8, height: 8)
                                            Text("Online")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                                if let last = user.lastActivity {
                                    Text("Last Activity: \(last)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
            } else {
                Text("Fetch user activity to view details")
                    .foregroundColor(.white.opacity(0.65))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }
    
    private func adminCard<Content: View>(title: String, icon: String, accent: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                iconBadge(systemName: icon, tint: accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                    Text("Manage \(title.lowercased())")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            content()
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 20, y: 10)
    }
    
    private func iconBadge(systemName: String, tint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.18))
                .frame(width: 44, height: 44)
            Image(systemName: systemName)
                .foregroundColor(tint)
        }
    }
    
    private var hasCredentials: Bool {
        apiService.adminCredentials != nil
    }
    
    
    private func syncCredentials() {
        if let creds = apiService.adminCredentials {
            username = creds.username
            password = creds.password
            rememberCredentials = true
        } else {
            rememberCredentials = false
        }
    }
    
    private func saveCredentials() {
        apiService.setAdminCredentials(username: username, password: password, remember: rememberCredentials)
        statusMessage = "Credentials saved"
    }
    
    private func clearStoredCredentials() {
        apiService.clearAdminCredentials()
        username = ""
        password = ""
        rememberCredentials = false
        statusMessage = "Credentials cleared"
    }
    
    private func loadStats() {
        isLoadingStats = true
        apiService.fetchAdminStats { result in
            isLoadingStats = false
            switch result {
            case .success(let stats):
                self.stats = stats
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func loadUserStatus() {
        isLoadingUsers = true
        apiService.fetchAdminUserStatus { result in
            isLoadingUsers = false
            switch result {
            case .success(let status):
                self.userStatus = status
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func checkVersions() {
        isCheckingVersions = true
        apiService.checkAdminVersions { result in
            isCheckingVersions = false
            switch result {
            case .success(let info):
                self.versions = info
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func updateYtDlp() {
        isUpdatingTools = true
        apiService.updateYtDlp { result in
            isUpdatingTools = false
            switch result {
            case .success(let message):
                statusMessage = message
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func updateSpotdl() {
        isUpdatingTools = true
        apiService.updateSpotdl { result in
            isUpdatingTools = false
            switch result {
            case .success(let message):
                statusMessage = message
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

}

struct AdminView_Previews: PreviewProvider {
    static var previews: some View {
        AdminView()
            .environmentObject(APIService())
    }
}
