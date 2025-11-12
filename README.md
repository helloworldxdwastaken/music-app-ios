# Music Stream iOS App 🎵

A native iOS music streaming app that connects to your Music Stream backend server. Install via AltStore for wireless music streaming on your iPhone or iPad.

## Features

- 🎵 Stream music from your backend server
- 🔐 Native login & signup with persisted sessions
- 🔍 Search for songs and artists
- 📚 Browse and manage your music library
- 📥 Monitor backend downloads in real time
- 🛠️ Run admin maintenance tasks from the app
- 🎨 Album artwork display
- ⏯️ Background audio playback & remote controls
- 📋 Playlist management

## Native Screens

| Screen | Description |
| --- | --- |
| **Auth** | SwiftUI login & signup backed by `/api/auth/login` and `/api/auth/signup`, with remember-me support. |
| **Home** | Personalized library feed filtered by the authenticated user, quick access to recently added tracks. |
| **Search** | Server-side search with native results list and inline playback. |
| **Library** | Playlist browser plus a one-tap “Add all to my library” action that mirrors the web admin tool. |
| **Downloads** | Live view of `/api/download/list` with start/cancel/delete controls for SpotDL/yt-dlp jobs. |
| **Admin** | Basic-auth guarded dashboard for `/api/admin/*` endpoints (stats, user activity, tool updates, version checks). |
| **Settings** | Server URL override, audio quality preferences, account details, logout, and admin credential storage. |

## Requirements

- iOS 15.0 or later
- Xcode 14+ (for building)
- Music Stream backend server running

## Backend Server

This iOS app connects to the Music Stream backend server.

### Default Server URL (Public)
```
https://stream.noxamusic.com
```

The app is pre-configured to use the public server - **no setup required!** Just install and start streaming.

### Using Your Own Local Server
If you prefer to use a local server:
1. Start the backend: `cd music_app/backend && npm start`
2. Open the app → Settings
3. Change server URL to your local IP (e.g., `http://192.168.1.100:3001`)

You can change the server URL anytime in the app's Settings tab.

## Installation Methods

### Method 1: AltStore (Recommended for Users)

