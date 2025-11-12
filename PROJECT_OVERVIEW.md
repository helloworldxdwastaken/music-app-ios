# Music Stream iOS App - Project Overview 🎵

## What Is This?

A **native iOS app** for streaming music from your Music Stream backend server. It connects to the backend running in the `music_app` folder and provides a beautiful, native iOS experience with full audio playback capabilities.

## Key Features

### ✨ Core Functionality
- 🎵 **Stream Music** - Direct streaming from your backend server
- 🔍 **Search** - Find songs, artists, and albums instantly  
- 📚 **Library** - Browse your complete music collection
- 📋 **Playlists** - View and play your curated playlists
- 🎨 **Album Art** - Beautiful artwork displays
- ⏯️ **Full Playback Control** - Play, pause, skip, seek
- 🔊 **Background Audio** - Listen while using other apps
- 🎛️ **Lock Screen Controls** - Control music from lock screen

### 🎨 User Interface
- Native iOS design language
- SwiftUI for smooth, modern UI
- Dark mode support
- Responsive layouts for iPhone & iPad
- Gesture-based navigation
- Beautiful animations

### 🔧 Technical Features
- **Backend Integration** - Connects to existing music_app server
- **Audio Streaming** - AVPlayer for high-quality playback
- **Media Controls** - System-level audio controls
- **Network Flexibility** - Works on local network or remote
- **Configurable** - Easy server URL configuration

## Architecture

### 📱 iOS App (Client)
```
music app ios/
├── SwiftUI Views (User Interface)
├── Audio Player (Playback Engine)
├── API Service (Backend Communication)
└── Models (Data Structures)
```

### 🖥️ Backend Server
```
music_app/backend/
├── Express Server (API)
├── Music Library (Storage)
├── Stream Endpoints (Audio Delivery)
└── Database (Metadata)
```

### 🔄 Communication Flow
```
iOS App → HTTP/HTTPS → Backend Server
         ← JSON Data ←
         ← Audio Stream ←
```

## File Structure

```
music app ios/
│
├── 📄 Core App Files
│   ├── MusicStreamApp.swift          # App entry point
│   ├── ContentView.swift             # Main navigation
│   └── Info.plist                    # App configuration
│
├── 📱 Views (User Interface)
│   ├── HomeView.swift               # Home screen with library
│   ├── SearchView.swift             # Search functionality
│   ├── LibraryView.swift            # Complete library view
│   ├── SettingsView.swift           # App settings
│   ├── NowPlayingView.swift         # Full-screen player
│   ├── PlaylistDetailView.swift     # Playlist contents
│   └── Components/
│       ├── SongCardView.swift       # Card-style song display
│       ├── SongRowView.swift        # List-style song display
│       └── PlaylistRowView.swift    # Playlist row display
│
├── 🗂️ Models (Data Structures)
│   ├── Song.swift                   # Song data model
│   └── Playlist.swift               # Playlist data model
│
├── ⚙️ Services (Business Logic)
│   ├── APIService.swift             # Backend API client
│   └── AudioPlayerManager.swift     # Audio playback manager
│
├── 🎨 Assets
│   └── Assets.xcassets/
│       ├── AppIcon.appiconset/      # App icons (all sizes)
│       └── AccentColor.colorset/    # App accent color
│
├── 🔧 Build Configuration
│   ├── build.sh                     # Build script for IPA
│   ├── project.yml                  # XcodeGen configuration
│   ├── ExportOptions.plist          # IPA export settings
│   ├── Makefile                     # Build automation
│   └── .gitignore                   # Git ignore rules
│
└── 📚 Documentation
    ├── README.md                    # Main documentation
    ├── INSTALLATION.md              # Installation guide
    └── PROJECT_OVERVIEW.md          # This file
```

## How It Works

### 1️⃣ User Opens App
- SwiftUI views render the interface
- APIService connects to backend server
- Library data is fetched and displayed

### 2️⃣ User Selects a Song
- Song metadata retrieved from backend
- AudioPlayerManager gets stream URL
- AVPlayer begins streaming audio

### 3️⃣ Music Plays
- Audio streams in real-time from backend
- Playback controls update UI
- Lock screen shows now playing info
- Background audio continues seamlessly

### 4️⃣ Navigation & Control
- Tab bar switches between views
- Search queries backend API
- Playlists load song lists
- Settings allow server configuration

## Backend API Endpoints Used

The iOS app communicates with these backend endpoints:

| Endpoint | Purpose | Response |
|----------|---------|----------|
| `GET /api/library/library` | Get music library | Array of songs |
| `GET /api/music/search?q=query` | Search music | Search results |
| `GET /api/music/stream/:id` | Stream audio | Audio file (mp3) |
| `GET /api/playlists` | Get all playlists | Array of playlists |
| `GET /api/playlists/:id/songs` | Get playlist songs | Array of songs |

## Installation Methods

### 🏪 For End Users: AltStore
1. Install AltStore on iOS device
2. Build or download IPA file
3. Install via AltStore
4. Configure server URL in app

### 👨‍💻 For Developers: Xcode
1. Open in Xcode
2. Connect iOS device
3. Build and run (⌘R)
4. Test with simulator or device

