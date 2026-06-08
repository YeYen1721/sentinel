# API Integration Recommendations for Sentinel

## ✅ Currently Integrated

### 1. **OpenWeather API** (Implemented)
- **Purpose:** Real-time weather forecasts and alerts
- **Cost:** Free tier: 1,000 calls/day
- **Data:** Temperature, precipitation, wind, severe weather alerts
- **Status:** ✅ Working

### 2. **Google Gemini AI** (Implemented)
- **Purpose:** Personalized risk analysis and task generation
- **Cost:** Free tier: 60 requests/minute
- **Model:** gemini-2.0-flash
- **Status:** ✅ Working

### 3. **Attom Data API** (Just Added)
- **Purpose:** Real property details (year built, square footage, etc.)
- **Cost:** Free tier: 1,000 calls/month
- **Signup:** https://api.developer.attomdata.com/signup
- **Status:** 🔧 Ready to configure (need API key)

---

## 🌟 Highly Recommended APIs

### 4. **FEMA Flood Map Service API** (FREE)
**Why:** Essential for accurate flood risk assessment
- **URL:** https://hazards.fema.gov/gis/nfhl/rest/services
- **Cost:** FREE, no key required
- **Data:**
  - Flood zones (A, AE, X, etc.)
  - Base Flood Elevation (BFE)
  - Floodway boundaries
  - Historical flood data
- **Implementation Priority:** HIGH
- **Integration Effort:** Low (REST API)

**Example Use:**
```swift
// Check if property is in flood zone
let floodZone = FEMAService.getFloodZone(lat: 32.06, lon: -81.10)
// Returns: "AE" (high risk) or "X" (low risk)
```

### 5. **USGS Earthquake Hazards API** (FREE)
**Why:** Real earthquake risk and historical data
- **URL:** https://earthquake.usgs.gov/fdsnws/event/1/
- **Cost:** FREE, no key required
- **Data:**
  - Recent earthquakes (last 30 days)
  - Historical earthquake data
  - Seismic hazard maps
  - Ground motion probabilities
- **Implementation Priority:** MEDIUM
- **Integration Effort:** Low

### 6. **NASA FIRMS (Fire Information)** (FREE with registration)
**Why:** Real-time wildfire detection and risk
- **URL:** https://firms.modaps.eosdis.nasa.gov/api/
- **Cost:** FREE with NASA Earthdata account
- **Data:**
  - Active fire locations (from satellites)
  - Fire radiative power
  - Confidence levels
  - 24-hour updates
- **Implementation Priority:** HIGH (for western US)
- **Integration Effort:** Medium

### 7. **Storm Prediction Center API** (FREE)
**Why:** Tornado and severe weather outlooks
- **URL:** https://www.spc.noaa.gov/products/
- **Cost:** FREE, no key required
- **Data:**
  - Tornado probability maps
  - Severe weather outlooks (1-8 days)
  - Convective outlooks
  - Hail risk predictions
- **Implementation Priority:** HIGH
- **Integration Effort:** Medium (scraping required)

---

## 💡 Nice-to-Have APIs

### 8. **AirNow API** (FREE with key)
**Why:** Air quality and smoke from wildfires
- **URL:** https://www.airnow.gov/international/us-embassies-and-consulates/#API
- **Cost:** FREE with API key
- **Data:** AQI, PM2.5, ozone, smoke advisories
- **Priority:** MEDIUM

### 9. **CoreLogic HazardHQ** (PAID - $$$)
**Why:** Professional-grade hazard data
- **Cost:** Enterprise pricing (~$500+/month)
- **Data:** Comprehensive hazard scores, claims history
- **Priority:** LOW (expensive, for enterprise version)

### 10. **Zillow API** (Discontinued for new users ⚠️)
**Why:** Property details, home values
- **Status:** No longer accepting new API applications
- **Alternative:** Use Attom Data instead
- **Priority:** N/A

### 11. **Google Places API** (FREE tier available)
**Why:** Address autocomplete and validation
- **Cost:** Free tier: $200 credit/month (~28,000 autocomplete requests)
- **Data:** Address suggestions, geocoding, place details
- **Priority:** LOW (we already have CoreLocation for geocoding)

### 12. **Census Bureau API** (FREE)
**Why:** Neighborhood demographics and socioeconomic data
- **URL:** https://www.census.gov/data/developers/data-sets.html
- **Data:** Population density, income levels, housing stats
- **Priority:** LOW (future enhancement)

---

## 🎯 Recommended Implementation Order

### Phase 1: Critical Safety Data (Implement Now)
1. ✅ **Attom Data API** - Already added (need API key)
2. **FEMA Flood Map API** - FREE, critical for flood risk
3. **NASA FIRMS** - FREE, critical for wildfire risk

### Phase 2: Enhanced Weather Intelligence
4. **Storm Prediction Center** - FREE, improves tornado forecasts
5. **USGS Earthquake API** - FREE, adds earthquake risk

### Phase 3: Nice-to-Have
6. **AirNow API** - Adds air quality monitoring
7. **Census Bureau** - Neighborhood risk factors

---

## 📊 Estimated Monthly Costs

With recommended free APIs:
- **Attom Data:** FREE (1,000 calls/month)
- **OpenWeather:** FREE (1,000 calls/day)
- **Gemini AI:** FREE (60 req/min)
- **FEMA Flood Maps:** FREE
- **NASA FIRMS:** FREE
- **USGS Earthquake:** FREE
- **Storm Prediction Center:** FREE

**Total Monthly Cost: $0** 🎉

---

## 🚀 Next Steps

1. **Sign up for Attom Data API**
   - Go to: https://api.developer.attomdata.com/signup
   - Get free API key (1,000 calls/month)
   - Add to `APIConfiguration.swift`

2. **Integrate FEMA Flood Map API**
   - No signup required
   - Add `FEMAFloodService.swift`
   - Update risk calculations with flood zone data

3. **Add NASA FIRMS**
   - Sign up for NASA Earthdata account: https://urs.earthdata.nasa.gov/
   - Get API token
   - Add wildfire detection

4. **Test with real addresses**
   - Verify all APIs return accurate data
   - Handle API failures gracefully
   - Show users which data sources are active

---

## 🔒 API Key Security

**Best Practices:**
- Store keys in environment variables (already implemented)
- Never commit API keys to Git
- Use `.gitignore` for sensitive files
- Rotate keys periodically
- Monitor usage to detect abuse

**Current Implementation:**
```swift
// APIConfiguration.swift
static let attomAPIKey: String = {
    // Check environment variable first
    if let envKey = ProcessInfo.processInfo.environment["ATTOM_API_KEY"], !envKey.isEmpty {
        return envKey
    }
    return "" // Add your key here
}()
```

---

## 📝 API Documentation Links

- **Attom Data:** https://api.developer.attomdata.com/docs
- **FEMA Flood Maps:** https://hazards.fema.gov/gis/nfhl/rest/services
- **NASA FIRMS:** https://firms.modaps.eosdis.nasa.gov/api/
- **USGS Earthquake:** https://earthquake.usgs.gov/fdsnws/event/1/
- **Storm Prediction Center:** https://www.spc.noaa.gov/products/
- **OpenWeather:** https://openweathermap.org/api
- **Google Gemini:** https://ai.google.dev/tutorials/rest_quickstart

---

**Last Updated:** 2025-10-25
