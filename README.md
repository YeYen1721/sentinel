# Sentinel

Hackathon-winning SwiftUI prototype for predictive home maintenance using weather-risk signals.

Case study: https://www.minwookshin.com/work/sentinel

## Recruiter Summary

Sentinel is a native iOS MVP built during the Google x SCAD FLUX Hackathon 2025. The product turns weather and property-risk signals into homeowner decisions: current risk, historical timeline, recommended actions, and insurance-readiness cues.

## Role

Designed and built by Minwook Shin during a 48-hour team hackathon with Hyunsoo and Madelyn.

My core ownership:

- Designed the homeowner risk dashboard and action-plan flow.
- Built SwiftUI interface screens for the native iOS prototype.
- Structured the product around current risk, historical events, recommended maintenance, and insurance-readiness.
- Connected the concept to configurable weather, alert, and property-risk signals.

## Outcome

- Winner, Google x SCAD FLUX Hackathon 2025
- 48-hour native iOS MVP
- Public source proof for SwiftUI app structure, service layer, view models, setup docs, and tests

## Stack

- Swift
- SwiftUI
- Figma
- Firebase configuration
- Weather-risk APIs
- Gemini API

## Where To Look First

- `Sentinel/Features/Home/Views/SentinelDashboard.swift` - main dashboard experience
- `Sentinel/Features/ActionPlan/Views/TaskListView.swift` - recommended action flow
- `Sentinel/Features/Historical/Views/HistoricalTimeline.swift` - risk history timeline
- `Sentinel/Core/Services/` - weather, risk, Gemini, FEMA, NASA FIRMS, and scoring services
- `Sentinel/Core/ViewModels/` - dashboard, profile, and task list view models
- `docs/setup/SETUP.md` - setup notes
- `docs/setup/API_SETUP.md` - API setup notes

## Notes

Built as a hackathon MVP and product prototype. API keys are loaded from environment variables, and the included Firebase plist uses placeholder demo values.

Research notes, improvement logs, debug docs, standalone API probes, and archived assets live in `Research/` and `docs/`. They are retained as build-process evidence, but the files above are the best starting point for code review.