1. Install [AltStore](https://altstore.io/) on your iOS device
2. Download the `MusicStream.ipa` file from the `build` folder
3. Open AltStore on your device
4. Tap the "+" button and select the IPA file
5. Wait for installation to complete

### Method 2: Sideloadly

1. Download [Sideloadly](https://sideloadly.io/)
2. Connect your iOS device to your computer
3. Open Sideloadly and drag the IPA file
4. Enter your Apple ID and install

### Method 3: Xcode (For Developers)

1. Open the project in Xcode
2. Connect your iOS device
3. Select your device in Xcode
4. Click Run (⌘R)

## Building from Source

### Prerequisites

- macOS with Xcode installed
- Command Line Tools
- (Optional) Homebrew for XcodeGen

### Build Steps

1. **Navigate to the project directory:**
   ```bash
   cd "music app ios"
   ```

2. **Run the build script:**
   ```bash
   chmod +x build.sh
   ./build.sh
   ```

3. **Find your IPA:**
   The IPA file will be in the `build` folder

### Manual Build

If you prefer to build manually:

```bash
# Generate Xcode project (if needed)
xcodegen generate

# Build archive
xcodebuild archive \
    -project MusicStream.xcodeproj \
    -scheme MusicStream \
    -archivePath build/MusicStream.xcarchive

# Export IPA
xcodebuild -exportArchive \
    -archivePath build/MusicStream.xcarchive \
    -exportPath build \
    -exportOptionsPlist ExportOptions.plist
```

## Configuration

### Server URL Setup

**Default (Public Server):**
- The app comes pre-configured with `https://stream.noxamusic.com`
- No setup needed - just install and use!

**Using a Custom Server:**
1. Open the app
2. Go to Settings tab
3. Tap on "Server URL"
4. Enter your backend server URL
5. Tap "Test Connection" to verify

### Network Requirements

**For Public Server (Default):**
- Just need internet connection
- Works anywhere - WiFi or cellular
- HTTPS secure connection

**For Local Server:**
- Same WiFi network as your server
- Use your computer's local IP address
- Port forwarding for remote access

**Example URLs:**
- Public: `https://stream.noxamusic.com` (default)
- Local: `http://192.168.1.100:3001`
- Custom: `https://your-domain.com`

## Project Structure

```
music app ios/
├── MusicStreamApp.swift          # App entry point
├── ContentView.swift             # Main tab view
├── Info.plist                    # App configuration
├── Views/
│   ├── HomeView.swift           # Home screen
│   ├── SearchView.swift         # Search interface
│   ├── LibraryView.swift        # Music library
│   ├── DownloadsView.swift      # Backend download manager
│   ├── AdminView.swift          # Admin tooling dashboard
│   ├── SettingsView.swift       # App settings
│   ├── AuthView.swift           # Login/signup flow
│   ├── RootView.swift           # Auth gating wrapper
│   ├── NowPlayingView.swift     # Full-screen player
│   ├── PlaylistDetailView.swift # Playlist details
│   └── Components/
│       ├── SongCardView.swift   # Song card component
│       ├── SongRowView.swift    # Song row component
│       └── PlaylistRowView.swift # Playlist row component
├── Models/
│   ├── Song.swift               # Song model
│   ├── Playlist.swift           # Playlist & responses
│   ├── User.swift               # Auth/user data
│   ├── Download.swift           # Download queue models
│   └── AdminModels.swift        # Admin endpoint models
│   ├── Song.swift               # Song data model
│   └── Playlist.swift           # Playlist data model
├── Services/
│   ├── APIService.swift         # Backend API integration
│   └── AudioPlayerManager.swift # Audio playback
├── Assets.xcassets/             # App icons and colors
├── build.sh                     # Build script
├── project.yml                  # XcodeGen config
└── ExportOptions.plist          # IPA export settings
```

## API Endpoints Used

The app communicates with these backend endpoints:

- `GET /api/library/library` - Get music library
- `GET /api/music/search` - Search songs
- `GET /api/music/stream/:id` - Stream audio
- `GET /api/playlists` - Get playlists
- `GET /api/playlists/:id/songs` - Get playlist songs

## Troubleshooting

### Cannot Connect to Server

- Verify the server URL is correct
- Ensure your backend server is running
- Check firewall settings
- Make sure both devices are on the same network (for local connections)

### Audio Not Playing

- Check device volume
- Verify the stream URL is accessible
- Check backend server logs
- Ensure audio files exist on the server

### Build Errors

- Update Xcode to the latest version
- Clean build folder (⇧⌘K in Xcode)
- Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- Verify all source files are present

### AltStore Installation Issues

- Ensure AltStore is properly set up
- Check that your device is authorized
- Verify the IPA file is not corrupted
- Try reinstalling AltStore

## Development

### Adding New Features

1. Create new Swift files in appropriate folders
2. Update `project.yml` if adding new targets
3. Test on iOS Simulator first
4. Build and test on physical device

### Code Signing

For distribution outside AltStore, you'll need:
- Apple Developer Account ($99/year)
- Valid provisioning profile
- Update `DEVELOPMENT_TEAM` in `project.yml`

## Screenshots

The app features:
- Clean, modern interface
- Dark mode support
- Smooth animations
- Native iOS controls
- Gesture support

## Contributing

Contributions are welcome! Please ensure:
- Code follows Swift style guidelines
- UI is tested on iPhone and iPad
- No breaking changes to API integration

## License

This project is part of the Music Stream application suite.

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review backend server logs
3. Verify network connectivity
4. Test API endpoints directly

## Roadmap

Future features:
- [ ] Offline playback
- [ ] Download management
- [ ] Enhanced search filters
- [ ] Lyrics display
- [ ] Equalizer
- [ ] AirPlay support
- [ ] CarPlay integration
- [ ] Widget support

---

**Happy Streaming! 🎵**

