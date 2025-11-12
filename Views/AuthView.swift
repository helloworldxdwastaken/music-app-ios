//
//  AuthView.swift
//  Music Stream
//

import SwiftUI
import UIKit

struct AuthView: View {
    @EnvironmentObject private var apiService: APIService
    @State private var mode: AuthMode = .login
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var rememberMe: Bool = true
    @State private var errorMessage: String?
    @State private var showAlert = false
    @FocusState private var focusedField: Field?
    
    enum AuthMode: String, CaseIterable {
        case login = "Login"
        case signup = "Sign Up"
    }
    
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 18) {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Noxa Music")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(mode == .login ? "Log in to keep the music going." : "Sign up and start streaming.")
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.75))
            }
            
            Spacer()
        }
    }
    
    private var formCard: some View {
        VStack(spacing: 24) {
            Picker("Mode", selection: $mode) {
                ForEach(AuthMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .tint(.green)
            .onAppear {
                UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
                UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
                UISegmentedControl.appearance().backgroundColor = UIColor.white.withAlphaComponent(0.05)
            }
            
            VStack(spacing: 14) {
                inputField(icon: "person.fill", isFocused: focusedField == .username) {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.username)
                        .foregroundColor(.white)
                        .accentColor(.green)
                        .focused($focusedField, equals: .username)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                }
                
                inputField(icon: "lock.fill", isFocused: focusedField == .password) {
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .foregroundColor(.white)
                        .accentColor(.green)
                        .focused($focusedField, equals: .password)
                        .submitLabel(mode == .signup ? .next : .go)
                        .onSubmit { mode == .signup ? focusedField = .confirmPassword : authenticate() }
                }
                
                if mode == .signup {
                    inputField(icon: "lock.rotation", isFocused: focusedField == .confirmPassword) {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.password)
                            .foregroundColor(.white)
                            .accentColor(.green)
                            .focused($focusedField, equals: .confirmPassword)
                            .submitLabel(.go)
                            .onSubmit { authenticate() }
                    }
                }
            }
            
            rememberRow
            
            Button(action: authenticate) {
                HStack(spacing: 12) {
                    if apiService.isAuthenticating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                        Text(mode == .login ? "Log In" : "Create Account")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundColor(.white)
                .background(
                    LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.green.opacity(0.4), radius: 18, y: 6)
            }
            .disabled(submitDisabled)
            .opacity(submitDisabled ? 0.5 : 1)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 30, y: 15)
    }
    
    private var rememberRow: some View {
        HStack {
            Button(action: { rememberMe.toggle() }) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(rememberMe ? Color.green : Color.clear)
                            .frame(width: 22, height: 22)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(rememberMe ? Color.green : Color.white.opacity(0.35), lineWidth: 1.5)
                            )
                        if rememberMe {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    Text("Remember me")
                        .foregroundColor(.white.opacity(0.85))
                        .font(.subheadline)
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button("Forgot password?") {
                errorMessage = "Contact us on Discord to reset your password."
                showAlert = true
            }
            .font(.footnote.weight(.semibold))
            .foregroundColor(.white.opacity(0.75))
        }
    }
    
    private func inputField<Content: View>(icon: String, isFocused: Bool, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(isFocused ? .green : .white.opacity(0.7))
                .frame(width: 24)
            content()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isFocused ? Color.green : Color.white.opacity(0.15), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 10, y: 4)
    }
    
    private var submitDisabled: Bool {
        apiService.isAuthenticating ||
        username.isEmpty ||
        password.isEmpty ||
        (mode == .signup && password != confirmPassword)
    }
    
    enum Field {
        case username
        case password
        case confirmPassword
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.07, blue: 0.18),
                        Color(red: 0.0, green: 0.2, blue: 0.18),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                Circle()
                    .fill(Color.green.opacity(0.25))
                    .frame(width: 320, height: 320)
                    .blur(radius: 120)
                    .offset(x: -150, y: -260)
                
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 280, height: 280)
                    .blur(radius: 100)
                    .offset(x: 160, y: 200)
                
                GeometryReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 28) {
                            headerSection
                            formCard
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                        .padding(.bottom, 80)
                        .frame(minHeight: proxy.size.height, alignment: .center)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Authentication Failed"),
                    message: Text(errorMessage ?? "Unknown error"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func authenticate() {
        errorMessage = nil
        if mode == .signup && password != confirmPassword {
            errorMessage = "Passwords do not match"
            showAlert = true
            return
        }
        
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUsername.isEmpty else {
            errorMessage = "Please enter a username"
            showAlert = true
            return
        }
        
        switch mode {
        case .login:
            apiService.login(username: trimmedUsername, password: password, rememberMe: rememberMe) { result in
                handleAuthResult(result)
            }
        case .signup:
            apiService.signup(username: trimmedUsername, password: password, rememberMe: rememberMe) { result in
                handleAuthResult(result)
            }
        }
    }
    
    private func handleAuthResult(_ result: Result<User, Error>) {
        switch result {
        case .success:
            clearFields()
        case .failure(let error):
            errorMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func clearFields() {
        username = ""
        password = ""
        confirmPassword = ""
        focusedField = nil
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(APIService())
    }
}
