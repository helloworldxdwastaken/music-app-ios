# Changelog

## Version 1.0 - Initial Release

### Features
- ✅ Native iOS app with SwiftUI
- ✅ Stream music from server
- ✅ Search functionality
- ✅ Browse music library
- ✅ View playlists (with auth)
- ✅ Background audio playback
- ✅ Lock screen controls
- ✅ Album artwork display
- ✅ Beautiful modern UI

### Integration
- ✅ Connected to music_app backend
- ✅ Supports all backend API endpoints:
  - `/api/library/library` - Browse library
  - `/api/library/search` - Search songs
  - `/api/library/stream/:id` - Stream audio
  - `/api/playlists` - View playlists
  - `/api/playlists/:id/tracks` - Playlist songs
  - `/api/auth/login` - Authentication

### Configuration
- ✅ Default server: `https://stream.noxamusic.com`
- ✅ Public server pre-configured
- ✅ No setup required for end users
- ✅ Optional custom server support
- ✅ Auth token storage for playlists

### Fixes & Improvements
- ✅ Fixed Song model (Int ID instead of String)
- ✅ Fixed Playlist model (track_count instead of song_count)
- ✅ Fixed API response parsing (plain arrays, not wrapped objects)
- ✅ Fixed playlist endpoints (uses /tracks not /songs)
- ✅ Added authentication support for playlists
- ✅ Graceful handling of 401 errors
- ✅ Better error messages with response logging
- ✅ HTTPS support for public server

### Build System
- ✅ Automated build script (build.sh)
- ✅ XcodeGen configuration
- ✅ Makefile for common tasks
- ✅ IPA export configuration
- ✅ AltStore ready

### Documentation
- ✅ Complete README.md
- ✅ Quick start guide (QUICK_START.md)
- ✅ Installation guide (INSTALLATION.md)
- ✅ Project overview (PROJECT_OVERVIEW.md)
- ✅ Setup completion guide (SETUP_COMPLETE.md)
- ✅ This changelog

### Known Limitations
- Playlists require authentication (future: add login UI)
- No offline playback (future feature)
- No downloads (future feature)
- No lyrics display (future feature)

---

## Roadmap

### Version 1.1 (Planned)
- [ ] Login screen for authentication
- [ ] User profile view
- [ ] Create/edit playlists in app
- [ ] Add songs to playlists
- [ ] Favorites/liked songs

### Version 1.2 (Planned)
- [ ] Download songs for offline playback
- [ ] Offline mode
- [ ] Download management
- [ ] Cache management

### Version 2.0 (Future)
- [ ] Lyrics display
- [ ] Equalizer
- [ ] Sleep timer
- [ ] AirPlay support
- [ ] CarPlay integration
- [ ] Widgets
- [ ] Siri integration
- [ ] Apple Watch companion app

---

**Current Version:** 1.0
**Last Updated:** November 2025

