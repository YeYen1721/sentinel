# Sentinel

SwiftUI prototype for predictive home maintenance, built during the Google x SCAD FLUX Hackathon 2025.

Sentinel turns weather and property-risk signals into a home dashboard with current risk, past events, and suggested maintenance actions.

[Case study](https://www.minwookshin.com/work/sentinel)

## Overview

- Home dashboard for environmental risk signals.
- Historical timeline for storms, floods, earthquakes, and other property-risk events.
- Action-plan flow for maintenance tasks.
- Insurance-score view for prevention and documentation context.
- Service layer for weather, risk, Gemini, FEMA, NASA FIRMS, and scoring logic.

## Role

Designed and built with Hyunsoo and Madelyn during a 48-hour team hackathon.

I worked on the dashboard, action-plan flow, SwiftUI screens, and product structure.

## Stack

- Swift and SwiftUI
- Figma
- Firebase configuration
- Weather-risk APIs
- Gemini API

## Start Here

- `Sentinel/Features/Home/Views/SentinelDashboard.swift` - main dashboard.
- `Sentinel/Features/ActionPlan/Views/TaskListView.swift` - action-plan flow.
- `Sentinel/Features/Historical/Views/HistoricalTimeline.swift` - risk history timeline.
- `Sentinel/Features/Insurance/Views/InsuranceScoreView.swift` - insurance-score view.
- `Sentinel/Core/Services/` - services and scoring logic.
- `Sentinel/Core/ViewModels/` - dashboard, profile, and task-list view models.
- `docs/setup/SETUP.md` - setup notes.
- `docs/setup/API_SETUP.md` - API setup notes.

## Run

Open `Sentinel.xcodeproj` in Xcode, review setup notes in `docs/setup/`, then run the app target on an iOS simulator.

API keys are loaded from environment/configuration paths. The included Firebase plist uses placeholder demo values.

## Notes

This is a hackathon prototype, not a production home-risk product. Research notes, improvement logs, debug docs, standalone API probes, and archived assets live in `Research/` and `docs/`.
