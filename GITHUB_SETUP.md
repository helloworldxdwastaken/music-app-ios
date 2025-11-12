# GitHub Actions Setup Guide - Build iOS App Automatically 🚀

## Why Use GitHub Actions?

- ✅ **You're on Linux** - Can't run Xcode locally
- ✅ **100% Free** - GitHub provides free macOS runners
- ✅ **Automatic** - Push code, get IPA automatically
- ✅ **No Mac needed** - Everything builds in the cloud

---

## Quick Setup (5 Minutes)

### Step 1: Create GitHub Repository

1. Go to https://github.com
2. Click **New repository** (green button)
3. Repository name: `music-stream-ios`
4. Choose **Public** (for unlimited free builds) or **Private**
5. **DON'T** initialize with README (we already have files)
6. Click **Create repository**

### Step 2: Push Your Code to GitHub

```bash
# Navigate to your project
cd ~/Desktop/music\ app\ ios

# Initialize git
git init

# Add all files
git add .

# Commit files
git commit -m "Initial commit - Music Stream iOS App"

# Add your GitHub repo (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/music-stream-ios.git

# Push to GitHub
git branch -M main
git push -u origin main
```

**That's it!** GitHub Actions will automatically start building your app! 🎉

### Step 3: Watch the Build

1. Go to your GitHub repo: `https://github.com/YOUR_USERNAME/music-stream-ios`
2. Click the **Actions** tab at the top
3. You'll see "Build iOS App" workflow running
4. Wait 5-10 minutes for it to complete

### Step 4: Download Your IPA

Once the build is complete (green checkmark):

