//
//  SettingsView.swift
//  Music Stream
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var apiService: APIService
    @AppStorage("serverURL") private var serverURL = "https://stream.noxamusic.com"
    @AppStorage("audioQuality") private var audioQuality = "high"
    @State private var showingURLEditor = false
    @State private var showingLogoutConfirmation = false
    @State private var connectionTestResult: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [Color.black, Color(red: 0.05, green: 0.08, blue: 0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        if let user = apiService.currentUser {
                            settingsCard(title: "Account", icon: "person.crop.circle.fill", accent: .mint) {
                                settingRow(icon: "person.fill", title: "Username", value: user.username)
                                
                                if let email = user.email, !email.isEmpty {
                                    Divider().blendMode(.overlay)
                                    settingRow(icon: "envelope.fill", title: "Email", value: email)
                                }
                                
                                if let lastLogin = user.lastLogin {
                                    Divider().blendMode(.overlay)
                                    settingRow(icon: "clock.fill", title: "Last Login", value: lastLogin)
                                }
                                
                                Divider().blendMode(.overlay)
                                
                                Button(action: { showingLogoutConfirmation = true }) {
                                    HStack {
                                        Image(systemName: "arrow.backward.square.fill")
                                        Text("Log Out")
                                            .fontWeight(.semibold)
                                        Spacer()
                                    }
                                    .foregroundColor(.red)
                                    .padding(.vertical, 6)
                    }
                    .padding(.bottom, 80)
                }
                        }
                        
                        settingsCard(title: "Server Configuration", icon: "server.rack", accent: .blue) {
                            Button(action: { showingURLEditor = true }) {
                                HStack(spacing: 14) {
                                    iconBadge(systemName: "link", tint: .blue)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Server URL")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                        Text(serverURL)
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.35))
                                }
                                .padding(.vertical, 4)
                            }
                            
                            Divider().blendMode(.overlay)
                            
                            Button(action: testConnection) {
                                HStack(spacing: 12) {
                                    iconBadge(systemName: "waveform.badge.mic", tint: .green)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Test Connection")
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                        Text("Ensure your music server responds before streaming.")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    Spacer()
                                    if let result = connectionTestResult {
                                        Text(result)
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(result == "Success" ? .green : .red)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        
                        settingsCard(title: "Audio Settings", icon: "waveform", accent: .purple) {
                            VStack(spacing: 18) {
                                HStack {
                                    Text("Streaming Quality")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(audioQuality.capitalized)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Picker("Audio Quality", selection: $audioQuality) {
                                    Text("Low").tag("low")
                                    Text("Medium").tag("medium")
                                    Text("High").tag("high")
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        
                        settingsCard(title: "App Information", icon: "info.circle.fill", accent: .orange) {
                            settingRow(icon: "number", title: "Version", value: "1.0")
                            Divider().blendMode(.overlay)
                            settingRow(icon: "hammer.fill", title: "Build", value: "1")
                        }
                        
                        settingsCard(title: "Support", icon: "questionmark.circle.fill", accent: .indigo) {
                            Text("Need help? Contact the team or browse the help center for quick answers.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.75))
                            
                            Button(action: {
                                if let url = URL(string: "https://support.noxamusic.com") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("Visit Help Center")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.indigo.opacity(0.2))
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 32)
                }
            }
            .navigationTitle("Settings")
            .applyDarkNavBar()
            .alert("Server URL", isPresented: $showingURLEditor) {
                TextField("Server URL", text: $serverURL)
                Button("Save") {
                    apiService.updateBaseURL(serverURL)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter your music server URL")
            }
            .confirmationDialog("Are you sure you want to log out?", isPresented: $showingLogoutConfirmation, titleVisibility: .visible) {
                Button("Log Out", role: .destructive) {
                    apiService.logout()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    private func settingsCard<Content: View>(title: String, icon: String, accent: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
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
        .shadow(color: Color.black.opacity(0.35), radius: 25, y: 12)
    }
    
    private func iconBadge(systemName: String, tint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.18))
                .frame(width: 42, height: 42)
            Image(systemName: systemName)
                .foregroundColor(tint)
        }
    }
    
    private func settingRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
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
    
    private func testConnection() {
        connectionTestResult = nil
        apiService.testConnection { success in
            connectionTestResult = success ? "Success" : "Failed"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                connectionTestResult = nil
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(APIService())
    }
}
