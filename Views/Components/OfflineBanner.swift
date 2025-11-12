import SwiftUI

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .imageScale(.medium)
            VStack(alignment: .leading, spacing: 2) {
                Text("Offline Mode")
                    .font(.footnote.weight(.semibold))
                Text("Only downloaded playlists are available")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .opacity(0.95)
        .cornerRadius(18)
        .padding(.top, 16)
        .padding(.horizontal, 24)
    }
}

struct OfflineBanner_Previews: PreviewProvider {
    static var previews: some View {
        OfflineBanner()
            .preferredColorScheme(.dark)
            .background(Color.black)
    }
}
