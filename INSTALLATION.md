# Quick Installation Guide for Music Stream iOS App 📱

## For End Users (Using AltStore)

### Step 1: Check Internet Connection

**Good News!** The app now works with a public server by default:
- Default URL: `https://stream.noxamusic.com`
- No local server setup needed!
- Just need internet connection

**Skip to Step 2** if you want to use the public server (recommended for most users).

**Using Your Own Local Server? (Advanced)**
1. Make sure your Music Stream backend is running:
   ```bash
   cd ~/Desktop/music_app/backend
   npm start
   ```

2. Find your computer's local IP address:
   - **macOS/Linux:** Open Terminal and run `ifconfig | grep "inet " | grep -v 127.0.0.1`
   - **Windows:** Open Command Prompt and run `ipconfig`
   - Look for something like `192.168.1.100`

### Step 2: Install AltStore

1. Download AltStore from: https://altstore.io/
2. Install AltStore on your iPhone/iPad
3. Follow the setup instructions to pair with your computer

### Step 3: Install the Music Stream App

**Option A: Pre-built IPA (If Available)**
1. Download the `MusicStream.ipa` file from the `build` folder
2. Open AltStore on your iOS device
3. Tap the "+" button in the top-left corner
4. Select "MusicStream.ipa"
5. Wait for installation to complete

**Option B: Build It Yourself (Requires macOS with Xcode)**
1. Open Terminal and navigate to the project:
   ```bash
   cd ~/Desktop/music\ app\ ios
   ```
2. Run the build script:
   ```bash
   ./build.sh
   ```
3. The IPA will be created in the `build` folder
4. Transfer it to your iOS device and install via AltStore

### Step 4: Open and Enjoy!

1. Open the Music Stream app on your iOS device
2. The app is pre-configured to use `https://stream.noxamusic.com`
3. Go to Home tab and start streaming! 🎵

**That's it!** No configuration needed.

**Optional - Using Your Own Server:**
If you want to use your own local server:
1. Go to the **Settings** tab
2. Tap on **Server URL**
3. Enter your backend server URL:
   - Local WiFi: `http://YOUR_COMPUTER_IP:3001`
   - Example: `http://192.168.1.100:3001`
4. Tap **Test Connection** to verify
5. If successful, go back to Home and start streaming! 🎵

## For Developers

### Setting Up Development Environment

1. **Install Xcode:**
   - Download from Mac App Store
   - Install Command Line Tools: `xcode-select --install`

2. **Install XcodeGen (Optional but Recommended):**
   ```bash
   brew install xcodegen
   ```

3. **Open Project in Xcode:**
   ```bash
   cd ~/Desktop/music\ app\ ios
   xcodegen generate  # Generate .xcodeproj file
   open MusicStream.xcodeproj
   ```

4. **Run on Simulator:**
   - Select a device simulator in Xcode
   - Press ⌘R to build and run
   - The simulator can connect to `http://localhost:3001`

5. **Run on Physical Device:**
   - Connect your iPhone/iPad via USB
   - Select your device in Xcode
   - Press ⌘R to build and run
   - Use your computer's local IP in Settings

### Building IPA for Distribution

```bash
# Simple method
./build.sh

# Manual method
xcodegen generate
xcodebuild archive -project MusicStream.xcodeproj -scheme MusicStream -archivePath build/MusicStream.xcarchive
xcodebuild -exportArchive -archivePath build/MusicStream.xcarchive -exportPath build -exportOptionsPlist ExportOptions.plist
```

## Troubleshooting

### "Unable to Connect to Server"

**Solution 1: Check Server Status**
- Ensure backend is running: `cd ~/Desktop/music_app/backend && npm start`
- Check for errors in the backend console

**Solution 2: Verify IP Address**
- Make sure you're using the correct IP address
- Both devices must be on the same WiFi network
- Try pinging: `ping YOUR_COMPUTER_IP`

**Solution 3: Check Firewall**
- macOS: System Preferences → Security & Privacy → Firewall
- Allow incoming connections for Node.js
- Or temporarily disable firewall to test

**Solution 4: Port Forwarding**
- Ensure port 3001 is not blocked
- Try accessing in Safari: `http://YOUR_IP:3001`

### "Certificate Expired" (AltStore)

- AltStore certificates expire after 7 days for free Apple IDs
- Refresh the app weekly through AltStore
- Or use a paid Apple Developer account (1-year certificates)

### "No Audio Playing"

1. Check device volume and mute switch
2. Verify audio files exist on backend server
3. Test streaming URL in browser
4. Check backend logs for errors

### Build Errors

**"Signing for MusicStream requires a development team"**
- Add your Team ID in `project.yml`
- Or select your team in Xcode: Target → Signing & Capabilities

**"Command line tools not found"**
```bash
xcode-select --install
```

**"XcodeGen not found"**
```bash
brew install xcodegen
```

## Remote Access (Advanced)

To access your music server from anywhere:

### Option 1: Cloudflare Tunnel
```bash
# Install cloudflared
brew install cloudflare/cloudflare/cloudflared

# Create tunnel
cloudflared tunnel --url http://localhost:3001
```
Use the provided HTTPS URL in app settings.

### Option 2: ngrok
```bash
# Install ngrok
brew install ngrok

# Start tunnel
ngrok http 3001
```
Use the provided HTTPS URL in app settings.

### Option 3: Port Forwarding
1. Configure your router to forward port 3001
2. Use your public IP address
3. Use dynamic DNS for consistent access

## Security Considerations

- Default setup has no authentication
- Use HTTPS for remote access
- Consider VPN for secure connections
- Don't expose your server publicly without security

## Tips for Best Experience

1. **Keep Backend Running:**
   - Use `pm2` or `screen` to keep backend running 24/7
   - Or use a dedicated server/Raspberry Pi

2. **Organize Your Library:**
   - Use the admin panel to manage music
   - Create playlists for easy access
   - Add album artwork for better visuals

3. **Network Performance:**
   - Use 5GHz WiFi for better streaming
   - Ensure strong signal on both devices
   - Consider audio quality settings for mobile data

4. **Battery Life:**
   - Background audio is optimized
   - But streaming uses data/battery
   - Download music to backend for local playback

## Getting Help

- Check README.md for detailed documentation
- Review backend server logs
- Test API endpoints with curl/Postman
- Verify network connectivity

## Quick Commands Reference

```bash
# Start backend server
cd ~/Desktop/music_app/backend && npm start

# Build iOS app
cd ~/Desktop/music\ app\ ios && ./build.sh

# Find local IP
ifconfig | grep "inet " | grep -v 127.0.0.1

# Test server from terminal
curl http://localhost:3001/api/library/library?limit=1

# Generate Xcode project
xcodegen generate

# Clean build
rm -rf build ~/Library/Developer/Xcode/DerivedData
```

---

**Need More Help?**
- Backend Issues: Check `music_app/backend` logs
- iOS Issues: Check Xcode console
- Network Issues: Verify firewall and connectivity

**Enjoy your music! 🎵🎉**

