# **Sentinel iOS App Project Report: Final Development Specification**

## **1\. Executive Summary and Application Mandate**

Project Name: Sentinel (Proactive Hazard Management)  
Goal: To provide highly personalized, address-specific Home Vulnerability Scores (HVS) and generate actionable mitigation tasks using a combination of external data (simulated property/peril APIs) and Generative AI (Gemini API).  
Core Constraint: All user data and tasks must be stored persistently and securely using Firebase/Firestore.

## **2\. Core Architecture and Technology Stack**

The application must be built using the latest modern iOS development standards.

| Directive | Specification |
| :---- | :---- |
| **Technology Stack** | **SwiftUI** (iOS 17.0+), **Swift Concurrency** (async/await). |
| **State Management** | **@Observable** macro must be used for all ViewModels to ensure reactive UI updates. |
| **Architecture Pattern** | **Domain-Driven Design (DDD) / MVVM** with strong separation between Views, ViewModels, Services, and Repositories. |

### **2.1 Mandatory File Structure**

The project MUST adhere to this modular structure for organization and maintainability:  
Sentinel/  
├── Core/  
│   ├── Models/  
│   │   ├── PropertyProfile.swift // Structural data (roof, foundation)  
│   │   ├── HazardAssessment.swift // API model for peril data  
│   │   └── MitigationTask.swift // User and AI-generated tasks  
│   ├── Services/  
│   │   ├── RiskDataServiceProtocol.swift // Protocol for Tier 1 data  
│   │   ├── MockRiskDataService.swift // Required for development/previews  
│   │   └── ActionPlanService.swift // Handles Gemini API calls (Tier 2\)  
│   ├── Repositories/  
│   │   └── TaskRepository.swift // Handles all Firestore interaction  
│   └── Utilities/  
│       └── ScoringEngine.swift // Pure Swift logic for HVS calculation  
├── Features/  
│   └── Home/  
│       └── Views/  
│           ├── SentinelDashboard.swift   
│           └── VulnerabilityGauge.swift // Reusable HVS component  
│   └── ActionPlan/  
│       └── Views/  
│           └── TaskListView.swift  
├── ContentView.swift // Handles TabView and Auth check  
└── SentinelApp.swift

## **3\. API Integration and Data Handling Guide**

### **3.1 Tier 1: Data Input and Persistence (Mandatory Constraints)**

| API / Service | Purpose | Constraint Details |
| :---- | :---- | :---- |
| **Integrated Risk API Proxy** | Simulates collection of Geocoding, Property Specs, Historical Peril Data, and Real-Time Forecasts. | Must be abstracted via a RiskDataService Protocol. |
| **Firebase Authentication** | User sign-in. | MUST use \_\_initial\_auth\_token for signInWithCustomToken(). Fallback to signInAnonymously() is mandatory. |
| **Firestore** | Task and Profile Persistence. | **Mandatory Storage Path:** /artifacts/{\_\_app\_id}/users/{userId}/tasks |
| **Scoring Engine** | Home Vulnerability Score (HVS) Calculation. | Must combine three weighted factors: **Property Resilience**, **Historical Exposure**, and **Forecasted Severity**. |

### **3.2 Tier 2: Generative Intelligence (Gemini API)**

* **Role:** The ActionPlanService must call the Gemini API to translate the quantitative HVS and raw structural data into a high-quality, actionable, and prioritized natural language **Action Plan** and **Alert Text**.  
* **Output Processing:** The raw text response from the LLM must be parsed and structured into an array of MitigationTask objects before being saved by the TaskRepository.

## **4\. Navigation and Screen Flow Specification**

The app uses a **4-Tab TabView** for primary navigation and a NavigationStack for all detail drilling, ensuring a clear information hierarchy.

### **Primary Tabs (Root Views)**

| Tab Index | View Name | Purpose |
| :---- | :---- | :---- |
| 1\. | SentinelDashboard | HVS summary, current alert, quick stats. |
| 2\. | TaskListView | Management of all user and AI-generated mitigation tasks. |
| 3\. | HistoricalTimeline | Timeline of past severe weather events at the location. |
| 4\. | ProfileView | User account and property data editing. |

### **Detail Views (Drill-Down Flow)**

| Source View | Interaction | Destination View | Purpose |
| :---- | :---- | :---- | :---- |
| SentinelDashboard | Tap Alert Banner | ActionPlanDetailView | View the full, prioritized, step-by-step Gemini-generated action plan. |
| TaskListView | Tap Task Item | TaskEditView | Edit task status, due date, and associated notes. |
| HistoricalTimeline | Tap Historical Event | PerilEventDetailView | Show severity details of the historical event and resulting mitigation tasks. |
| ProfileView | Tap "Edit Address" | PropertyEditForms | Forms for updating structural data (e.g., roof material, year built). |

## **5\. UI/UX and Motion Mandates**

### **5.1 Design System: Google Material Design (M3)**

All components must follow **Google Material Design 3 (M3) principles**, adapted to native SwiftUI elements. This includes rounded corners on all cards, clear hierarchy, and dynamic color use (especially for the HVS indicator).

### **5.2 Native iOS Motion Principles (Mandatory)**

The application must feel fluid and native by employing specific Apple-recommended animations.

| Component | Required Motion Technique | Purpose |
| :---- | :---- | :---- |
| **HVS Gauge Update** | **Spring Animation** | Use a bouncy spring (e.g., spring(response: 0.8, dampingFraction: 0.6)) to animate the HVS needle/fill when the score changes. |
| **Navigation Transitions** | **Matched Geometry Effect** | Must be used to smoothly transition elements (like the HVS card) from a source view to a destination detail view. |
| **Alert Banner** | **Top Edge Transition** | Alerts should enter and exit smoothly from the top of the screen using a slide or move transition combined with opacity fade. |
| **Tappable Feedback** | **Scale Effect** | Buttons and list rows must provide subtle scaling (scaleEffect(0.95)) on tap to confirm interaction. |