### 📦 Building IPA
```bash
cd "music app ios"
./build.sh
```
Output: `build/MusicStream.ipa`

## Configuration

### Server URL Setup
The app needs to know where your backend server is:

**Local Network (Same WiFi):**
```
http://192.168.1.100:3001
```

**Remote Access (Tunneled):**
```
https://your-tunnel-url.com
```

**Domain Name:**
```
https://music.yourdomain.com
```

Change this in: **App → Settings → Server URL**

## Technologies Used

### iOS Development
- **SwiftUI** - Modern declarative UI framework
- **AVFoundation** - Audio playback engine
- **Combine** - Reactive programming
- **URLSession** - Network requests
- **MediaPlayer** - System audio controls

### Build Tools
- **Xcode** - Apple's IDE
- **XcodeGen** - Project generation
- **xcodebuild** - Command-line build tool

### Languages
- **Swift 5.0** - Modern, safe iOS programming
- **JSON** - Data exchange format

## System Requirements

### For the iOS App
- iOS 15.0 or later
- iPhone or iPad
- AltStore (for installation)

### For Building
- macOS 12.0 or later
- Xcode 14 or later
- Command Line Tools

### For Backend
- Node.js server running
- Music files in library
- Network accessibility

## Network Requirements

### Local Network
- Both devices on same WiFi
- Backend server running on computer
- Port 3001 accessible (default)

### Remote Access
- Public IP or domain name
- Port forwarding configured
- Or use Cloudflare Tunnel/ngrok

## Security Considerations

⚠️ **Important Security Notes:**

1. **No Built-in Authentication**
   - Default setup has no login
   - Anyone with server URL can access
   - Consider adding authentication

2. **Network Security**
   - Use HTTPS for remote access
   - Consider VPN for secure connections
   - Don't expose server without protection

3. **AltStore Limitations**
   - Free Apple ID: Re-sign every 7 days
   - Paid Apple ID: Re-sign yearly
   - Or use proper App Store distribution

## Development Workflow

### Making Changes
1. Edit Swift files
2. Test in Simulator (⌘R in Xcode)
3. Test on device
4. Build IPA for distribution

### Adding Features
1. Create new View files
2. Update ContentView navigation
3. Add API calls in APIService
4. Test thoroughly

### Debugging
- Use Xcode console for logs
- Check backend server logs
- Use network debugging tools
- Test API endpoints directly

## Common Issues & Solutions

### ❌ "Cannot Connect to Server"
- ✅ Verify server is running
- ✅ Check IP address is correct
- ✅ Ensure firewall allows connections
- ✅ Test URL in Safari first

### ❌ "No Audio Playing"
- ✅ Check device volume
- ✅ Verify stream URL works
- ✅ Check backend has audio files
- ✅ Review backend logs

### ❌ Build Errors
- ✅ Update Xcode
- ✅ Clean build (⇧⌘K)
- ✅ Delete derived data
- ✅ Regenerate project

## Performance Optimization

The app is optimized for:
- ⚡ Fast UI rendering (SwiftUI)
- 🔋 Battery efficiency (background audio)
- 📡 Network efficiency (streaming)
- 💾 Memory management (image caching)

## Future Enhancements

Potential features to add:
- [ ] Offline caching
- [ ] Download management
- [ ] Lyrics display
- [ ] Equalizer settings
- [ ] AirPlay support
- [ ] CarPlay integration
- [ ] Widget support
- [ ] Siri integration
- [ ] Apple Watch app

## Testing Checklist

Before distribution, test:
- ✅ Search functionality
- ✅ Music playback
- ✅ Background audio
- ✅ Lock screen controls
- ✅ Playlist navigation
- ✅ Settings configuration
- ✅ Error handling
- ✅ Network interruption recovery

## Quick Start Commands

```bash
# Navigate to project
cd ~/Desktop/music\ app\ ios

# Build IPA
./build.sh

# Or use Make
make build

# Generate Xcode project
make generate

# Run in simulator
make simulator

# Clean build
make clean
```

## Support & Resources

### Documentation
- `README.md` - Comprehensive guide
- `INSTALLATION.md` - Step-by-step installation
- `PROJECT_OVERVIEW.md` - This file

### External Resources
- [AltStore](https://altstore.io/) - Sideloading tool
- [SwiftUI Docs](https://developer.apple.com/documentation/swiftui)
- [AVFoundation Guide](https://developer.apple.com/av-foundation/)

### Backend Server
- Located in: `~/Desktop/music_app/`
- Start with: `cd backend && npm start`
- Admin panel: `http://localhost:3001/admin.html`

## Summary

This iOS app provides a **native, beautiful interface** for your Music Stream backend. It connects to your existing `music_app` server and streams music directly to your iPhone or iPad.

**Key Benefits:**
- 📱 Native iOS experience
- 🎵 High-quality audio streaming
- 🔄 Real-time syncing with backend
- 🎨 Beautiful, modern interface
- 🔧 Easy to install and configure

**Ready to Install?**
See `INSTALLATION.md` for step-by-step instructions!

---

**Built with ❤️ for iOS | Powered by Music Stream Backend**

