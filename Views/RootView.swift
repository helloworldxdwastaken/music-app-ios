//
//  RootView.swift
//  Music Stream
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var apiService: APIService
    
    var body: some View {
        Group {
            if apiService.isAuthenticated {
                ContentView()
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut, value: apiService.isAuthenticated)
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(APIService())
            .environmentObject(OfflineManager())
            .environmentObject(ConnectivityService())
    }
}