1. Click on the completed workflow run
2. Scroll down to **Artifacts** section
3. Click **MusicStream-IPA** to download (it's a .zip file)
4. Extract the zip
5. Inside you'll find `MusicStream.ipa`
6. Install via AltStore! 🎵

---

## Detailed Walkthrough

### Understanding the Workflow

The file `.github/workflows/build-ios.yml` contains:

```yaml
name: Build iOS App

on:
  push:                    # Triggers on git push
    branches: [ main ]
  workflow_dispatch:       # Allows manual trigger

jobs:
  build:
    runs-on: macos-latest  # Uses GitHub's free Mac
    
    steps:
      - Checkout code
      - Install Xcode
      - Install XcodeGen
      - Generate Xcode project
      - Build app archive
      - Export IPA
      - Upload as artifact ✨
```

### What Happens When You Push?

1. **Trigger**: GitHub detects your push
2. **Allocate**: GitHub allocates a free macOS machine
3. **Setup**: Installs Xcode, XcodeGen, dependencies
4. **Generate**: Creates Xcode project from project.yml
5. **Build**: Compiles all Swift files
6. **Archive**: Creates app archive
7. **Export**: Generates IPA file
8. **Upload**: Stores IPA for download
9. **Cleanup**: Deletes the macOS machine

**Total time**: 5-10 minutes  
**Cost**: $0 (Free!)

---

## Manual Build Trigger

You can also trigger builds manually without pushing code:

1. Go to GitHub repo → **Actions** tab
2. Click **Build iOS App** on the left
3. Click **Run workflow** button (right side)
4. Select branch: `main`
5. Click green **Run workflow** button

Perfect for testing!

---

## Viewing Build Logs

To see what's happening:

1. Go to **Actions** tab
2. Click on the running/completed workflow
3. Click on the **Build IPA** job
4. Expand any step to see detailed logs

Useful for debugging if something goes wrong!

---

## Cost & Limits

### Public Repositories
- ✅ **Unlimited minutes** - Completely free!
- ✅ Unlimited builds
- ✅ Best option for this project

### Private Repositories
- ✅ **2,000 minutes/month** free
- Each build: ~5-10 minutes
- **~200-400 builds per month** for free
- After limit: $0.08 per minute

**Recommendation**: Use a **public repository** for unlimited free builds!

---

## Troubleshooting

### Build Fails with "Command not found: xcodegen"

**Solution**: Already handled in workflow - it installs xcodegen automatically.

### Build Fails with Code Signing Error

**Solution**: Already handled - workflow disables code signing for AltStore builds.

### No Artifact Appears

**Cause**: Build failed before IPA was created  
**Solution**: Check the logs in the workflow run

### Workflow Doesn't Start

**Check**:
1. Is the file at `.github/workflows/build-ios.yml`?
2. Did you push to `main` or `master` branch?
3. Are Actions enabled? (Settings → Actions → Allow all actions)

---

## Advanced: Build on Tags Only

To build only when you create version tags (v1.0, v2.0, etc.):

Edit `.github/workflows/build-ios.yml`:

```yaml
on:
  push:
    tags:
      - 'v*'  # Only build on version tags
  workflow_dispatch:  # Keep manual trigger
```

Then create a tag:

```bash
git tag v1.0
git push origin v1.0
```

---

## Advanced: Build Status Badge

Add a build status badge to your README:

```markdown
![Build Status](https://github.com/YOUR_USERNAME/music-stream-ios/workflows/Build%20iOS%20App/badge.svg)
```

Shows: ✅ passing | ❌ failing

---

## Files Created for GitHub Actions

```
music app ios/
└── .github/
    └── workflows/
        ├── build-ios.yml      # Main workflow file
        └── README.md          # Workflow documentation
```

These are automatically detected by GitHub!

---

## Complete Example

```bash
# 1. Setup
cd ~/Desktop/music\ app\ ios
git init
git add .
git commit -m "Initial commit"

# 2. Connect to GitHub
git remote add origin https://github.com/YOUR_USERNAME/music-stream-ios.git
git push -u origin main

# 3. Wait 5-10 minutes

# 4. Download IPA from Actions → Artifacts

# 5. Install via AltStore

# 6. Enjoy! 🎵
```

---

## Updating the App

When you make changes:

```bash
# Make your changes to Swift files

# Commit changes
git add .
git commit -m "Updated HomeView UI"

# Push to GitHub
git push

# New build starts automatically!
# Check Actions tab for new IPA
```

---

## Alternative: GitLab CI/CD

If you prefer GitLab, they also offer free macOS runners:

```yaml
# .gitlab-ci.yml
build-ios:
  stage: build
  tags:
    - saas-macos-medium-m1
  script:
    - brew install xcodegen
    - xcodegen generate
    - xcodebuild archive ...
  artifacts:
    paths:
      - build/*.ipa
```

But GitHub is simpler for this use case!

---

## Security Notes

### Code Signing
- Workflow builds **without code signing**
- Perfect for AltStore (doesn't need signing)
- For App Store, you'd need to add certificates as secrets

### Secrets (Not Needed for This App)
If you later need authentication:
1. Go to repo Settings → Secrets
2. Add `APPLE_ID`, `APPLE_PASSWORD`, etc.
3. Reference in workflow: `${{ secrets.APPLE_ID }}`

But for AltStore, no secrets needed! ✅

---

## Benefits Summary

✅ **No Mac required** - Build from Linux  
✅ **Completely free** - Public repo = unlimited  
✅ **Automatic** - Push code, get IPA  
✅ **Fast** - 5-10 minutes per build  
✅ **Reliable** - GitHub's infrastructure  
✅ **Simple** - Just push to GitHub  
✅ **Portable** - Download IPA anywhere  

---

## Quick Commands Reference

```bash
# First time setup
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/USER/REPO.git
git push -u origin main

# Make changes
git add .
git commit -m "Description of changes"
git push

# Create version tag
git tag v1.0
git push origin v1.0

# View git status
git status

# View remote
git remote -v
```

---

## Next Steps After Setup

1. ✅ Push code to GitHub (automatic build)
2. ⏱️ Wait 5-10 minutes
3. 📥 Download IPA from Artifacts
4. 📱 Install via AltStore
5. 🎵 Test the app
6. 🔄 Make changes and push again for new builds

---

## FAQ

**Q: Do I need a Mac at all?**  
A: Nope! GitHub provides the Mac for you.

**Q: How long does a build take?**  
A: Typically 5-10 minutes. First build might take longer.

**Q: Can I build for App Store this way?**  
A: Yes, but you'd need to add code signing certificates as secrets.

**Q: What if I exceed free minutes?**  
A: Use a public repo for unlimited minutes, or pay $0.08/min after 2,000.

**Q: Can I see the build progress?**  
A: Yes! Go to Actions tab and click on the running workflow.

**Q: Where is the IPA stored?**  
A: In the Artifacts section of each workflow run, kept for 90 days.

**Q: Can I download old builds?**  
A: Yes, artifacts are kept for 90 days (configurable).

---

## Summary

**Setup Time**: 5 minutes  
**Build Time**: 5-10 minutes  
**Cost**: $0 (free!)  
**Difficulty**: Easy ⭐⭐☆☆☆

Just push your code to GitHub and let it build automatically! 🚀

---

**Ready to start?**

```bash
cd ~/Desktop/music\ app\ ios
git init
git add .
git commit -m "Initial commit - Music Stream iOS"
# Create repo on GitHub, then:
git remote add origin https://github.com/YOUR_USERNAME/music-stream-ios.git
git push -u origin main
```

Then visit your repo's **Actions** tab and watch the magic happen! ✨

