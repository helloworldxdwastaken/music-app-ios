# Quick Start Guide - Music Stream iOS App 🚀

## For End Users (Ready to Use!)

### ✅ Good News!
The app is pre-configured to work with the public server at:
**`https://stream.noxamusic.com`**

No configuration needed - just install and play! 🎵

---

## Installation Steps

### Step 1: Get AltStore
1. Download **AltStore** from: https://altstore.io/
2. Follow their instructions to install on your iPhone/iPad
3. Make sure AltStore is running and paired with your computer

### Step 2: Install Music Stream App
1. Download the **MusicStream.ipa** file (from the `build` folder)
2. Open **AltStore** on your iOS device
3. Tap the **+** button in AltStore
4. Select **MusicStream.ipa**
5. Wait for installation (~30 seconds)

### Step 3: Open and Enjoy!
1. Find **Music Stream** on your home screen
2. Open the app
3. Start browsing and streaming music! 🎵

That's it! The app will connect to `https://stream.noxamusic.com` automatically.

---

## Optional: Using a Different Server

If you want to use your own local server instead:

1. Open the **Music Stream** app
2. Go to **Settings** tab (bottom right)
3. Tap **Server URL**
4. Enter your server URL (e.g., `http://192.168.1.100:3001`)
5. Tap **Test Connection**
6. If successful, go back and browse your music!

---

## AltStore Important Notes

### Free Apple ID (No Developer Account)
- ✅ Install up to 3 apps
- ⚠️ Apps expire after **7 days**
- 🔄 Need to refresh weekly in AltStore
- 💰 Free!

### Paid Apple Developer Account ($99/year)
- ✅ Install more apps
- ✅ Apps last **1 year** before needing refresh
- 💰 $99/year

### Refreshing Your App
When your app expires:
1. Open AltStore on your device
2. Go to "My Apps" tab
3. Tap the refresh icon next to Music Stream
4. Wait for it to re-sign
5. Done! Another 7 days (or 1 year)

---

## Features

### 🎵 What You Can Do
- Stream unlimited music
- Search for songs and artists
- Browse complete music library
- View playlists (requires login)
- Background playback
- Lock screen controls
- Beautiful album artwork

### 📱 App Features
- Native iOS interface
- Dark mode support
- iPhone & iPad compatible
- Smooth animations
- Offline-friendly UI

---

## Troubleshooting

### "Cannot Connect to Server"
**Solution:** Check your internet connection. The app needs internet to stream from `stream.noxamusic.com`.

### "No Music Showing"
**Solution:** 
1. Go to Settings → Server URL
2. Tap "Test Connection"
3. If it says "Failed", check your internet
4. Try closing and reopening the app

### "Audio Not Playing"
**Solution:**
1. Check device volume (not muted)
2. Check silent switch on side of iPhone
3. Try a different song
4. Close and reopen the app

### "App Keeps Crashing"
**Solution:**
1. Delete the app
2. Reinstall via AltStore
3. Restart your device

### "App Expired" / "Unable to Verify"
**Solution:**
1. Open AltStore
2. Refresh the app
3. This happens every 7 days with free Apple ID

---

## FAQ

**Q: Do I need to pay for anything?**
A: No! The app is free. AltStore is free. The music server is free.

**Q: Can I use this without WiFi?**
A: You need internet connection to stream music from the server.

**Q: How do I see playlists?**
A: Playlists require login. Use the web admin panel to create an account, then add login to the app in Settings.

**Q: Can I download music?**
A: Currently, the app streams only. Downloads coming in future version!

**Q: Is this legal?**
A: This app streams from a personal music server. Make sure you have rights to the music on the server.

**Q: Will this work on iPad?**
A: Yes! The app is universal - works on iPhone and iPad.

**Q: Can I use with CarPlay?**
A: Not yet, but it's on the roadmap!

---

## Building from Source (For Developers)

If you want to build the IPA yourself:

```bash
cd ~/Desktop/music\ app\ ios
./build.sh
```

The IPA will be in the `build` folder.

---

## Need Help?

1. Check the [full README](README.md) for detailed docs
2. Check [INSTALLATION.md](INSTALLATION.md) for troubleshooting
3. Test the server in your browser: https://stream.noxamusic.com

---

## Public Server Info

**Default Server:** `https://stream.noxamusic.com`

- ✅ Public access
- ✅ HTTPS secure
- ✅ No configuration needed
- ✅ Fast streaming
- ✅ Reliable uptime

You can browse the web interface at: https://stream.noxamusic.com

---

**Enjoy Your Music! 🎵🎉**

Made with ❤️ for music lovers

