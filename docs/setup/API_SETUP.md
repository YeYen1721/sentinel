# Sentinel API Setup Guide

The Sentinel app now supports **real weather data and AI-powered action plans**! Follow these steps to enable the full functionality.

## Current Status

- ✅ **Basic functionality works without any API keys** (uses mock data)
- ✅ **Free weather data from NOAA** (US locations only, no key required)
- ⚙️ **Enhanced weather data** requires OpenWeather API key (optional)
- ⚙️ **AI-generated action plans** require Google Gemini API key (optional)

## Quick Start (No API Keys)

The app will automatically use:
1. **NOAA Weather API** for real weather forecasts (US only, free, no key required)
2. **Mock data** for action plans

## Step 1: Add New Files to Xcode (REQUIRED)

The new API integration files need to be added to your Xcode project:

1. Open `Sentinel.xcodeproj` in Xcode
2. In the left sidebar (Project Navigator), find the **"Core"** folder
3. **Add APIConfiguration.swift:**
   - Right-click on **"Core/Utilities"** folder
   - Select **"Add Files to Sentinel..."**
   - Navigate to: `Sentinel/Core/Utilities/APIConfiguration.swift`
   - Make sure **"Copy items if needed"** is UNCHECKED
   - Make sure **"Sentinel"** target is CHECKED
   - Click **"Add"**

4. **Add RealRiskDataService.swift:**
   - Right-click on **"Core/Services"** folder
   - Select **"Add Files to Sentinel..."**
   - Navigate to: `Sentinel/Core/Services/RealRiskDataService.swift`
   - Make sure **"Copy items if needed"** is UNCHECKED
   - Make sure **"Sentinel"** target is CHECKED
   - Click **"Add"**

5. **Verify the files were added:**
   - Look for the files in the Project Navigator
   - They should appear in their respective folders
   - Build the project (`Cmd + B`) to ensure no errors

## Step 2: Get OpenWeather API Key (Optional - Enhanced Weather Data)

**Free tier: 1,000 calls/day**

1. Go to [https://openweathermap.org/api](https://openweathermap.org/api)
2. Click **"Sign Up"** (top right)
3. Create a free account
4. After signing in, go to **"API keys"** tab
5. Copy your API key from OpenWeather.

**Add to your app:**
1. Add `OPENWEATHER_API_KEY` to your local Xcode scheme environment variables.
2. Keep real API keys out of committed source files.

## Step 3: Get Google Gemini API Key (Optional - AI Action Plans)

**Free tier: 60 requests/minute**

1. Go to [https://makersuite.google.com/app/apikey](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click **"Create API Key"**
4. Select **"Create API key in new project"** or choose existing project
5. Copy your API key from Google AI Studio.

**Add to your app:**
1. Add `GEMINI_API_KEY` to your local Xcode scheme environment variables.
2. Keep real API keys out of committed source files.

## Step 4: Build and Run

1. Build the project: `Cmd + B`
2. Run on simulator or device: `Cmd + R`

**Check the console logs:**
- ✅ `"Using real weather APIs"` = Real data is working!
- ℹ️ `"Using mock data"` = No API keys configured (app still works with limited data)

## Testing Real vs Mock Data

### Without API Keys:
- Weather forecasts: Real data from NOAA (US only)
- Historical events: Generated based on location
- Action plans: Mock/demo tasks

### With OpenWeather Key:
- Weather forecasts: Enhanced global data with hourly forecasts
- Better international coverage
- More accurate precipitation and wind data

### With Gemini Key:
- Action plans: AI-generated, personalized recommendations
- Intelligent task prioritization based on your specific property
- Dynamic descriptions based on real hazard data

## API Usage Limits

| API | Free Tier | Cost After Limit |
|-----|-----------|------------------|
| NOAA Weather | Unlimited | Always free |
| OpenWeather | 1,000 calls/day | $0.0015/call |
| Google Gemini | 60 requests/min | Free (currently in beta) |

## Troubleshooting

### "Using mock data" in console
- Check that you added API keys to `APIConfiguration.swift`
- Make sure you're replacing the `return ""` line, not adding a new line
- Rebuild the app after changing the file

### "API request failed"
- Check your internet connection
- Verify API key is correct (no extra spaces)
- For OpenWeather: Wait 10 minutes after creating key (activation delay)
- For Gemini: Check quota limits (60/min)

### Files not found in Xcode
- Make sure you followed Step 1 to add files to Xcode
- Check that files are in the correct folders
- Try cleaning build folder: `Cmd + Shift + K`, then rebuild

## Security Note

**⚠️ Never commit API keys to version control!**

For production apps:
- Use environment variables
- Store keys in Keychain
- Use backend API proxy to hide keys from client

For this demo app, hardcoding in `APIConfiguration.swift` is acceptable for learning purposes.

## What Data Is Real?

| Feature | Data Source | API Required |
|---------|-------------|--------------|
| HVS Score | Calculated locally | None |
| Weather Forecasts | NOAA (US) or OpenWeather (global) | Optional |
| Historical Events | Generated from location | None |
| Risk Scores | Calculated from forecasts + location | Optional |
| Action Plans | Gemini AI or mock | Optional |
| Task Storage | Firebase Firestore | Configured |

---

**Questions?** Check the console output when the app launches - it will tell you which services are active!
