# 🔧 Fix Build Errors - Step by Step Guide

## Current Errors & Solutions

### ❌ Error 1: "No such module 'FirebaseAuth'"
**Cause**: Firebase SDK packages haven't been added to the Xcode project
**Solution**: Add Firebase via Swift Package Manager

### ❌ Error 2: Duplicate output files
**Cause**: Nested duplicate folder
**Solution**: ✅ Already fixed - removed duplicate Sentinel/Sentinel folder

---

## 🚀 Complete Fix Instructions

### Step 1: Add Firebase Packages to Xcode

1. **Open the project** in Xcode:
   ```bash
   open /Users/minwook/Sentinel/Sentinel.xcodeproj
   ```

2. **Add Firebase Package**:
   - In Xcode menu: `File` → `Add Package Dependencies...`
   - In the search box, paste: `https://github.com/firebase/firebase-ios-sdk`
   - Click "Add Package"
   - Select version: `10.29.0` (or latest 10.x.x version)
   - Click "Add Package" again

3. **Select Firebase Products**:
   When the product selection dialog appears, check these boxes for the **Sentinel** target:
   - ✅ `FirebaseAuth`
   - ✅ `FirebaseCore`
   - ✅ `FirebaseFirestore`

   Then click "Add Package"

4. **Wait for package resolution** (may take 1-2 minutes)

### Step 2: Verify Package Installation

1. In Xcode's Project Navigator (left sidebar)
2. Click on the **Sentinel** project (blue icon at the top)
3. Select the **Sentinel** target
4. Go to **General** tab
5. Scroll down to "Frameworks, Libraries, and Embedded Content"
6. You should see:
   - `FirebaseAuth`
   - `FirebaseCore`
   - `FirebaseFirestore`

### Step 3: Clean and Rebuild

1. Clean the build folder:
   - Menu: `Product` → `Clean Build Folder` (or press `⇧⌘K`)

2. Rebuild the project:
   - Menu: `Product` → `Build` (or press `⌘B`)

### Step 4: Fix Any Remaining Import Issues

If you still see errors after adding packages:

1. **Check deployment target**:
   - Project settings → General → Minimum Deployments → iOS `17.0`

2. **Verify GoogleService-Info.plist**:
   - Make sure it's in the project navigator
   - Right-click → Show File Inspector
   - Check "Target Membership" → ✅ Sentinel

3. **Restart Xcode**:
   - Sometimes Xcode needs a restart after adding packages
   - `Xcode` → `Quit Xcode` (⌘Q)
   - Reopen the project

---

## 🎯 Alternative: Manual Package Addition via Project File

If the UI method doesn't work, you can add packages manually:

1. Close Xcode

2. Edit the project file to add package dependencies:
   ```bash
   # This would require editing the .pbxproj file directly
   # NOT RECOMMENDED - use Xcode UI instead
   ```

---

## 🔍 Verify Everything Works

After adding Firebase packages, run these checks:

### ✅ Checklist:

1. [ ] No red errors in the Issues navigator
2. [ ] `import FirebaseAuth` shows no error in ContentView.swift
3. [ ] `import FirebaseCore` shows no error in SentinelApp.swift
4. [ ] `import FirebaseFirestore` shows no error in TaskRepository.swift
5. [ ] Build succeeds (⌘B shows "Build Succeeded")

### 🧪 Test Build:

```
1. Select a simulator (iPhone 15 Pro recommended)
2. Press ⌘R to build and run
3. You should see the Sentinel loading screen
4. Then the onboarding flow
```

---

## 🐛 Common Issues & Solutions

### Issue: "Failed to resolve dependencies"
**Solution**:
- Check internet connection
- Try different Firebase version (10.28.0 or 10.27.0)
- In Xcode: `File` → `Packages` → `Reset Package Caches`

### Issue: "Package.resolved file is corrupted"
**Solution**:
```bash
cd /Users/minwook/Sentinel/Sentinel.xcodeproj
rm -rf project.xcworkspace/xcshareddata/swiftpm
```
Then re-add packages in Xcode

### Issue: Build succeeds but app crashes on launch
**Solution**:
- Check Console for error message
- Verify `GoogleService-Info.plist` is properly configured
- Make sure it's added to the target (not just the folder)

### Issue: "Command PhaseScriptExecution failed"
**Solution**:
- This is often a code signing issue
- Go to Signing & Capabilities tab
- Select your development team
- Or check "Automatically manage signing"

---

## 📦 What the Packages Do

- **FirebaseCore**: Core Firebase SDK, required for all Firebase features
- **FirebaseAuth**: Handles user authentication (anonymous + custom tokens)
- **FirebaseFirestore**: NoSQL database for storing tasks and property profiles

---

## 🎉 Expected Result

After following these steps, you should see:

```
✅ Build Succeeded
✅ 0 Errors
✅ 0 Warnings (or minimal warnings)
✅ App launches successfully
✅ Onboarding screen appears
```

---

## 🆘 Still Having Issues?

If you're still seeing errors after following all steps:

1. **Share the exact error message** from Xcode
2. **Check Firebase setup**:
   - Did you replace the placeholder GoogleService-Info.plist?
   - Is your bundle ID correct?
3. **Xcode version**: Ensure you're using Xcode 15.0+
4. **macOS version**: Ensure macOS 14.0+ (Sonoma or later)

---

## 📝 Quick Command Reference

```bash
# Open project in Xcode
open /Users/minwook/Sentinel/Sentinel.xcodeproj

# Clean build folder (when Xcode is closed)
rm -rf /Users/minwook/Sentinel/Sentinel.xcodeproj/project.xcworkspace/xcshareddata

# View current Swift files
find /Users/minwook/Sentinel/Sentinel -name "*.swift" | wc -l

# Check if Firebase is imported correctly
grep -r "import Firebase" /Users/minwook/Sentinel/Sentinel
```

---

## ✨ Next Steps After Build Succeeds

1. Run the app (⌘R)
2. Complete onboarding
3. Test all 4 tabs (Dashboard, Tasks, History, Profile)
4. Try generating an action plan
5. Create and edit tasks
6. Explore the UI animations

The app is fully functional with mock data - no external APIs needed for testing!
